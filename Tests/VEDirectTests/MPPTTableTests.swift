import Testing
import VEDirect

@Suite("VE.Direct Protocol – BlueSolar and SmartSolar MPPT chargers, Rev 18: register table")
struct MPPTTableTests {
  /// Whether a decoded value is a number within a small tolerance of the expected one.
  private func isNumber(_ value: RegisterValue?, near expected: Double) -> Bool {
    guard case .number(let number) = value else { return false }
    return abs(number - expected) < 1e-9
  }

  /// The little-endian bytes of a wire integer at the width of an integer register type.
  private func bytes(of raw: UInt32, as type: RegisterType) -> [UInt8]? {
    let width: Int
    switch type {
    case .un8, .sn8: width = 1
    case .un16, .sn16: width = 2
    case .un24: width = 3
    case .un32, .sn32: width = 4
    case .text, .bytes, .none: return nil
    }
    return (0..<width).map { UInt8(truncatingIfNeeded: raw >> UInt32(8 * $0)) }
  }

  private func register(_ id: UInt16) throws -> Register {
    try #require(MPPT.registers.first { $0.id.rawValue == id })
  }

  // MARK: Table integrity

  @Test("Register ids are unique")
  func idsAreUnique() {
    let ids = MPPT.registers.map(\.id)
    #expect(Set(ids).count == ids.count)
  }

  @Test("Register names are unique")
  func namesAreUnique() {
    let names = MPPT.registers.map(\.name)
    #expect(Set(names).count == names.count)
    #expect(!names.contains(""))
  }

  @Test("The table holds every register of the document")
  func tableIsComplete() {
    #expect(MPPT.registers.count == 206)
  }

  @Test("Registers without a value carry neither scale nor unit")
  func commandRegisters() throws {
    for id: UInt16 in [0x0004, 0x1030] {
      let register = try register(id)
      #expect(register.type == .none)
      #expect(register.scale == 1)
      #expect(register.unit == .none)
      #expect(!register.isPersistent)
    }
  }

  // MARK: Message examples (section 1.3)

  @Test("Get Battery Maximum Current: value 0x0096 is 15.0 A")
  func getBatteryMaximumCurrentExample() throws {
    let value = try MPPT.batteryMaximumCurrent.decode([0x96, 0x00])
    #expect(isNumber(value, near: 15.0))
  }

  @Test("Set Battery Maximum Current: value 0x0064 is 10.0 A")
  func setBatteryMaximumCurrentExample() throws {
    let value = try MPPT.batteryMaximumCurrent.decode([0x64, 0x00])
    #expect(isNumber(value, near: 10.0))
    #expect(try MPPT.batteryMaximumCurrent.encode(.number(10.0)) == [0x64, 0x00])
  }

  @Test("Asynchronous message: register 0x0201 with value 0x05 is float")
  func asynchronousDeviceStateExample() throws {
    #expect(MPPT.deviceState.id.rawValue == 0x0201)
    #expect(try MPPT.deviceState.decode([0x05]) == .integer(5))
  }

  // MARK: Not-available values

  @Test("Every not-available value decodes to nil")
  func notAvailableDecodesToNil() throws {
    var checked = 0
    for register in MPPT.registers {
      guard let notAvailable = register.notAvailable else { continue }
      let wire = try #require(bytes(of: notAvailable, as: register.type))
      #expect(try register.decode(wire) == nil, "\(register.name)")
      checked += 1
    }
    #expect(checked == 4)
  }

  @Test("The document's not-available values are set on the registers it names")
  func notAvailableValues() throws {
    #expect(MPPT.batteryTemperature.notAvailable == 0xFFFF)
    #expect(MPPT.batteryVoltageSense.notAvailable == 0xFFFF)
    #expect(MPPT.batteryTemperatureSense.notAvailable == 0x7FFF)
    #expect(MPPT.timeOfDay.notAvailable == 0xFFFF)
    #expect(try MPPT.batteryVoltageSense.decode([0xFF, 0xFF]) == nil)
    #expect(try MPPT.batteryTemperatureSense.decode([0xFF, 0x7F]) == nil)
  }

  @Test("0xFFFF on the low temperature charge current means use maximum, not unavailable")
  func useMaximumIsNotUnavailable() throws {
    #expect(MPPT.lowTemperatureChargeCurrent.notAvailable == nil)
    let value = try MPPT.lowTemperatureChargeCurrent.decode([0xFF, 0xFF])
    #expect(isNumber(value, near: 6553.5))
  }

  // MARK: Remote control registers

  @Test("Remote control registers have the document's types and scales")
  func remoteControlRegisters() throws {
    let networkMode = try register(0x200E)
    #expect(networkMode == MPPT.networkMode)
    #expect(networkMode.type == .un8)
    #expect(networkMode.scale == 1)
    #expect(networkMode.unit == .none)

    let currentLimit = try register(0x2015)
    #expect(currentLimit == MPPT.chargeCurrentLimit)
    #expect(currentLimit.type == .un16)
    #expect(currentLimit.scale == 0.1)
    #expect(currentLimit.unit == .ampere)

    let voltageSetPoint = try register(0x2001)
    #expect(voltageSetPoint == MPPT.chargeVoltageSetPoint)
    #expect(voltageSetPoint.type == .un16)
    #expect(voltageSetPoint.scale == 0.01)
    #expect(voltageSetPoint.unit == .volt)

    let voltageSense = try register(0x2002)
    #expect(voltageSense == MPPT.batteryVoltageSense)
    #expect(voltageSense.type == .un16)
    #expect(voltageSense.scale == 0.01)
    #expect(voltageSense.unit == .volt)

    let temperatureSense = try register(0x2003)
    #expect(temperatureSense == MPPT.batteryTemperatureSense)
    #expect(temperatureSense.type == .sn16)
    #expect(temperatureSense.scale == 0.01)
    #expect(temperatureSense.unit == .celsius)
  }

  @Test("No remote control register is persistent")
  func remoteControlRegistersAreNotPersistent() {
    let remote = MPPT.registers.filter { (0x2000...0x2027).contains($0.id.rawValue) }
    #expect(remote.count == 19)
    for register in remote {
      #expect(!register.isPersistent, "\(register.name)")
    }
  }

  @Test("Remote control values decode with sign and scale")
  func remoteControlValuesDecode() throws {
    #expect(isNumber(try MPPT.batteryTemperatureSense.decode([0x18, 0xFC]), near: -10.0))
    #expect(isNumber(try MPPT.chargeVoltageSetPoint.decode([0xA0, 0x05]), near: 14.4))
    #expect(isNumber(try MPPT.chargeCurrentLimit.decode([0xF4, 0x01]), near: 50.0))
    #expect(try MPPT.networkMode.decode([0x05]) == .integer(5))
  }

  // MARK: Persistence

  @Test("Battery settings are persistent, the battery temperature measurement is not")
  func batterySettingsArePersistent() throws {
    #expect(MPPT.batteryMaximumCurrent.isPersistent)
    #expect(try register(0xEDF0) == MPPT.batteryMaximumCurrent)
    let settings: [UInt16] = [
      0xEDFF, 0xEDFE, 0xEDFD, 0xEDFC, 0xEDFB, 0xEDF7, 0xEDF6, 0xEDF4, 0xEDF2, 0xEDF1, 0xEDF0,
      0xEDEF, 0xEDEA, 0xEDE8, 0xEDE7, 0xEDE6, 0xEDE5, 0xEDE4, 0xEDE3, 0xED2E, 0xEDE0, 0xEDCA,
    ]
    for id in settings {
      let register = try register(id)
      #expect(register.isPersistent, "\(register.name)")
    }
    #expect(!MPPT.batteryTemperature.isPersistent)
  }

  @Test("Measurements, status and history are not persistent")
  func measurementsAreNotPersistent() throws {
    let ids: [UInt16] = [
      0x0100, 0x0200, 0x0201, 0x0202, 0x0207, 0xEDD5, 0xEDD7, 0xEDDA, 0xEDBC, 0xEDBB, 0xEDAD,
      0xEDA8, 0x104F, 0x1050, 0x10A0, 0x2030, 0x2031,
    ]
    for id in ids {
      let register = try register(id)
      #expect(!register.isPersistent, "\(register.name)")
    }
  }

  // MARK: History

  @Test("Day history covers 0x1050 to 0x106E and nothing else")
  func dayHistoryRange() throws {
    #expect(MPPT.dayHistory(daysAgo: -1) == nil)
    #expect(MPPT.dayHistory(daysAgo: 31) == nil)
    #expect(MPPT.dayHistory(daysAgo: .min) == nil)
    #expect(MPPT.dayHistory(daysAgo: .max) == nil)
    let today = try #require(MPPT.dayHistory(daysAgo: 0))
    #expect(today.id.rawValue == 0x1050)
    #expect(today.type == .bytes)
    let yesterday = try #require(MPPT.dayHistory(daysAgo: 1))
    #expect(yesterday.id.rawValue == 0x1051)
    let oldest = try #require(MPPT.dayHistory(daysAgo: 30))
    #expect(oldest.id.rawValue == 0x106E)
    for daysAgo in 0...30 {
      let register = try #require(MPPT.dayHistory(daysAgo: daysAgo))
      #expect(MPPT.registers.contains(register))
    }
  }

  @Test("Tracker day history covers 0x10A0 to 0x10BE and nothing else")
  func trackerDayHistoryRange() throws {
    #expect(MPPT.trackerDayHistory(daysAgo: -1) == nil)
    #expect(MPPT.trackerDayHistory(daysAgo: 31) == nil)
    #expect(MPPT.trackerDayHistory(daysAgo: .min) == nil)
    #expect(MPPT.trackerDayHistory(daysAgo: .max) == nil)
    let today = try #require(MPPT.trackerDayHistory(daysAgo: 0))
    #expect(today.id.rawValue == 0x10A0)
    #expect(today.type == .bytes)
    let oldest = try #require(MPPT.trackerDayHistory(daysAgo: 30))
    #expect(oldest.id.rawValue == 0x10BE)
    for daysAgo in 0...30 {
      let register = try #require(MPPT.trackerDayHistory(daysAgo: daysAgo))
      #expect(MPPT.registers.contains(register))
    }
  }

  @Test("History records pass through as bytes")
  func historyRecordsAreBytes() throws {
    let record = [UInt8](repeating: 0xFF, count: 34)
    #expect(try MPPT.historyTotals.decode(record) == .bytes(record))
    let today = try #require(MPPT.dayHistory(daysAgo: 0))
    #expect(try today.decode(record) == .bytes(record))
  }
}
