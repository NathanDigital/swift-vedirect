/// The flags byte of a get, set or asynchronous response.
///
/// Source: section "Frame format", table of flags, in the HEX protocol documents.
public struct ResponseFlags: OptionSet, Hashable, Sendable {
  /// The bits on the wire.
  public let rawValue: UInt8

  /// Creates flags from their wire bits; unknown bits are kept.
  public init(rawValue: UInt8) { self.rawValue = rawValue }

  /// The specified id does not exist.
  public static let unknownID = ResponseFlags(rawValue: 0x01)
  /// Attempting to write to a read-only value.
  public static let notSupported = ResponseFlags(rawValue: 0x02)
  /// The new value is out of range or inconsistent.
  public static let parameterError = ResponseFlags(rawValue: 0x04)
}

/// The register id, flags and value bytes of a get, set or asynchronous response.
///
/// The id is how a response is matched to its request: compare ``id`` with the register that was
/// asked for, and treat a different id as a stale or unsolicited response.
public struct RegisterReply: Sendable, Equatable {
  /// The register the response is about.
  public let id: RegisterID
  /// The flags the device set.
  public let flags: ResponseFlags
  /// The value bytes, in wire order.
  public let value: [UInt8]

  /// Creates a reply from its parts.
  public init(id: RegisterID, flags: ResponseFlags, value: [UInt8]) {
    self.id = id
    self.flags = flags
    self.value = value
  }

  /// Decodes the value with a register definition.
  ///
  /// - Returns: The value, or `nil` when the device reports that it has none.
  /// - Throws: ``VEDirectError/unknownRegister(_:)``, ``VEDirectError/notSupported(_:)`` or
  ///   ``VEDirectError/parameterError(_:)`` when the device set a flag, and the errors of
  ///   ``Register/decode(_:)``. The raw ``value`` stays readable after a flag error.
  public func decoded(as register: Register) throws(VEDirectError) -> RegisterValue? {
    if flags.contains(.unknownID) { throw .unknownRegister(id) }
    if flags.contains(.notSupported) { throw .notSupported(id) }
    if flags.contains(.parameterError) { throw .parameterError(id) }
    return try register.decode(value)
  }
}

/// A HEX frame received from a device, interpreted by its response number.
///
/// Source: section "Frame format", table of responses, in the MPPT, BMV, Orion XS and Phoenix
/// Inverter HEX protocol documents.
public enum HexResponse: Sendable, Equatable {
  /// Response `1`: the command succeeded; the bytes depend on the command sent.
  case done([UInt8])
  /// Response `2`: the device received a frame with a bad checksum (Orion XS).
  case checksumError
  /// Response `3`: the device does not know the command, whose number is returned.
  case unknownCommand(UInt8)
  /// Response `4`: an error; `0xAAAA` is a framing error.
  case error(UInt16)
  /// Response `5`: the reply to a ping.
  case ping(PingReply)
  /// Response `7`: the reply to a get.
  case get(RegisterReply)
  /// Response `8`: the reply to a set, holding the value the device now uses.
  case set(RegisterReply)
  /// Response `A`: a register the device sent unasked; it must not be answered.
  case asynchronous(RegisterReply)
  /// Any other response number, with its bytes.
  case other(command: UInt8, payload: [UInt8])

  /// Interprets a frame from the parser as a response.
  ///
  /// - Throws: ``VEDirectError/truncatedPayload`` when the frame is shorter than its layout.
  public init(_ frame: HexFrame) throws(VEDirectError) {
    let payload = frame.payload
    switch frame.command {
    case 1:
      self = .done(payload)
    case 2:
      self = .checksumError
    case 3:
      guard let command = payload.first else { throw .truncatedPayload }
      self = .unknownCommand(command)
    case 4:
      self = .error(try LittleEndian.word(payload))
    case 5:
      self = .ping(PingReply(rawValue: try LittleEndian.word(payload)))
    case 7:
      self = .get(try Self.reply(payload))
    case 8:
      self = .set(try Self.reply(payload))
    case 0xA:
      self = .asynchronous(try Self.reply(payload))
    default:
      self = .other(command: frame.command, payload: payload)
    }
  }

  private static func reply(_ payload: [UInt8]) throws(VEDirectError) -> RegisterReply {
    guard payload.count >= 3 else { throw .truncatedPayload }
    return RegisterReply(
      id: RegisterID(rawValue: try LittleEndian.word(payload)),
      flags: ResponseFlags(rawValue: payload[2]),
      value: Array(payload.dropFirst(3))
    )
  }
}

/// Reads of little-endian integers from received bytes.
enum LittleEndian {
  /// The 16-bit integer in the first two bytes.
  static func word(_ bytes: [UInt8]) throws(VEDirectError) -> UInt16 {
    guard bytes.count >= 2 else { throw .truncatedPayload }
    return UInt16(truncatingIfNeeded: bytes[0]) | UInt16(truncatingIfNeeded: bytes[1]) << 8
  }
}
