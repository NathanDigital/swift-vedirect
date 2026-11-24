/// One complete unit recognised in the byte stream.
public enum FrameEvent: Sendable, Equatable {
  /// A text block whose checksum was valid.
  case textBlock(TextBlock)
  /// A HEX frame whose checksum was valid.
  case hexFrame(HexFrame)
  /// A text block or HEX frame that was dropped, and why.
  case discarded(VEDirectError)
}

/// The state machine that splits a VE.Direct byte stream into text blocks and HEX frames.
///
/// The caller opens the serial port (19200 baud, 8 data bits, no parity, 1 stop bit, no flow
/// control) and feeds every received byte to ``consume(_:)``. Text blocks, HEX responses and
/// asynchronous HEX frames arrive interleaved on the one stream and all come out of this parser.
///
/// A HEX frame may interrupt a text block. Its bytes are kept out of the text checksum and the
/// block resumes where it stopped, so both are delivered.
///
/// Sources: "VE.Direct Protocol" rev 3.34, sections "Message format", "Data integrity" and
/// "Implementation guidelines"; the frame handler in the VE.Direct protocol FAQ; and section
/// "Frame format" of the HEX protocol documents.
public struct FrameParser: Sendable {
  /// The longest text label kept, in bytes ("Implementation guidelines": a buffer of 9 bytes).
  public static let maximumLabelLength = 9
  /// The longest text value kept, in bytes ("Implementation guidelines": a buffer of 33 bytes).
  public static let maximumValueLength = 33
  /// The most fields in one text block, not counting `Checksum` ("Implementation guidelines").
  public static let maximumFieldCount = 22
  /// The most bytes in one HEX frame after the command nibble, check byte included.
  ///
  /// Victron's documents state no maximum; the longest frame they define carries 55 bytes.
  public static let maximumHexLength = 64

  private enum TextState: Sendable {
    case idle
    case label
    case value
    case checksum
  }

  private static let checksumLabel: [UInt8] = Array("Checksum".utf8)

  private var textState = TextState.idle
  private var textSum: UInt8 = 0
  private var textFault: VEDirectError?
  private var label: [UInt8] = []
  private var value: [UInt8] = []
  private var fields: [TextField] = []

  private var isInHexFrame = false
  private var hexFault: VEDirectError?
  private var hexCommand: UInt8?
  private var hexHighNibble: UInt8?
  private var hexBytes: [UInt8] = []

  /// Creates a parser that is waiting for the start of a text block or HEX frame.
  public init() {
    label.reserveCapacity(Self.maximumLabelLength)
    value.reserveCapacity(Self.maximumValueLength)
    fields.reserveCapacity(Self.maximumFieldCount)
    hexBytes.reserveCapacity(Self.maximumHexLength)
  }

  /// Feeds one received byte to the parser.
  ///
  /// - Returns: The block or frame this byte completed, or `nil` when more bytes are needed.
  ///   A dropped block or frame is reported once, when its end is reached.
  public mutating func consume(_ byte: UInt8) -> FrameEvent? {
    if isInHexFrame {
      return consumeHex(byte)
    }
    // A colon starts a HEX frame anywhere except where it is the text checksum byte.
    if byte == ASCII.colon && textState != .checksum {
      beginHexFrame()
      return nil
    }
    return consumeText(byte)
  }

  // MARK: Text

  private mutating func consumeText(_ byte: UInt8) -> FrameEvent? {
    switch textState {
    case .idle:
      if byte == ASCII.carriageReturn {
        textSum = byte
      } else if byte == ASCII.lineFeed {
        textSum &+= byte
        textState = .label
      }
      return nil

    case .label:
      textSum &+= byte
      if byte == ASCII.tab {
        if ASCII.equalIgnoringCase(label, Self.checksumLabel) {
          textState = .checksum
        } else {
          textState = .value
        }
      } else if byte == ASCII.carriageReturn || byte == ASCII.lineFeed {
        if !label.isEmpty {
          recordTextFault(.malformedField)
          label.removeAll(keepingCapacity: true)
        }
      } else if label.count < Self.maximumLabelLength {
        label.append(byte)
      } else {
        recordTextFault(.labelTooLong)
      }
      return nil

    case .value:
      textSum &+= byte
      if byte == ASCII.lineFeed {
        if fields.count < Self.maximumFieldCount {
          fields.append(TextField(labelBytes: label, valueBytes: value))
        } else {
          recordTextFault(.tooManyFields)
        }
        label.removeAll(keepingCapacity: true)
        value.removeAll(keepingCapacity: true)
        textState = .label
      } else if byte == ASCII.carriageReturn {
        // The carriage return belongs to the next field's separator.
      } else if value.count < Self.maximumValueLength {
        value.append(byte)
      } else {
        recordTextFault(.valueTooLong)
      }
      return nil

    case .checksum:
      textSum &+= byte
      let event: FrameEvent
      if let textFault {
        event = .discarded(textFault)
      } else if textSum != 0 {
        event = .discarded(.textChecksumMismatch)
      } else {
        event = .textBlock(TextBlock(fields: fields))
      }
      resetText()
      return event
    }
  }

  private mutating func recordTextFault(_ fault: VEDirectError) {
    if textFault == nil {
      textFault = fault
    }
  }

  private mutating func resetText() {
    textState = .idle
    textSum = 0
    textFault = nil
    label.removeAll(keepingCapacity: true)
    value.removeAll(keepingCapacity: true)
    fields.removeAll(keepingCapacity: true)
  }

  // MARK: HEX

  private mutating func beginHexFrame() {
    isInHexFrame = true
    hexFault = nil
    hexCommand = nil
    hexHighNibble = nil
    hexBytes.removeAll(keepingCapacity: true)
  }

  private mutating func consumeHex(_ byte: UInt8) -> FrameEvent? {
    if byte == ASCII.lineFeed {
      let event = finishHexFrame()
      isInHexFrame = false
      return event
    }
    if byte == ASCII.colon {
      // A second colon abandons the frame in progress and starts another.
      let event = FrameEvent.discarded(hexFault ?? .hexIncomplete)
      beginHexFrame()
      return event
    }
    guard hexFault == nil else { return nil }
    guard let digit = ASCII.hexValue(byte, allowLowercase: false) else {
      hexFault = .hexInvalidDigit
      return nil
    }
    guard hexCommand != nil else {
      hexCommand = digit
      return nil
    }
    guard let high = hexHighNibble else {
      hexHighNibble = digit
      return nil
    }
    hexHighNibble = nil
    if hexBytes.count < Self.maximumHexLength {
      hexBytes.append(high << 4 | digit)
    } else {
      hexFault = .hexTooLong
    }
    return nil
  }

  private func finishHexFrame() -> FrameEvent {
    if let hexFault {
      return .discarded(hexFault)
    }
    guard let command = hexCommand, hexHighNibble == nil, !hexBytes.isEmpty else {
      return .discarded(.hexIncomplete)
    }
    var sum = command
    for byte in hexBytes {
      sum &+= byte
    }
    guard sum == HexFrame.checksumTarget else {
      return .discarded(.hexChecksumMismatch)
    }
    return .hexFrame(HexFrame(command: command, payload: Array(hexBytes.dropLast())))
  }
}
