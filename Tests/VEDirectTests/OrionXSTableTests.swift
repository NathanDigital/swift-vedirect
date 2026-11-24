import Testing
import VEDirect

@Suite("VE.Direct Protocol - Orion XS DC-DC battery charger, 16-06-2025")
struct OrionXSTableTests {
  private func register(_ id: UInt16) throws -> Register {
    try #require(OrionXS.registers.first { $0.id.rawValue == id })
  }

  private func number(_ register: Register, _ bytes: [UInt8]) throws -> Double {
    guard case .number(let value) = try #require(try register.decode(bytes)) else {
      Issue.record("\(register.name) did not decode to a number")
      return .nan
    }
    return value
  }

  @Test func idsAreUnique() {
    let ids = OrionXS.registers.map(\.id)
    #expect(Set(ids).count == ids.count)
  }

  @Test func namesAreUnique() {
    let names = OrionXS.registers.map(\.name)
    #expect(Set(names).count == names.count)
    #expect(!names.contains(""))
  }

  @Test func tableHoldsEveryRowOfTheDocument() {
    #expect(OrionXS.registers.count == 109)
    #expect(OrionXS.batteryMaximumCurrent.name == "batteryMaximumCurrent")
  }

  @Test func getBatteryMaximumCurrentExampleDecodesTo50Amperes() throws {
    // ":7F0ED00F4017C": register 0xEDF0, flags 0x00, value 0x01F4.
    let current = try register(0xEDF0)
    #expect(current == OrionXS.batteryMaximumCurrent)
    #expect(abs(try number(current, [0xF4, 0x01]) - 50.0) < 1e-9)
  }

  @Test func setBatteryMaximumCurrentExamplesEncodeAsInTheDocument() throws {
    // ":8F0ED0064000C" sets 10.0 A and ":8F0ED00F4017B" sets 50.0 A again.
    let current = OrionXS.batteryMaximumCurrent
    #expect(abs(try number(current, [0x64, 0x00]) - 10.0) < 1e-9)
    #expect(try current.encode(.number(10.0)) == [0x64, 0x00])
    #expect(try current.encode(.number(50.0)) == [0xF4, 0x01])
  }

  @Test func firmwareVersionExampleDecodesToIdentifierAndVersion() throws {
    // ":702010000FF120139": identifier 0x00, then version 0x0112FF (v1.12, release).
    let version = try register(0x0102)
    #expect(version.type == .un32)
    #expect(try version.decode([0x00, 0xFF, 0x12, 0x01]) == .integer(0x0112_FF00))
  }

  @Test func asynchronousDeviceStateExampleDecodesToFloat() throws {
    // ":A0102000543": register 0x0201, flags 0x00, value 0x05 (float).
    let state = try register(0x0201)
    #expect(state.type == .un8)
    #expect(try state.decode([0x05]) == .integer(5))
  }

  @Test func notAvailableValuesDecodeToNil() throws {
    #expect(try OrionXS.batteryTemperature.decode([0xFF, 0xFF]) == nil)
    #expect(try OrionXS.sensedBatteryVoltage.decode([0xFF, 0xFF, 0xFF, 0x7F]) == nil)
    #expect(try OrionXS.batteryVoltageSense.decode([0xFF, 0xFF]) == nil)
    #expect(try OrionXS.batteryTemperatureSense.decode([0xFF, 0x7F]) == nil)
    let withNotAvailable = OrionXS.registers.filter { $0.notAvailable != nil }.map(\.id.rawValue)
    #expect(withNotAvailable.sorted() == [0x2002, 0x2003, 0xD18D, 0xEDEC])
  }

  @Test func useMaximumIsNotDecodedAsNotAvailable() throws {
    #expect(try OrionXS.lowTemperatureChargeCurrent.decode([0xFF, 0xFF]) != nil)
  }

  @Test func remoteControlRegistersHaveTheDocumentedTypesAndScales() throws {
    let mode = try register(0x200E)
    #expect(mode.type == .un8)
    #expect(mode.unit == .none)
    #expect(try mode.decode([0x05]) == .integer(5))

    let currentLimit = try register(0x2015)
    #expect(currentLimit.type == .un16)
    #expect(currentLimit.unit == .ampere)
    #expect(abs(currentLimit.scale - 0.1) < 1e-12)
    #expect(try currentLimit.encode(.number(25.0)) == [0xFA, 0x00])

    let voltageSetPoint = try register(0x2001)
    #expect(voltageSetPoint.type == .un16)
    #expect(voltageSetPoint.unit == .volt)
    #expect(abs(voltageSetPoint.scale - 0.01) < 1e-12)
    #expect(try voltageSetPoint.encode(.number(14.2)) == [0x8C, 0x05])

    let voltageSense = try register(0x2002)
    #expect(voltageSense.type == .un16)
    #expect(voltageSense.unit == .volt)
    #expect(abs(voltageSense.scale - 0.01) < 1e-12)

    let temperatureSense = try register(0x2003)
    #expect(temperatureSense.type == .sn16)
    #expect(temperatureSense.unit == .celsius)
    #expect(abs(temperatureSense.scale - 0.01) < 1e-12)
    #expect(abs(try number(temperatureSense, [0x18, 0xFC]) - -10.0) < 1e-9)

    for id: UInt16 in [0x200E, 0x2015, 0x2001, 0x2002, 0x2003] {
      #expect(try !register(id).isPersistent)
    }
  }

  @Test func noRemoteControlRegisterIsPersistent() {
    for register in OrionXS.registers where (0x2000...0x20FF).contains(register.id.rawValue) {
      #expect(!register.isPersistent, "\(register.name)")
    }
  }

  @Test func settingsArePersistentAndMeasurementsAreNot() throws {
    #expect(OrionXS.batteryMaximumCurrent.isPersistent)
    for id: UInt16 in [0xEDFF, 0xEDF7, 0xEDE8, 0xEDCA, 0xEE36, 0xEE39, 0x0320, 0x0321, 0x0090] {
      #expect(try register(id).isPersistent, "\(id)")
    }
    for id: UInt16 in [0xEDEF, 0xEDEC, 0xEDBB, 0xED8D, 0x0200, 0x0201, 0x0004, 0x1030, 0x1070] {
      #expect(try !register(id).isPersistent, "\(id)")
    }
  }

  @Test func chargerDataRegistersHaveTheDocumentedTypesAndScales() throws {
    let inputVoltage = try register(0xEDBB)
    #expect(inputVoltage.type == .un16)
    #expect(abs(try number(inputVoltage, [0x78, 0x05]) - 14.0) < 1e-9)

    let outputPower = try register(0xED8E)
    #expect(outputPower.type == .un32)
    #expect(outputPower.unit == .watt)
    #expect(abs(try number(outputPower, [0x10, 0x27, 0x00, 0x00]) - 100.0) < 1e-9)

    let batteryVoltage = try register(0xD18D)
    #expect(batteryVoltage.type == .sn32)
    #expect(abs(try number(batteryVoltage, [0xE8, 0x32, 0x00, 0x00]) - 13.032) < 1e-9)

    let temperature = try register(0xEDDB)
    #expect(temperature.type == .sn16)
    #expect(temperature.unit == .celsius)

    let compensation = try register(0xEDF2)
    #expect(compensation.type == .sn16)
    #expect(compensation.unit == .millivoltPerKelvin)

    let startDelay = try register(0xEE39)
    #expect(startDelay.type == .un32)
    #expect(startDelay.unit == .second)

    let lockout = try register(0x0320)
    #expect(lockout.type == .un16)
    #expect(abs(lockout.scale - 0.1) < 1e-12)
  }

  @Test func commandsHaveNoValue() throws {
    #expect(try register(0x0004).type == .none)
    #expect(try register(0x1030).type == .none)
  }

  @Test func cycleHistoryCoversTheDocumentedRange() throws {
    let newest = try #require(OrionXS.cycleHistory(0))
    #expect(newest.id.rawValue == 0x1070)
    #expect(newest.type == .bytes)
    let oldest = try #require(OrionXS.cycleHistory(40))
    #expect(oldest.id.rawValue == 0x1098)
    for id: UInt16 in 0x1070...0x1098 {
      #expect(try register(id).type == .bytes)
    }
    #expect(try register(0x1099) == OrionXS.cycleSequenceNumber)
    #expect(try register(0x106F) == OrionXS.cycleCount)
  }

  @Test func cycleHistoryIsNilOutOfRange() {
    #expect(OrionXS.cycleHistory(-1) == nil)
    #expect(OrionXS.cycleHistory(41) == nil)
    #expect(OrionXS.cycleHistory(.min) == nil)
    #expect(OrionXS.cycleHistory(.max) == nil)
  }
}
