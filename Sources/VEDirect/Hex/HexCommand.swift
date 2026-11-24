/// A HEX command to send to a device.
///
/// The library builds the bytes; the caller decides when to send them and how often to repeat
/// them. There is no way to build command `0`, which puts a device in its bootloader.
///
/// Source: section "Frame format", table of commands, in the MPPT, BMV, Orion XS and Phoenix
/// Inverter HEX protocol documents.
public struct HexCommand: Sendable, Equatable {
  let frame: HexFrame

  private init(command: UInt8, payload: [UInt8] = []) {
    self.frame = HexFrame(command: command, payload: payload)
  }

  /// Ping (command `1`); the device answers with ``HexResponse/ping(_:)``.
  public static let ping = HexCommand(command: 1)

  /// Ask for the application version (command `3`); the device answers with
  /// ``HexResponse/done(_:)`` holding the same word as a ping reply. The Orion XS answers
  /// ``HexResponse/unknownCommand(_:)`` and reports its version in register `0x0102`.
  public static let applicationVersion = HexCommand(command: 3)

  /// Ask for the product ID (command `4`); the device answers with ``HexResponse/done(_:)``.
  public static let productID = HexCommand(command: 4)

  /// Restart the device (command `6`); no response is sent.
  public static let restart = HexCommand(command: 6)

  /// Read a register by id (command `7`).
  public static func get(_ id: RegisterID) -> HexCommand {
    HexCommand(command: 7, payload: header(id))
  }

  /// Read a register (command `7`).
  public static func get(_ register: Register) -> HexCommand {
    get(register.id)
  }

  /// Write a run-time register (command `8`).
  ///
  /// - Throws: ``VEDirectError/persistentRegister(_:)`` when the register is stored in
  ///   non-volatile memory, and the errors of ``Register/encode(_:)``.
  public static func set(
    _ register: Register, to value: RegisterValue
  ) throws(VEDirectError) -> HexCommand {
    guard !register.isPersistent else { throw .persistentRegister(register.id) }
    return try setRaw(register.id, bytes: register.encode(value))
  }

  /// Write a setting that the device stores in non-volatile memory (command `8`).
  ///
  /// Victron warns against writing such settings continuously. A Phoenix Inverter keeps the
  /// value only after a save command is written to its register `0xEB99`.
  ///
  /// - Throws: ``VEDirectError/notPersistentRegister(_:)`` when the register is a run-time one,
  ///   and the errors of ``Register/encode(_:)``.
  public static func setPersistent(
    _ register: Register, to value: RegisterValue
  ) throws(VEDirectError) -> HexCommand {
    guard register.isPersistent else { throw .notPersistentRegister(register.id) }
    return try setRaw(register.id, bytes: register.encode(value))
  }

  /// Write raw bytes to any register id (command `8`), with no check of what the register is.
  ///
  /// - Throws: ``VEDirectError/payloadTooLong`` when the frame would exceed
  ///   ``FrameParser/maximumHexLength``.
  public static func setRaw(_ id: RegisterID, bytes: [UInt8]) throws(VEDirectError) -> HexCommand {
    let payload = header(id) + bytes
    guard payload.count < FrameParser.maximumHexLength else { throw .payloadTooLong }
    return HexCommand(command: 8, payload: payload)
  }

  /// The command as bytes to send, from the colon to the line feed, checksum included.
  public func encoded() -> [UInt8] {
    frame.encoded()
  }

  /// The id in little-endian order followed by a zero flags byte.
  private static func header(_ id: RegisterID) -> [UInt8] {
    [UInt8(truncatingIfNeeded: id.rawValue), UInt8(truncatingIfNeeded: id.rawValue >> 8), 0]
  }
}
