import Testing
import VEDirect

/// Registers defined for these tests only, with the layouts the documents' examples use.
private let maximumCurrent = Register(
  0xEDF0, "batteryMaximumCurrent", .un16, scale: 0.1, unit: .ampere, isPersistent: true)
private let capacity = Register(
  0x1000, "batteryCapacity", .un16, unit: .ampereHour, isPersistent: true)
private let currentLimit = Register(0x2015, "chargeCurrentLimit", .un16, scale: 0.1, unit: .ampere)

private func response(_ text: String) throws -> HexResponse {
  try HexResponse(try hexFrame(text))
}

@Suite("HEX protocol documents: commands")
struct HexCommandTests {
  @Test("MPPT section 1.3: ping, application version, product id and restart")
  func simpleCommands() {
    #expect(HexCommand.ping.encoded() == hexLine(":154"))
    #expect(HexCommand.applicationVersion.encoded() == hexLine(":352"))
    #expect(HexCommand.productID.encoded() == hexLine(":451"))
    #expect(HexCommand.restart.encoded() == hexLine(":64F"))
  }

  @Test("MPPT section 1.3, BMV examples, Orion XS section 1.3 and FAQ question 3: get")
  func getCommands() {
    #expect(HexCommand.get(0xEDF0).encoded() == hexLine(":7F0ED0071"))
    #expect(HexCommand.get(maximumCurrent).encoded() == hexLine(":7F0ED0071"))
    #expect(HexCommand.get(0x1000).encoded() == hexLine(":70010003E"))
    #expect(HexCommand.get(0x0102).encoded() == hexLine(":70201004B"))
    #expect(HexCommand.get(0x0FFF).encoded() == hexLine(":7FF0F0040"))
  }

  @Test("MPPT section 1.3 and Orion XS section 1.3: set battery maximum current")
  func setMaximumCurrent() throws {
    #expect(
      try HexCommand.setPersistent(maximumCurrent, to: .number(10)).encoded()
        == hexLine(":8F0ED0064000C"))
    #expect(
      try HexCommand.setPersistent(maximumCurrent, to: .number(50)).encoded()
        == hexLine(":8F0ED00F4017B"))
  }

  @Test("BMV examples: set battery capacity")
  func setCapacity() throws {
    #expect(
      try HexCommand.setPersistent(capacity, to: .number(500)).encoded()
        == hexLine(":8001000F40148"))
    #expect(
      try HexCommand.setPersistent(capacity, to: .number(0)).encoded()
        == hexLine(":800100000003D"))
    #expect(
      try HexCommand.setRaw(0x1000, bytes: [0xF4, 0x01]).encoded() == hexLine(":8001000F40148"))
  }

  @Test("A run-time write and a persistent write cannot be mistaken for each other")
  func writeKinds() throws {
    #expect(throws: VEDirectError.persistentRegister(0xEDF0)) {
      try HexCommand.set(maximumCurrent, to: .number(10))
    }
    #expect(throws: VEDirectError.notPersistentRegister(0x2015)) {
      try HexCommand.setPersistent(currentLimit, to: .number(10))
    }
    // 30.0 A at 0.1 A per bit is 300 = 0x012C; the check byte makes the sum 0x55.
    let bytes = try HexCommand.set(currentLimit, to: .number(30)).encoded()
    #expect(bytes == hexLine(":81520002C01EB"))
    #expect(try hexFrame(":81520002C01EB").payload == [0x15, 0x20, 0x00, 0x2C, 0x01])
  }

  @Test("A write longer than a frame can hold is refused")
  func payloadLimit() throws {
    let longest = Array(repeating: UInt8(0), count: FrameParser.maximumHexLength - 4)
    let command = try HexCommand.setRaw(0x010C, bytes: longest)
    #expect(events(command.encoded()).count == 1)
    #expect(throws: VEDirectError.payloadTooLong) {
      try HexCommand.setRaw(0x010C, bytes: longest + [0])
    }
  }
}

@Suite("HEX protocol documents: responses")
struct HexResponseTests {
  @Test("MPPT section 1.3: ping reply 0x4116 is application version 1.16")
  func mpptPing() throws {
    guard case .ping(let reply) = try response(":51641F9") else {
      Issue.record("not a ping reply")
      return
    }
    #expect(reply.rawValue == 0x4116)
    #expect(reply.firmwareType == .application)
    #expect(reply.version == FirmwareVersion(major: 1, minor: 16))
  }

  @Test("MPPT section 1.3: application version and product id come back as done")
  func mpptDone() throws {
    guard case .done(let version) = try response(":11641FD") else {
      Issue.record("not a done response")
      return
    }
    #expect(try PingReply(payload: version).version == FirmwareVersion(major: 1, minor: 16))
    guard case .done(let product) = try response(":1000351") else {
      Issue.record("not a done response")
      return
    }
    #expect(try ProductID(payload: product) == 0x0300)
  }

  @Test("MPPT section 1.3: get, set, unknown command, error and asynchronous responses")
  func mpptResponses() throws {
    let get = RegisterReply(id: 0xEDF0, flags: [], value: [0x96, 0x00])
    #expect(try response(":7F0ED009600DB") == .get(get))
    #expect(try get.decoded(as: maximumCurrent) == .number(15))
    #expect(
      try response(":8F0ED0064000C")
        == .set(RegisterReply(id: 0xEDF0, flags: [], value: [0x64, 0x00])))
    #expect(try response(":3020050") == .unknownCommand(2))
    #expect(try response(":4AAAAFD") == .error(0xAAAA))
    #expect(
      try response(":A0102000543")
        == .asynchronous(RegisterReply(id: 0x0201, flags: [], value: [0x05])))
  }

  @Test("Orion XS section 1.3: ping reply 0x7FFF is the application with no version")
  func orionPing() throws {
    guard case .ping(let reply) = try response(":5FF7FD2") else {
      Issue.record("not a ping reply")
      return
    }
    #expect(reply.firmwareType == .application)
    #expect(reply.version == nil)
  }

  @Test("Orion XS section 1.3: product id, firmware register and checksum failure")
  func orionResponses() throws {
    guard case .done(let product) = try response(":1F0A3C1") else {
      Issue.record("not a done response")
      return
    }
    #expect(try ProductID(payload: product) == 0xA3F0)
    #expect(
      try response(":702010000FF120139")
        == .get(RegisterReply(id: 0x0102, flags: [], value: [0x00, 0xFF, 0x12, 0x01])))
    // "0x0112FF = v1.12-release"
    #expect(FirmwareVersion(extended: 0x0112FF) == FirmwareVersion(major: 1, minor: 12))
    #expect(try response(":2AAAAFF") == .checksumError)
    let reply = RegisterReply(id: 0xEDF0, flags: [], value: [0xF4, 0x01])
    #expect(try response(":7F0ED00F4017C") == .get(reply))
    #expect(try reply.decoded(as: maximumCurrent) == .number(50))
  }

  @Test("BMV examples: ping 0x4401 is application version 4.01 and the product is 0xA381")
  func bmvIdentity() throws {
    guard case .ping(let reply) = try response(":501440B") else {
      Issue.record("not a ping reply")
      return
    }
    #expect(reply.version == FirmwareVersion(major: 4, minor: 1))
    guard case .done(let product) = try response(":181A330") else {
      Issue.record("not a done response")
      return
    }
    #expect(try ProductID(payload: product) == 0xA381)
  }

  @Test("BMV examples: capacity reads 200 Ah, and a rejected write returns the nearest value")
  func bmvCapacity() throws {
    guard case .get(let get) = try response(":7001000C80076") else {
      Issue.record("not a get response")
      return
    }
    #expect(try get.decoded(as: capacity) == .number(200))
    guard case .set(let rejected) = try response(":8001004010038") else {
      Issue.record("not a set response")
      return
    }
    #expect(rejected.flags == .parameterError)
    #expect(rejected.value == [0x01, 0x00])
    #expect(throws: VEDirectError.parameterError(0x1000)) {
      try rejected.decoded(as: capacity)
    }
  }

  @Test("Each response flag is surfaced as its own error")
  func flags() {
    let unknown = RegisterReply(id: 0x1234, flags: .unknownID, value: [])
    #expect(throws: VEDirectError.unknownRegister(0x1234)) { try unknown.decoded(as: capacity) }
    let readOnly = RegisterReply(id: 0x1234, flags: .notSupported, value: [0, 0])
    #expect(throws: VEDirectError.notSupported(0x1234)) { try readOnly.decoded(as: capacity) }
    let range = RegisterReply(id: 0x1234, flags: .parameterError, value: [0, 0])
    #expect(throws: VEDirectError.parameterError(0x1234)) { try range.decoded(as: capacity) }
  }

  @Test("A release candidate is named by the top digit of the ping word")
  func releaseCandidate() {
    // "0xD101 represents release candidate D of version 1.01"
    let reply = PingReply(rawValue: 0xD101)
    #expect(reply.firmwareType == .releaseCandidate)
    #expect(reply.version == FirmwareVersion(major: 1, minor: 1, candidate: UInt8(ascii: "D")))
    #expect(PingReply(rawValue: 0x0101).firmwareType == .bootloader)
  }

  @Test("A response shorter than its layout throws and an unknown response number is kept")
  func malformedResponses() throws {
    #expect(throws: VEDirectError.truncatedPayload) { try response(":7F0ED71") }
    #expect(throws: VEDirectError.truncatedPayload) { try response(":5FF51") }
    #expect(throws: VEDirectError.truncatedPayload) { try response(":40051") }
    #expect(try response(":901020049") == .other(command: 9, payload: [0x01, 0x02, 0x00]))
  }
}

@Suite("Register values")
struct RegisterValueTests {
  @Test("Integers decode little-endian at the width received")
  func widths() throws {
    let unsigned = Register(0x0001, "u", .un16)
    #expect(try unsigned.decode([0x34]) == .integer(0x34))
    #expect(try unsigned.decode([0x34, 0x12]) == .integer(0x1234))
    #expect(try unsigned.decode([0x56, 0x34, 0x12]) == .integer(0x123456))
    #expect(try unsigned.decode([0x78, 0x56, 0x34, 0x12]) == .integer(0x1234_5678))
    #expect(try unsigned.decode([0xFF, 0xFF, 0xFF, 0xFF]) == .integer(0xFFFF_FFFF))
    #expect(throws: VEDirectError.unexpectedLength(0x0001)) { try unsigned.decode([]) }
    #expect(throws: VEDirectError.unexpectedLength(0x0001)) {
      try unsigned.decode([1, 2, 3, 4, 5])
    }
  }

  @Test("Signed integers are sign-extended from the width received")
  func signed() throws {
    let register = Register(0x0002, "s", .sn16)
    #expect(try register.decode([0xFF]) == .integer(-1))
    #expect(try register.decode([0xFE, 0xFF]) == .integer(-2))
    #expect(try register.decode([0x00, 0x80]) == .integer(-32768))
    #expect(try register.decode([0xFF, 0x7F]) == .integer(32767))
    #expect(try register.decode([0xFD, 0xFF, 0xFF, 0xFF]) == .integer(-3))
  }

  @Test("A scaled register decodes to a number and its not-available value to nil")
  func scaled() throws {
    let temperature = Register(
      0x2003, "t", .sn16, scale: 0.01, unit: .celsius, notAvailable: 0x7FFF)
    #expect(try temperature.decode([0x18, 0xFC]) == .number(-10))
    #expect(try temperature.decode([0xFF, 0x7F]) == nil)
  }

  @Test("Text stops at the first zero byte and bytes are passed through")
  func textAndBytes() throws {
    let text = Register(0x010B, "model", .text)
    #expect(try text.decode(ascii("BMV-712") + [0, 0, 0]) == .text("BMV-712"))
    #expect(try text.decode([0xFF, 0xFE]) == .bytes([0xFF, 0xFE]))
    #expect(try text.encode(.text("AB")) == [0x41, 0x42, 0x00])
    let record = Register(0x1050, "day", .bytes)
    #expect(try record.decode([1, 2, 3]) == .bytes([1, 2, 3]))
    #expect(try record.encode(.bytes([9])) == [9])
  }

  @Test("Numbers are divided by the scale, rounded and written little-endian")
  func encoding() throws {
    let current = Register(0x2015, "i", .un16, scale: 0.1, unit: .ampere)
    #expect(try current.encode(.number(30)) == [0x2C, 0x01])
    #expect(try current.encode(.number(0.34)) == [0x03, 0x00])
    let temperature = Register(0x2003, "t", .sn16, scale: 0.01, unit: .celsius)
    #expect(try temperature.encode(.number(-10)) == [0x18, 0xFC])
    let mode = Register(0x200E, "mode", .un8)
    #expect(try mode.encode(.integer(5)) == [0x05])
    let wide = Register(0x0003, "w", .un32)
    #expect(try wide.encode(.integer(0xFFFF_FFFF)) == [0xFF, 0xFF, 0xFF, 0xFF])
    let three = Register(0x0004, "three", .un24)
    #expect(try three.encode(.integer(0x0112FF)) == [0xFF, 0x12, 0x01])
  }

  @Test("A value of the wrong kind or outside the register's width is refused")
  func encodingErrors() {
    let current = Register(0x2015, "i", .un16, scale: 0.1, unit: .ampere)
    let mode = Register(0x200E, "mode", .un8)
    #expect(throws: VEDirectError.valueTypeMismatch(0x2015)) { try current.encode(.integer(300)) }
    #expect(throws: VEDirectError.valueTypeMismatch(0x200E)) { try mode.encode(.number(5)) }
    #expect(throws: VEDirectError.valueTypeMismatch(0x200E)) { try mode.encode(.text("5")) }
    #expect(throws: VEDirectError.valueOutOfRange(0x200E)) { try mode.encode(.integer(256)) }
    #expect(throws: VEDirectError.valueOutOfRange(0x200E)) { try mode.encode(.integer(-1)) }
    #expect(throws: VEDirectError.valueOutOfRange(0x2015)) { try current.encode(.number(-0.1)) }
    #expect(throws: VEDirectError.valueOutOfRange(0x2015)) { try current.encode(.number(6553.6)) }
    #expect(throws: VEDirectError.valueOutOfRange(0x2015)) { try current.encode(.number(.nan)) }
    #expect(throws: VEDirectError.valueOutOfRange(0x2015)) {
      try current.encode(.number(.infinity))
    }
  }

  @Test(
    "Random bytes never trap a decode", arguments: [RegisterType.un8, .sn16, .un32, .text, .bytes])
  func randomDecode(type: RegisterType) {
    let register = Register(0x0001, "r", type, scale: 0.01, unit: .volt, notAvailable: 0xFFFF)
    var generator = SeededGenerator(seed: 4)
    for _ in 0..<5000 {
      let length = Int.random(in: 0...70, using: &generator)
      let bytes = (0..<length).map { _ in UInt8.random(in: .min ... .max, using: &generator) }
      _ = try? register.decode(bytes)
    }
  }
}
