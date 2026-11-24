/// The 16-bit id of a HEX register.
///
/// Ids are one namespace across Victron products, but a register's type, scale and meaning can
/// differ between product families, so definitions live in per-family tables.
public struct RegisterID: RawRepresentable, Hashable, Sendable {
  /// The id on the wire.
  public let rawValue: UInt16

  /// Creates an id from its wire value.
  public init(rawValue: UInt16) { self.rawValue = rawValue }
}

extension RegisterID: ExpressibleByIntegerLiteral {
  /// Creates an id from a literal such as `0xEDF0`.
  public init(integerLiteral value: UInt16) { self.rawValue = value }
}

/// How a register's value is laid out on the wire.
public enum RegisterType: Sendable, Equatable {
  /// Unsigned 8-bit integer.
  case un8
  /// Unsigned 16-bit integer.
  case un16
  /// Unsigned 24-bit integer.
  case un24
  /// Unsigned 32-bit integer.
  case un32
  /// Signed 8-bit integer.
  case sn8
  /// Signed 16-bit integer.
  case sn16
  /// Signed 32-bit integer.
  case sn32
  /// Text, ended by a zero byte when shorter than the register.
  case text
  /// A record or other bytes the library does not split into fields.
  case bytes
  /// No value: a register that is written to trigger an action.
  case none

  /// The number of bytes an integer of this type occupies, or `nil` for the other types.
  var integerWidth: Int? {
    switch self {
    case .un8, .sn8: 1
    case .un16, .sn16: 2
    case .un24: 3
    case .un32, .sn32: 4
    case .text, .bytes, .none: nil
    }
  }

  var isSigned: Bool {
    switch self {
    case .sn8, .sn16, .sn32: true
    default: false
    }
  }
}

/// The unit of a register's scaled value.
public struct RegisterUnit: RawRepresentable, Hashable, Sendable {
  /// The unit's symbol; empty for a value without a unit.
  public let rawValue: String

  /// Creates a unit from its symbol.
  public init(rawValue: String) { self.rawValue = rawValue }

  /// No unit: a count, an enumeration, a bit field or a ratio.
  public static let none = RegisterUnit(rawValue: "")
  /// Volts.
  public static let volt = RegisterUnit(rawValue: "V")
  /// Amperes.
  public static let ampere = RegisterUnit(rawValue: "A")
  /// Watts.
  public static let watt = RegisterUnit(rawValue: "W")
  /// Volt-amperes.
  public static let voltAmpere = RegisterUnit(rawValue: "VA")
  /// Ampere-hours.
  public static let ampereHour = RegisterUnit(rawValue: "Ah")
  /// Kilowatt-hours.
  public static let kilowattHour = RegisterUnit(rawValue: "kWh")
  /// Kilovolt-ampere-hours.
  public static let kilovoltAmpereHour = RegisterUnit(rawValue: "kVAh")
  /// Percent.
  public static let percent = RegisterUnit(rawValue: "%")
  /// Kelvin.
  public static let kelvin = RegisterUnit(rawValue: "K")
  /// Degrees Celsius.
  public static let celsius = RegisterUnit(rawValue: "°C")
  /// Ohms.
  public static let ohm = RegisterUnit(rawValue: "Ω")
  /// Milliseconds.
  public static let millisecond = RegisterUnit(rawValue: "ms")
  /// Seconds.
  public static let second = RegisterUnit(rawValue: "s")
  /// Minutes.
  public static let minute = RegisterUnit(rawValue: "min")
  /// Hours.
  public static let hour = RegisterUnit(rawValue: "h")
  /// Days.
  public static let day = RegisterUnit(rawValue: "d")
  /// Millivolts per kelvin, used for temperature compensation.
  public static let millivoltPerKelvin = RegisterUnit(rawValue: "mV/K")
}

/// A register's value after decoding, or before encoding.
public enum RegisterValue: Sendable, Equatable {
  /// A measurement or setting in the register's unit, already multiplied by its scale.
  case number(Double)
  /// A count, enumeration value or bit field, exactly as on the wire.
  case integer(Int64)
  /// Text.
  case text(String)
  /// Bytes the library does not interpret.
  case bytes([UInt8])
}

/// The definition of one HEX register for one product family.
///
/// A definition says how to turn the register's bytes into a value and back. Callers may create
/// their own for registers the library does not list.
public struct Register: Sendable, Equatable {
  /// The register's id.
  public let id: RegisterID
  /// A short name in lowerCamelCase, unique within its family table.
  public let name: String
  /// How the value is laid out on the wire.
  public let type: RegisterType
  /// The number a wire integer is multiplied by to give the value in ``unit``.
  public let scale: Double
  /// The unit of the scaled value.
  public let unit: RegisterUnit
  /// Whether the device stores a written value in non-volatile memory.
  ///
  /// Victron warns that such settings must not be written continuously. A persistent register
  /// is written with ``HexCommand/setPersistent(_:to:)``.
  public let isPersistent: Bool
  /// The wire integer that means the device has no value, if the register has one.
  public let notAvailable: UInt32?

  /// Creates a register definition.
  public init(
    _ id: RegisterID,
    _ name: String,
    _ type: RegisterType,
    scale: Double = 1,
    unit: RegisterUnit = .none,
    isPersistent: Bool = false,
    notAvailable: UInt32? = nil
  ) {
    self.id = id
    self.name = name
    self.type = type
    self.scale = scale
    self.unit = unit
    self.isPersistent = isPersistent
    self.notAvailable = notAvailable
  }

  /// Whether the value decodes to ``RegisterValue/number(_:)`` and not ``RegisterValue/integer(_:)``.
  var isScaled: Bool { unit != .none || scale != 1 }

  /// Decodes the value bytes of a get, set or asynchronous response.
  ///
  /// An integer is read at the width received, because some registers changed width between
  /// firmware versions; the definition supplies only the signedness and scale.
  ///
  /// - Returns: The value, or `nil` when the bytes are the register's not-available value.
  /// - Throws: ``VEDirectError/unexpectedLength(_:)`` when an integer is not 1 to 4 bytes long.
  public func decode(_ bytes: [UInt8]) throws(VEDirectError) -> RegisterValue? {
    switch type {
    case .bytes, .none:
      return .bytes(bytes)
    case .text:
      let characters = Array(bytes.prefix { $0 != 0 })
      guard let text = String(validating: characters, as: UTF8.self) else {
        return .bytes(bytes)
      }
      return .text(text)
    case .un8, .un16, .un24, .un32, .sn8, .sn16, .sn32:
      guard (1...4).contains(bytes.count) else { throw .unexpectedLength(id) }
      var raw: UInt32 = 0
      for byte in bytes.reversed() {
        raw = raw << 8 | UInt32(truncatingIfNeeded: byte)
      }
      if raw == notAvailable {
        return nil
      }
      var integer = Int64(truncatingIfNeeded: raw)
      if type.isSigned {
        let unusedBits = Int64(64 - 8 * bytes.count)
        integer = (integer << unusedBits) >> unusedBits
      }
      return isScaled ? .number(Double(integer) * scale) : .integer(integer)
    }
  }

  /// Encodes a value as the bytes of a set command.
  ///
  /// A register with a unit or scale takes ``RegisterValue/number(_:)``, which is divided by the
  /// scale and rounded to the nearest wire integer; any other integer register takes
  /// ``RegisterValue/integer(_:)``. Text is sent with a zero byte after it.
  ///
  /// - Throws: ``VEDirectError/valueTypeMismatch(_:)`` or ``VEDirectError/valueOutOfRange(_:)``.
  public func encode(_ value: RegisterValue) throws(VEDirectError) -> [UInt8] {
    switch (type, value) {
    case (.bytes, .bytes(let bytes)), (.none, .bytes(let bytes)):
      return bytes
    case (.text, .text(let text)):
      return Array(text.utf8) + [0]
    case (.bytes, _), (.none, _), (.text, _):
      throw .valueTypeMismatch(id)
    case (_, .number(let number)):
      guard isScaled else { throw .valueTypeMismatch(id) }
      let scaled = (number / scale).rounded()
      guard scaled.isFinite, let integer = Int64(exactly: scaled) else {
        throw .valueOutOfRange(id)
      }
      return try encodeInteger(integer)
    case (_, .integer(let integer)):
      guard !isScaled else { throw .valueTypeMismatch(id) }
      return try encodeInteger(integer)
    case (_, .text), (_, .bytes):
      throw .valueTypeMismatch(id)
    }
  }

  private func encodeInteger(_ integer: Int64) throws(VEDirectError) -> [UInt8] {
    guard let width = type.integerWidth else { throw .valueTypeMismatch(id) }
    let bits = Int64(8 * width)
    let range: ClosedRange<Int64> =
      type.isSigned ? -(1 << (bits - 1))...(1 << (bits - 1)) - 1 : 0...(1 << bits) - 1
    guard range.contains(integer) else { throw .valueOutOfRange(id) }
    return (0..<width).map { UInt8(truncatingIfNeeded: integer >> Int64(8 * $0)) }
  }
}
