import Testing

@testable import VEDirect

@Suite("HEX protocol documents: framing")
struct FrameParserHexTests {
  /// Every example frame with a valid checksum from the four HEX documents and the FAQ.
  static let validFrames = [
    // "VE.Direct Protocol - BlueSolar and SmartSolar MPPT chargers" Rev 18, section 1.3;
    // "VE.Direct Protocol - Phoenix Inverters" Rev 5 prints the same examples.
    ":154", ":51641F9", ":352", ":11641FD", ":451", ":1000351", ":64F", ":7F0ED0071",
    ":7F0ED009600DB", ":8F0ED0064000C", ":253", ":3020050", ":4AAAAFD", ":A0102000543",
    // "VE.Direct Protocol - Orion XS DC-DC battery charger", section 1.3.
    ":5FF7FD2", ":1F0A3C1", ":70201004B", ":702010000FF120139", ":7F0ED00F4017C",
    ":8F0ED00F4017B", ":2000152", ":2AAAAFF",
    // "BMV700 Series Hex Protocol" Rev 7, examples.
    ":501440B", ":101440F", ":181A330", ":70010003E", ":7001000C80076", ":8001000F40148",
    ":800100000003D", ":8001004010038", ":7001000F40149",
    // VE.Direct protocol FAQ, question 3.
    ":7FF0F0040",
  ]

  @Test(
    "Every valid example frame parses and encodes back to the same bytes", arguments: validFrames)
  func exampleFrameRoundTrip(text: String) throws {
    let frame = try hexFrame(text)
    #expect(frame.encoded() == hexLine(text))
  }

  @Test("MPPT section 1.3: the frame with a deliberately wrong checksum is discarded")
  func wrongChecksumExample() {
    #expect(events(hexLine(":452")) == [.discarded(.hexChecksumMismatch)])
  }

  @Test("Orion XS section 1.3: the response printed as :30300F4 has a wrong checksum")
  func orionMisprintedExample() throws {
    #expect(events(hexLine(":30300F4")) == [.discarded(.hexChecksumMismatch)])
    // The check byte that makes the printed command and data valid is 4F.
    #expect(try hexFrame(":303004F") == HexFrame(command: 3, payload: [0x03, 0x00]))
  }

  @Test("A parsed frame holds the command nibble and the data without the check byte")
  func frameContents() throws {
    let frame = try hexFrame(":7F0ED009600DB")
    #expect(frame.command == 7)
    #expect(frame.payload == [0xF0, 0xED, 0x00, 0x96, 0x00])
  }

  @Test("Lowercase digits and other bytes discard the frame")
  func invalidDigits() {
    #expect(events(hexLine(":7f0ed0071")) == [.discarded(.hexInvalidDigit)])
    #expect(events(hexLine(":15G")) == [.discarded(.hexInvalidDigit)])
    #expect(events(ascii(":154\r\n")) == [.discarded(.hexInvalidDigit)])
  }

  @Test("A frame without a check byte or with half a byte is discarded")
  func incompleteFrames() {
    #expect(events(hexLine(":")) == [.discarded(.hexIncomplete)])
    #expect(events(hexLine(":1")) == [.discarded(.hexIncomplete)])
    #expect(events(hexLine(":1540")) == [.discarded(.hexIncomplete)])
  }

  @Test("A second colon abandons the frame in progress and starts another")
  func restartOnColon() throws {
    let expected = try hexFrame(":154")
    #expect(events(hexLine(":7F0ED:154")) == [.discarded(.hexIncomplete), .hexFrame(expected)])
  }

  @Test("A frame of the maximum length is kept and a longer one is discarded")
  func lengthLimit() throws {
    let longest = HexFrame(
      command: 7, payload: Array(repeating: 0x11, count: FrameParser.maximumHexLength - 1))
    #expect(events(longest.encoded()) == [.hexFrame(longest)])
    let tooLong = HexFrame(
      command: 7, payload: Array(repeating: 0x11, count: FrameParser.maximumHexLength))
    #expect(events(tooLong.encoded()) == [.discarded(.hexTooLong)])
    // The parser is back in step straight afterwards.
    var parser = FrameParser()
    _ = events(tooLong.encoded(), parser: &parser)
    #expect(events(hexLine(":154"), parser: &parser) == [.hexFrame(try hexFrame(":154"))])
  }

  @Test("A damaged HEX frame inside a text block does not lose the block")
  func damagedFrameInsideTextBlock() {
    let block = textBlockBytes(faqBlockFields)
    let bytes = Array(block[..<20]) + hexLine(":A0102000544") + Array(block[20...])
    #expect(
      events(bytes) == [
        .discarded(.hexChecksumMismatch), .textBlock(textBlock(faqBlockFields)),
      ])
  }
}

@Suite("Arbitrary input")
struct ArbitraryInputTests {
  private func checkRecovery(_ parser: inout FrameParser, _ comment: Comment) throws {
    let block = textBlockBytes(faqBlockFields)
    let frame = hexLine(":A0102000543")
    #expect(
      events(block + block, parser: &parser).last == .textBlock(textBlock(faqBlockFields)),
      comment)
    #expect(events(frame + frame, parser: &parser).last == .hexFrame(try hexFrame(":A0102000543")))
  }

  private func checkLimits(_ event: FrameEvent) {
    switch event {
    case .textBlock(let block):
      #expect(block.fields.count <= FrameParser.maximumFieldCount)
      for field in block.fields {
        #expect(field.labelBytes.count <= FrameParser.maximumLabelLength)
        #expect(field.valueBytes.count <= FrameParser.maximumValueLength)
      }
    case .hexFrame(let frame):
      #expect(frame.payload.count < FrameParser.maximumHexLength)
      // Interpreting any frame as a response either succeeds or throws; it never traps.
      _ = try? HexResponse(frame)
    case .discarded:
      break
    }
  }

  @Test("Random bytes never trap, stay within the limits and leave the parser able to recover")
  func randomBytes() throws {
    var generator = SeededGenerator(seed: 1)
    var parser = FrameParser()
    for _ in 0..<300_000 {
      if let event = parser.consume(UInt8.random(in: .min ... .max, using: &generator)) {
        checkLimits(event)
      }
    }
    try checkRecovery(&parser, "after random bytes")
  }

  @Test("Random bytes from the protocol's own alphabet never trap and allow recovery")
  func randomProtocolBytes() throws {
    let alphabet = ascii("\r\n\t::0123456789ABCDEFabcChecksumVIH-xON")
    var generator = SeededGenerator(seed: 2)
    var parser = FrameParser()
    for _ in 0..<300_000 {
      let byte = try #require(alphabet.randomElement(using: &generator))
      if let event = parser.consume(byte) {
        checkLimits(event)
      }
    }
    try checkRecovery(&parser, "after random protocol bytes")
  }

  @Test("Every truncation of a block and a frame leaves the parser able to recover")
  func truncatedSequences() throws {
    let sequence = textBlockBytes(faqBlockFields) + hexLine(":7F0ED009600DB")
    for length in 0...sequence.count {
      var parser = FrameParser()
      _ = events(Array(sequence[..<length]), parser: &parser)
      try checkRecovery(&parser, "after a sequence cut at \(length)")
    }
  }

  @Test("Random text values never trap the typed readings")
  func randomTextValues() throws {
    let alphabet = ascii("0123456789-+xXABCDEFONFfon. ")
    let labels = [
      "V", "I", "TTG", "SOC", "Alarm", "Relay", "AR", "OR", "PID", "FW", "FWE", "CS", "ERR",
      "MON", "H4", "LOAD", "MODE", "MPPT", "WARN", "CAP_BLE", "HSDS",
    ]
    var generator = SeededGenerator(seed: 3)
    for _ in 0..<20_000 {
      let length = Int.random(in: 0...12, using: &generator)
      var value: [UInt8] = []
      for _ in 0..<length {
        value.append(try #require(alphabet.randomElement(using: &generator)))
      }
      let block = TextBlock(
        fields: labels.map { TextField(labelBytes: ascii($0), valueBytes: value) })
      _ = try? block.mainVoltage
      _ = try? block.current
      _ = try? block.timeToGo
      _ = try? block.stateOfCharge
      _ = try? block.isAlarmActive
      _ = try? block.isRelayOn
      _ = try? block.alarmReason
      _ = try? block.offReason
      _ = try? block.productID
      _ = try? block.firmwareVersion
      _ = try? block.extendedFirmwareVersion
      _ = try? block.operationState
      _ = try? block.chargerError
      _ = try? block.monitorMode
      _ = try? block.chargeCycleCount
      _ = try? block.isLoadOutputOn
      _ = try? block.deviceMode
      _ = try? block.trackerMode
      _ = try? block.warningReason
      _ = try? block.bluetoothCapabilities
      _ = try? block.daySequenceNumber
    }
  }
}
