import Testing
import VEDirect

/// The ASCII bytes of a string.
func ascii(_ text: String) -> [UInt8] {
  Array(text.utf8)
}

/// Feeds bytes to a parser and returns every event they produced.
func events(_ bytes: [UInt8], parser: inout FrameParser) -> [FrameEvent] {
  var result: [FrameEvent] = []
  for byte in bytes {
    if let event = parser.consume(byte) {
      result.append(event)
    }
  }
  return result
}

/// Feeds bytes to a new parser and returns every event they produced.
func events(_ bytes: [UInt8]) -> [FrameEvent] {
  var parser = FrameParser()
  return events(bytes, parser: &parser)
}

/// The bytes of a text block with a correct checksum, from the first carriage return to the
/// checksum byte.
func textBlockBytes(_ fields: [(label: String, value: String)]) -> [UInt8] {
  var bytes: [UInt8] = []
  for field in fields {
    bytes += ascii("\r\n\(field.label)\t\(field.value)")
  }
  bytes += ascii("\r\nChecksum\t")
  var sum: UInt8 = 0
  for byte in bytes {
    sum &+= byte
  }
  bytes.append(0 &- sum)
  return bytes
}

/// A block built from label and value pairs, as the parser would deliver it.
func textBlock(_ fields: [(label: String, value: String)]) -> TextBlock {
  TextBlock(
    fields: fields.map { TextField(labelBytes: ascii($0.label), valueBytes: ascii($0.value)) })
}

/// A HEX frame with a line feed added, as it appears on the wire.
func hexLine(_ text: String) -> [UInt8] {
  ascii(text) + [0x0A]
}

/// The only frame in a line of HEX, or a recorded failure when the line does not parse to one.
func hexFrame(_ text: String) throws -> HexFrame {
  let result = events(hexLine(text))
  guard result.count == 1, case .hexFrame(let frame) = result[0] else {
    Issue.record("\(text) did not parse to one frame: \(result)")
    throw VEDirectError.hexIncomplete
  }
  return frame
}

/// A small deterministic generator, so that random-input tests repeat exactly.
struct SeededGenerator: RandomNumberGenerator {
  private var state: UInt64

  init(seed: UInt64) {
    state = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed
  }

  mutating func next() -> UInt64 {
    state ^= state << 13
    state ^= state >> 7
    state ^= state << 17
    return state
  }
}

/// The example block from the VE.Direct protocol FAQ, question 8, sent by a BMV-700.
let faqBlockFields: [(label: String, value: String)] = [
  ("PID", "0x203"), ("V", "26201"), ("I", "0"), ("P", "0"), ("CE", "0"), ("SOC", "1000"),
  ("TTG", "-1"), ("Alarm", "OFF"), ("Relay", "OFF"), ("AR", "0"), ("BMV", "700"), ("FW", "0307"),
]
