/// A firmware version such as 1.16, with its release-candidate or beta marker.
public struct FirmwareVersion: Sendable, Equatable {
  /// The part before the point.
  public let major: UInt8
  /// The part after the point, `0` to `99`.
  public let minor: UInt8
  /// The ASCII letter of a release candidate, or `nil` for any other build.
  public let candidate: UInt8?
  /// The number of a beta build, or `nil` for any other build.
  public let beta: UInt8?

  /// Creates a version from its parts.
  public init(major: UInt8, minor: UInt8, candidate: UInt8? = nil, beta: UInt8? = nil) {
    self.major = major
    self.minor = minor
    self.candidate = candidate
    self.beta = beta
  }

  /// Reads the value of the text field `FW`.
  ///
  /// The value is a whole number, `208` or `0208` for version 2.08, with a leading letter for a
  /// release candidate: `C208` is candidate C of 2.08.
  ///
  /// Source: "VE.Direct Protocol" rev 3.34, "Detailed field description", `FW`.
  init(text bytes: [UInt8]) throws(VEDirectError) {
    var digits = bytes[...]
    var candidate: UInt8?
    if let first = digits.first, (0x41...0x5A).contains(ASCII.uppercased(first)) {
      candidate = ASCII.uppercased(first)
      digits = digits.dropFirst()
    }
    guard
      (1...4).contains(digits.count),
      digits.allSatisfy({ (0x30...0x39).contains($0) }),
      let number = ASCII.integer(Array(digits)),
      let major = UInt8(exactly: number / 100),
      let minor = UInt8(exactly: number % 100)
    else {
      throw .malformedValue(label: "FW")
    }
    self.init(major: major, minor: minor, candidate: candidate)
  }

  /// Reads the value of the text field `FWE`.
  ///
  /// The value is up to six hexadecimal digits: `0208FF` or `208FF` is the release of 2.08 and
  /// `020801` is beta 1 of 2.08.
  ///
  /// Source: "VE.Direct Protocol" rev 3.34, "Detailed field description", `FWE`.
  init(extendedText bytes: [UInt8]) throws(VEDirectError) {
    guard (3...6).contains(bytes.count) else { throw .malformedValue(label: "FWE") }
    var value: UInt32 = 0
    for byte in bytes {
      guard let digit = ASCII.hexValue(byte, allowLowercase: true) else {
        throw .malformedValue(label: "FWE")
      }
      value = value << 4 | UInt32(truncatingIfNeeded: digit)
    }
    self.init(extended: value)
  }

  /// Creates a version from the 24-bit form `0xHHMMLL`.
  ///
  /// `HH` and `MM` are the major and minor version read as decimal digits; `LL` is `0xFF` for a
  /// release and otherwise the beta number. `0x0112FF` is the release of 1.12.
  ///
  /// Source: "VE.Direct Protocol – Orion XS DC-DC battery charger", register `0x0102`.
  public init(extended value: UInt32) {
    let low = UInt8(truncatingIfNeeded: value)
    self.init(
      major: Self.decimal(UInt8(truncatingIfNeeded: value >> 16)),
      minor: Self.decimal(UInt8(truncatingIfNeeded: value >> 8)),
      beta: low == 0xFF ? nil : low
    )
  }

  /// A byte whose two hexadecimal digits are read as decimal digits: `0x16` is 16.
  static func decimal(_ byte: UInt8) -> UInt8 {
    (byte >> 4) &* 10 &+ (byte & 0x0F)
  }
}

/// The kind of firmware a device is running, from a ping reply.
public struct FirmwareType: RawRepresentable, Hashable, Sendable {
  /// The two bits on the wire.
  public let rawValue: UInt8

  /// Creates a type from its wire value.
  public init(rawValue: UInt8) { self.rawValue = rawValue }

  /// The bootloader.
  public static let bootloader = FirmwareType(rawValue: 0)
  /// The application.
  public static let application = FirmwareType(rawValue: 1)
  /// The tester.
  public static let tester = FirmwareType(rawValue: 2)
  /// A release candidate of the application.
  public static let releaseCandidate = FirmwareType(rawValue: 3)
}

/// The 16-bit word of a ping reply, which is also the reply to the application version command.
///
/// The top two bits are the firmware type and the low twelve bits are the version read as
/// decimal digits: `0x4116` is application version 1.16. The Orion XS sends `0xFFF` in the low
/// bits and reports its version in register `0x0102`.
///
/// Source: section "Frame format", response `5`, in the MPPT, BMV, Orion XS and Phoenix Inverter
/// HEX protocol documents.
public struct PingReply: RawRepresentable, Hashable, Sendable {
  /// The word on the wire.
  public let rawValue: UInt16

  /// Creates a reply from its wire word.
  public init(rawValue: UInt16) { self.rawValue = rawValue }

  /// Creates a reply from the bytes of ``HexResponse/done(_:)`` after an application version
  /// command.
  public init(payload: [UInt8]) throws(VEDirectError) {
    self.rawValue = try LittleEndian.word(payload)
  }

  /// The kind of firmware running.
  public var firmwareType: FirmwareType {
    FirmwareType(rawValue: UInt8(truncatingIfNeeded: rawValue >> 14))
  }

  /// The firmware version, or `nil` when the device does not report one here.
  ///
  /// For a release candidate the letter is the top hexadecimal digit of the word: `0xD101` is
  /// candidate D of 1.01.
  public var version: FirmwareVersion? {
    guard rawValue & 0x0FFF != 0x0FFF else { return nil }
    let isCandidate = firmwareType == .releaseCandidate
    return FirmwareVersion(
      major: UInt8(truncatingIfNeeded: rawValue >> 8) & 0x0F,
      minor: FirmwareVersion.decimal(UInt8(truncatingIfNeeded: rawValue)),
      candidate: isCandidate ? ASCII.hexDigit(UInt8(truncatingIfNeeded: rawValue >> 12)) : nil
    )
  }
}
