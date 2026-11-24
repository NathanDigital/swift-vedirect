import Testing
import VEDirect

@Suite("VE.Direct Protocol - Phoenix Inverters, Rev 5")
struct PhoenixInverterTableTests {
  private func register(_ id: UInt16) throws -> Register {
    try #require(PhoenixInverter.registers.first { $0.id.rawValue == id })
  }

  private func number(_ register: Register, _ bytes: [UInt8]) throws -> Double {
    guard case .number(let value) = try #require(try register.decode(bytes)) else {
      Issue.record("\(register.name) did not decode to a number")
      return .nan
    }
    return value
  }

  @Test func idsAreUnique() {
    let ids = PhoenixInverter.registers.map(\.id)
    #expect(Set(ids).count == ids.count)
  }

  @Test func namesAreUnique() {
    let names = PhoenixInverter.registers.map(\.name)
    #expect(Set(names).count == names.count)
    #expect(!names.contains(""))
  }

  @Test func tableHoldsEveryRowOfTheDocument() {
    #expect(PhoenixInverter.registers.count == 48)
    #expect(PhoenixInverter.acOutputVoltage.name == "acOutputVoltage")
  }

  @Test func asynchronousDeviceStateExampleDecodesToItsValue() throws {
    // ":A0102000543": register 0x0201, flags 0x00, value 0x05.
    let state = try register(0x0201)
    #expect(state == PhoenixInverter.deviceState)
    #expect(try state.decode([0x05]) == .integer(5))
  }

  @Test func noRegisterDefinesANotAvailableValue() {
    #expect(PhoenixInverter.registers.allSatisfy { $0.notAvailable == nil })
  }

  @Test func operationRegistersHaveTheDocumentedTypesAndScales() throws {
    let voltage = try register(0x2200)
    #expect(voltage.type == .sn16)
    #expect(voltage.unit == .volt)
    #expect(abs(try number(voltage, [0xD8, 0x59]) - 230.0) < 1e-9)

    let current = try register(0x2201)
    #expect(current.type == .sn16)
    #expect(current.unit == .ampere)
    #expect(abs(try number(current, [0x0F, 0x00]) - 1.5) < 1e-9)

    let power = try register(0x2205)
    #expect(power.type == .sn32)
    #expect(power.unit == .voltAmpere)
    #expect(abs(try number(power, [0xFA, 0x00, 0x00, 0x00]) - 250.0) < 1e-9)

    let energy = try register(0x1041)
    #expect(energy.type == .un32)
    #expect(energy.unit == .kilovoltAmpereHour)
    #expect(abs(try number(energy, [0x39, 0x30, 0x00, 0x00]) - 123.45) < 1e-9)

    let battery = try register(0xED8D)
    #expect(battery.type == .sn16)
    #expect(abs(try number(battery, [0xE2, 0x04]) - 12.5) < 1e-9)

    let loopCurrent = try register(0xEB4E)
    #expect(loopCurrent.type == .sn16)
    #expect(abs(loopCurrent.scale - 0.001) < 1e-12)
  }

  @Test func settingsHaveTheDocumentedTypesAndScales() throws {
    let setPoint = try register(0x0230)
    #expect(setPoint.type == .un16)
    #expect(try setPoint.encode(.number(230.0)) == [0xD8, 0x59])

    let retryTime = try register(0xEB06)
    #expect(retryTime.type == .un8)
    #expect(retryTime.unit == .second)
    #expect(abs(try number(retryTime, [0x0A]) - 2.5) < 1e-9)

    let periods = try register(0xEB10)
    #expect(periods.type == .un8)
    #expect(try periods.decode([0x03]) == .integer(3))

    let cutoffVoltage = try register(0xEBB1)
    #expect(cutoffVoltage.type == .un16)
    #expect(abs(cutoffVoltage.scale - 0.001) < 1e-12)

    let cutoffEnabled = try register(0xEBBA)
    #expect(cutoffEnabled.type == .un8)

    let ratedPower = try register(0x2203)
    #expect(ratedPower.type == .sn16)
    #expect(ratedPower.unit == .voltAmpere)

    #expect(try register(0x0100).type == .un32)
    #expect(try register(0x0101).type == .un24)
    #expect(try register(0x0207).type == .un32)
    #expect(try register(0x031C).type == .un16)
  }

  @Test func writableSettingsArePersistentAndTheRestIsNot() throws {
    let persistent: [UInt16] = [
      0x0090, 0x0230, 0x2206, 0x2207, 0xEB03, 0xEB04, 0xEB06, 0xEB10, 0x2210, 0x0320, 0x0321,
      0xEBBA, 0xEBB7, 0xEBB5, 0xEBB3, 0xEBB2, 0x034E, 0x034F,
    ]
    for register in PhoenixInverter.registers {
      #expect(
        register.isPersistent == persistent.contains(register.id.rawValue), "\(register.name)")
    }
  }

  @Test func saveCommandIsAnUnsignedByteAndRestoreDefaultsHasNoValue() throws {
    let command = try register(0xEB99)
    #expect(command.type == .un8)
    #expect(!command.isPersistent)
    #expect(try command.encode(.integer(1)) == [0x01])
    #expect(try register(0x0004).type == .none)
  }
}
