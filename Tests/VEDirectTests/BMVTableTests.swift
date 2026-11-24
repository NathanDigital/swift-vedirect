import Testing
import VEDirect

@Suite("BMV700 Series Hex Protocol, Rev 7")
struct BMVTableTests {
  private func register(_ id: UInt16) throws -> Register {
    try #require(BMV.registers.first { $0.id.rawValue == id })
  }

  private func number(_ register: Register, _ bytes: [UInt8]) throws -> Double {
    guard case .number(let value) = try #require(try register.decode(bytes)) else {
      Issue.record("\(register.name) did not decode to a number")
      return .nan
    }
    return value
  }

  @Test func idsAreUnique() {
    let ids = BMV.registers.map(\.id)
    #expect(Set(ids).count == ids.count)
  }

  @Test func namesAreUnique() {
    let names = BMV.registers.map(\.name)
    #expect(Set(names).count == names.count)
    #expect(!names.contains(""))
  }

  @Test func tableHoldsEveryRowOfTheDocument() {
    #expect(BMV.registers.count == 110)
    #expect(BMV.batteryCapacity.name == "batteryCapacity")
    #expect(BMV.dcMonitorMode.name == "dcMonitorMode")
  }

  @Test func getBatteryCapacityExampleDecodesTo200AmpereHours() throws {
    // ":7001000C80076": register 0x1000, flags 0x00, value 0x00C8.
    let capacity = try register(0x1000)
    #expect(capacity == BMV.batteryCapacity)
    #expect(abs(try number(capacity, [0xC8, 0x00]) - 200) < 1e-9)
  }

  @Test func setBatteryCapacityExampleIs500AmpereHours() throws {
    // ":8001000F40148": register 0x1000, flags 0x00, value 0x01F4.
    #expect(abs(try number(BMV.batteryCapacity, [0xF4, 0x01]) - 500) < 1e-9)
    #expect(try BMV.batteryCapacity.encode(.number(500)) == [0xF4, 0x01])
  }

  @Test func parameterErrorExampleReturnsNearestValidCapacity() throws {
    // ":8001004010038": flags 0x04, value 0x0001, the nearest valid value of 1 Ah.
    #expect(abs(try number(BMV.batteryCapacity, [0x01, 0x00]) - 1) < 1e-9)
  }

  @Test func notAvailableValuesDecodeToNil() throws {
    for register in BMV.registers {
      guard let notAvailable = register.notAvailable else { continue }
      let bytes = (0..<4).map { UInt8(truncatingIfNeeded: notAvailable >> UInt32(8 * $0)) }
      let width: Int
      switch register.type {
      case .un8, .sn8: width = 1
      case .un16, .sn16: width = 2
      case .un24: width = 3
      default: width = 4
      }
      #expect(try register.decode(Array(bytes.prefix(width))) == nil)
    }
  }

  @Test func monitorRegistersHaveTheDocumentedTypesAndScales() throws {
    let voltage = try register(0xED8D)
    #expect(voltage.type == .sn16)
    #expect(voltage.unit == .volt)
    #expect(abs(try number(voltage, [0x2A, 0x05]) - 13.22) < 1e-9)

    let current = try register(0xED8C)
    #expect(current.type == .sn32)
    #expect(current.unit == .ampere)
    #expect(abs(try number(current, [0x18, 0xFC, 0xFF, 0xFF]) - -1.0) < 1e-9)

    let stateOfCharge = try register(0x0FFF)
    #expect(stateOfCharge.type == .un16)
    #expect(stateOfCharge.unit == .percent)
    #expect(abs(try number(stateOfCharge, [0x10, 0x27]) - 100) < 1e-9)

    let temperature = try register(0xEDEC)
    #expect(temperature.type == .un16)
    #expect(temperature.unit == .kelvin)
    #expect(abs(temperature.scale - 0.01) < 1e-12)

    let timeToGo = try register(0x0FFE)
    #expect(timeToGo.type == .un16)
    #expect(timeToGo.unit == .minute)
    #expect(abs(timeToGo.scale - 1) < 1e-12)

    let consumed = try register(0xEEFF)
    #expect(consumed.type == .sn32)
    #expect(consumed.unit == .ampereHour)
    #expect(abs(consumed.scale - 0.1) < 1e-12)
  }

  @Test func historyRegistersHaveTheDocumentedTypesAndScales() throws {
    let energy = try register(0x0310)
    #expect(energy.type == .un32)
    #expect(energy.unit == .kilowattHour)
    #expect(abs(try number(energy, [0x39, 0x30, 0x00, 0x00]) - 123.45) < 1e-9)

    let cycles = try register(0x0303)
    #expect(cycles.type == .un32)
    #expect(try cycles.decode([0x07, 0x00, 0x00, 0x00]) == .integer(7))
  }

  @Test func settingsUseTheStepAsScale() throws {
    let chargedVoltage = try register(0x1001)
    #expect(chargedVoltage.type == .un16)
    #expect(abs(try number(chargedVoltage, [0x84, 0x00]) - 13.2) < 1e-9)

    let peukert = try register(0x1005)
    #expect(peukert.unit == .none)
    #expect(abs(try number(peukert, [0x7D, 0x00]) - 1.25) < 1e-9)

    let shuntVoltage = try register(0xEEFA)
    #expect(shuntVoltage.unit == .volt)
    #expect(abs(try number(shuntVoltage, [0x32, 0x00]) - 0.05) < 1e-9)

    let mode = try register(0xEEB8)
    #expect(mode.type == .sn16)
    #expect(try mode.decode([0xF7, 0xFF]) == .integer(-9))
  }

  @Test func settingsArePersistentAndTheRestIsNot() throws {
    for id: UInt16 in [0x1000, 0x1009, 0xEEFC, 0x0320, 0x034F, 0xEEFE, 0xEEE8, 0xEEF6, 0x0090] {
      #expect(try register(id).isPersistent, "\(id)")
    }
    for id: UInt16 in [0x0100, 0xED8D, 0x0FFF, 0x0300, 0x1034, 0xEEF9, 0x031F] {
      #expect(try !register(id).isPersistent, "\(id)")
    }
  }

  @Test func commandsHaveNoValue() throws {
    for id: UInt16 in [0x1029, 0x102C, 0x0004, 0x1030] {
      let command = try register(id)
      #expect(command.type == .none)
      #expect(!command.isPersistent)
    }
  }
}
