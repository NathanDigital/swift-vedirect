import Testing
import VEDirect

@Suite("VE.Direct Protocol 3.34 and FAQ: text framing")
struct FrameParserTextTests {
  @Test("FAQ question 8: the example block has checksum byte 0xD8 and is delivered")
  func faqExampleBlock() throws {
    let bytes = textBlockBytes(faqBlockFields)
    #expect(bytes.last == 0xD8)
    #expect(events(bytes) == [.textBlock(textBlock(faqBlockFields))])
  }

  @Test("Blocks that follow each other are all delivered")
  func consecutiveBlocks() {
    let bytes = textBlockBytes(faqBlockFields)
    let result = events(bytes + bytes + bytes)
    #expect(result == Array(repeating: .textBlock(textBlock(faqBlockFields)), count: 3))
  }

  @Test("A checksum byte of 0x3A is not taken as the start of a HEX frame")
  func colonChecksumByte() throws {
    // Search for a voltage whose block has ':' as its checksum byte.
    let fields = try #require(
      (0..<2000).lazy
        .map { [(label: "V", value: "\($0)"), (label: "I", value: "0")] }
        .first { textBlockBytes($0).last == 0x3A })
    let bytes = textBlockBytes(fields)
    let next = textBlockBytes(faqBlockFields)
    #expect(
      events(bytes + next) == [
        .textBlock(textBlock(fields)), .textBlock(textBlock(faqBlockFields)),
      ]
    )
  }

  @Test("A HEX frame at any position inside a text block leaves both intact")
  func hexFrameInsideTextBlock() throws {
    let block = textBlockBytes(faqBlockFields)
    let frame = hexLine(":A0102000543")
    let expectedFrame = try hexFrame(":A0102000543")
    // The last position is before the checksum byte, where a colon is the checksum itself.
    for position in 0..<(block.count - 1) {
      let bytes = Array(block[..<position]) + frame + Array(block[position...])
      #expect(
        events(bytes) == [.hexFrame(expectedFrame), .textBlock(textBlock(faqBlockFields))],
        "frame inserted at offset \(position)")
    }
  }

  @Test("A block split at every byte boundary is delivered once")
  func blockSplitAtEveryBoundary() {
    let block = textBlockBytes(faqBlockFields)
    for boundary in 0...block.count {
      var parser = FrameParser()
      var result = events(Array(block[..<boundary]), parser: &parser)
      if boundary < block.count {
        #expect(result.isEmpty, "event before the block was complete, split at \(boundary)")
      }
      result += events(Array(block[boundary...]), parser: &parser)
      #expect(result == [.textBlock(textBlock(faqBlockFields))])
    }
  }

  @Test("A block with a corrupted checksum is discarded whole and the next one is delivered")
  func corruptedChecksum() {
    var bad = textBlockBytes(faqBlockFields)
    bad[bad.count - 1] ^= 0x01
    let good = textBlockBytes(faqBlockFields)
    #expect(
      events(bad + good) == [
        .discarded(.textChecksumMismatch), .textBlock(textBlock(faqBlockFields)),
      ])
  }

  @Test("No single flipped bit lets a damaged block through")
  func singleBitCorruption() {
    let block = textBlockBytes(faqBlockFields)
    let original = FrameEvent.textBlock(textBlock(faqBlockFields))
    for index in block.indices {
      for bit in 0..<8 {
        var damaged = block
        damaged[index] ^= UInt8(1) << UInt8(bit)
        var parser = FrameParser()
        let result = events(damaged, parser: &parser)
        for event in result {
          if case .textBlock = event {
            Issue.record("damaged block delivered, byte \(index) bit \(bit)")
          }
        }
        // Whatever state the damage left, the parser is back in step within two good blocks.
        let recovery = events(block + block, parser: &parser)
        #expect(recovery.last == original, "no recovery, byte \(index) bit \(bit)")
      }
    }
  }

  @Test("A label of 9 bytes is kept and one of 10 discards the block")
  func labelLimit() {
    let fits = [(label: "ABCDEFGHI", value: "1")]
    #expect(events(textBlockBytes(fits)) == [.textBlock(textBlock(fits))])
    let tooLong = [(label: "ABCDEFGHIJ", value: "1")]
    #expect(events(textBlockBytes(tooLong)) == [.discarded(.labelTooLong)])
  }

  @Test("A value of 33 bytes is kept and one of 34 discards the block")
  func valueLimit() {
    let fits = [(label: "V", value: String(repeating: "7", count: 33))]
    #expect(events(textBlockBytes(fits)) == [.textBlock(textBlock(fits))])
    let tooLong = [(label: "V", value: String(repeating: "7", count: 34))]
    #expect(events(textBlockBytes(tooLong)) == [.discarded(.valueTooLong)])
  }

  @Test("A block of 22 fields is kept and one of 23 is discarded")
  func fieldLimit() {
    let fits = (0..<22).map { (label: "L\($0)", value: "\($0)") }
    #expect(events(textBlockBytes(fits)) == [.textBlock(textBlock(fits))])
    let tooMany = (0..<23).map { (label: "L\($0)", value: "\($0)") }
    #expect(events(textBlockBytes(tooMany)) == [.discarded(.tooManyFields)])
  }

  @Test("A line without a tab discards the block")
  func lineWithoutTab() {
    let bytes = ascii("\r\nV\t1\r\nBROKEN\r\nI\t2\r\nChecksum\t") + [0x00]
    #expect(events(bytes) == [.discarded(.malformedField)])
  }

  @Test("An input that never ends a block is held in bounded buffers and produces nothing")
  func endlessInput() {
    var parser = FrameParser()
    var count = 0
    for _ in 0..<5000 {
      count += events(ascii("\r\nLABELLABELLABEL\tVALUE"), parser: &parser).count
    }
    #expect(count == 0)
    let block = textBlockBytes(faqBlockFields)
    #expect(events(block + block, parser: &parser).last == .textBlock(textBlock(faqBlockFields)))
  }

  @Test("A stream joined part-way through a block recovers on the next block")
  func joinedMidBlock() {
    let block = textBlockBytes(faqBlockFields)
    for start in 1..<block.count {
      let result = events(Array(block[start...]) + block)
      #expect(result.last == .textBlock(textBlock(faqBlockFields)), "joined at offset \(start)")
      #expect(result.count <= 2)
    }
  }

  @Test("The label of the checksum field is matched without regard to case")
  func checksumLabelCase() {
    var bytes = ascii("\r\nV\t1\r\nCHECKSUM\t")
    var sum: UInt8 = 0
    for byte in bytes {
      sum &+= byte
    }
    bytes.append(0 &- sum)
    #expect(events(bytes) == [.textBlock(textBlock([(label: "V", value: "1")]))])
  }
}
