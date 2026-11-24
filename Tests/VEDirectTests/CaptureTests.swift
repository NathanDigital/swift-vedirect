import Testing
import VEDirect

/// What a capture is expected to contain.
struct Capture: Sendable, CustomTestStringConvertible {
  let name: String
  let bytes: [UInt8]
  let blocks: Int
  let hexFrames: Int
  let discarded: [VEDirectError]
  let productID: ProductID
  let firmware: FirmwareVersion

  var testDescription: String { name }

  /// The captures in `Fixtures`, recorded from real devices; see `docs/testing.md`.
  static let all = [
    // Starts with one stray byte and ends on a checksum byte.
    Capture(
      name: "bluesolar_1.23.dump", bytes: PackageResources.bluesolar_1_23_dump, blocks: 248,
      hexFrames: 7, discarded: [], productID: 0xA042,
      firmware: FirmwareVersion(major: 1, minor: 23)),
    // Ends part-way through a block, which produces no event.
    Capture(
      name: "bvm702.dump", bytes: PackageResources.bvm702_dump, blocks: 906, hexFrames: 0,
      discarded: [], productID: 0x203, firmware: FirmwareVersion(major: 3, minor: 8)),
    // Starts part-way through a block, which is discarded.
    Capture(
      name: "smartsolar_1.39.dump", bytes: PackageResources.smartsolar_1_39_dump, blocks: 493,
      hexFrames: 2, discarded: [.textChecksumMismatch], productID: 0xA05F,
      firmware: FirmwareVersion(major: 1, minor: 39)),
  ]
}

@Suite("Captures from real devices")
struct CaptureTests {
  @Test("Every block and frame of a capture is delivered", arguments: Capture.all)
  func contents(capture: Capture) throws {
    var blocks: [TextBlock] = []
    var frames: [HexFrame] = []
    var discarded: [VEDirectError] = []
    for event in events(capture.bytes) {
      switch event {
      case .textBlock(let block): blocks.append(block)
      case .hexFrame(let frame): frames.append(frame)
      case .discarded(let reason): discarded.append(reason)
      }
    }
    #expect(blocks.count == capture.blocks)
    #expect(frames.count == capture.hexFrames)
    #expect(discarded == capture.discarded)

    // Every HEX frame in the captures is an asynchronous history record.
    for frame in frames {
      guard case .asynchronous(let reply) = try HexResponse(frame) else {
        Issue.record("frame is not asynchronous: \(frame)")
        continue
      }
      #expect(reply.id == 0x1050 || reply.id == 0x104F)
      #expect(reply.flags == [])
    }
  }

  @Test("Every block of a capture reads as typed values", arguments: Capture.all)
  func typedValues(capture: Capture) throws {
    var identified = 0
    for event in events(capture.bytes) {
      guard case .textBlock(let block) = event else { continue }
      if let productID = try block.productID {
        #expect(productID == capture.productID)
        #expect(try block.firmwareVersion == capture.firmware)
        let voltage = try #require(try block.mainVoltage)
        #expect((5...60).contains(voltage))
        _ = try #require(try block.current)
        identified += 1
      }
      // No field of a real capture is malformed.
      _ = try block.panelVoltage
      _ = try block.panelPower
      _ = try block.operationState
      _ = try block.chargerError
      _ = try block.isLoadOutputOn
      _ = try block.loadCurrent
      _ = try block.totalYield
      _ = try block.yieldToday
      _ = try block.maximumPowerToday
      _ = try block.yieldYesterday
      _ = try block.maximumPowerYesterday
      _ = try block.daySequenceNumber
      _ = try block.trackerMode
      _ = try block.power
      _ = try block.consumedCharge
      _ = try block.stateOfCharge
      _ = try block.timeToGo
      _ = try block.isAlarmActive
      _ = try block.isRelayOn
      _ = try block.alarmReason
      _ = try block.deepestDischarge
      _ = try block.lastDischarge
      _ = try block.averageDischarge
      _ = try block.chargeCycleCount
      _ = try block.fullDischargeCount
      _ = try block.cumulativeChargeDrawn
      _ = try block.minimumMainVoltage
      _ = try block.maximumMainVoltage
      _ = try block.timeSinceFullCharge
      _ = try block.automaticSynchronisationCount
      _ = try block.lowMainVoltageAlarmCount
      _ = try block.highMainVoltageAlarmCount
      _ = try block.dischargedEnergy
      _ = try block.chargedEnergy
    }
    #expect(identified > 0)
  }

  @Test("The BMV capture alternates between a live block and a history block")
  func alternatingBlocks() throws {
    let capture = try #require(Capture.all.first { $0.name == "bvm702.dump" })
    var live = 0
    var history = 0
    for event in events(capture.bytes) {
      guard case .textBlock(let block) = event else { continue }
      let hasLive = block["V"] != nil
      let hasHistory = block["H1"] != nil
      #expect(hasLive != hasHistory)
      if hasLive { live += 1 } else { history += 1 }
    }
    #expect(live == 453)
    #expect(history == 453)
  }

  @Test("The BMV capture has blocks whose checksum byte is a colon")
  func colonChecksumBytes() throws {
    let capture = try #require(Capture.all.first { $0.name == "bvm702.dump" })
    let marker = ascii("Checksum\t:")
    var count = 0
    var index = 0
    while index + marker.count <= capture.bytes.count {
      if capture.bytes[index..<(index + marker.count)].elementsEqual(marker) {
        count += 1
      }
      index += 1
    }
    #expect(count == 7)
  }
}
