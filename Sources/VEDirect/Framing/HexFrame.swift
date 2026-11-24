/// A HEX frame with a valid checksum: a command or response nibble and its data bytes.
///
/// A frame on the wire is `:`, one hexadecimal digit for the command, two uppercase hexadecimal
/// digits for each byte, a check byte and a line feed. The command, the data bytes and the check
/// byte sum to `0x55` modulo 256.
///
/// Source: section "Frame format" of the MPPT, BMV, Orion XS and Phoenix Inverter HEX protocol
/// documents.
public struct HexFrame: Sendable, Equatable {
  static let checksumTarget: UInt8 = 0x55

  /// The command or response number, `0` to `15`.
  public let command: UInt8
  /// The data bytes, without the check byte.
  public let payload: [UInt8]

  /// Only the parser and ``HexCommand`` create frames, so no caller can build command `0`.
  init(command: UInt8, payload: [UInt8]) {
    self.command = command & 0x0F
    self.payload = payload
  }

  /// The frame as bytes to send, from the colon to the line feed.
  func encoded() -> [UInt8] {
    var bytes: [UInt8] = [ASCII.colon, ASCII.hexDigit(command)]
    bytes.reserveCapacity(payload.count * 2 + 5)
    var check = Self.checksumTarget &- command
    for byte in payload {
      check &-= byte
      bytes.append(ASCII.hexDigit(byte >> 4))
      bytes.append(ASCII.hexDigit(byte))
    }
    bytes.append(ASCII.hexDigit(check >> 4))
    bytes.append(ASCII.hexDigit(check))
    bytes.append(ASCII.lineFeed)
    return bytes
  }
}
