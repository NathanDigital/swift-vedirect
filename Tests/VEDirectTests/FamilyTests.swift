import Testing
import VEDirect

@Suite("Product families and their register tables")
struct FamilyTests {
  @Test("A product id leads to its family's definition of a register")
  func lookupByProduct() throws {
    let orion = ProductID(rawValue: 0xA3F0).family
    #expect(orion == .orionXS)
    #expect(orion.register(0x2015) == OrionXS.chargeCurrentLimit)
    #expect(ProductID(rawValue: 0xA057).family.register(0x2015) == MPPT.chargeCurrentLimit)
    #expect(ProductID(rawValue: 0xA381).family.register(0x1000)?.unit == .ampereHour)
    #expect(ProductID(rawValue: 0xA381).family.register(0x2015) == nil)
  }

  @Test("A family without a HEX document, and an unknown product, have no registers")
  func familiesWithoutRegisters() {
    #expect(ProductFamily.smartShunt.registers.isEmpty)
    #expect(ProductFamily.phoenixCharger.registers.isEmpty)
    #expect(ProductFamily.unknown.register(0xEDF0) == nil)
  }

  @Test("The same id is defined differently by different families")
  func perFamilyDefinitions() throws {
    // 0xED8D is signed on a BMV and unsigned on an Orion XS.
    let bmv = try #require(ProductFamily.bmv.register(0xED8D))
    let orion = try #require(ProductFamily.orionXS.register(0xED8D))
    #expect(bmv.type == .sn16)
    #expect(orion.type == .un16)
    #expect(try bmv.decode([0xFF, 0xFF]) == .number(-0.01))
    #expect(try #require(try orion.decode([0xFF, 0xFF])) != .number(-0.01))
  }

  @Test("External control of an Orion XS: network mode and charge current limit, byte for byte")
  func externalControlFrames() throws {
    // 0x200E = 0x05: 8 + 0E + 20 + 00 + 05 = 0x3B, check 0x1A.
    #expect(
      try HexCommand.set(OrionXS.networkMode, to: .integer(5)).encoded()
        == hexLine(":80E2000051A"))
    // 0x2015 = 30.0 A = 0x012C: 8 + 15 + 20 + 00 + 2C + 01 = 0x6A, check 0xEB.
    #expect(
      try HexCommand.set(OrionXS.chargeCurrentLimit, to: .number(30)).encoded()
        == hexLine(":81520002C01EB"))
    #expect(throws: VEDirectError.persistentRegister(0xEDF0)) {
      try HexCommand.set(OrionXS.batteryMaximumCurrent, to: .number(30))
    }
  }

  @Test("Every register of every family decodes random bytes without trapping")
  func randomDecodeOverTables() {
    var generator = SeededGenerator(seed: 5)
    let families: [ProductFamily] = [.bmv, .mppt, .orionXS, .phoenixInverter]
    for family in families {
      #expect(!family.registers.isEmpty)
      for register in family.registers {
        for length in 0...8 {
          let bytes = (0..<length).map { _ in UInt8.random(in: .min ... .max, using: &generator) }
          _ = try? register.decode(bytes)
        }
      }
    }
  }
}
