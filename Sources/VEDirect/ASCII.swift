/// ASCII helpers for the two wire formats; the library does not import Foundation.
enum ASCII {
  static let tab: UInt8 = 0x09
  static let lineFeed: UInt8 = 0x0A
  static let carriageReturn: UInt8 = 0x0D
  static let colon: UInt8 = 0x3A

  /// The value of a hexadecimal digit, or `nil` for any other byte.
  static func hexValue(_ byte: UInt8, allowLowercase: Bool) -> UInt8? {
    switch byte {
    case 0x30...0x39: byte &- 0x30
    case 0x41...0x46: byte &- 0x41 &+ 10
    case 0x61...0x66: allowLowercase ? byte &- 0x61 &+ 10 : nil
    default: nil
    }
  }

  /// The uppercase hexadecimal digit for the low four bits of `value`.
  static func hexDigit(_ value: UInt8) -> UInt8 {
    let nibble = value & 0x0F
    return nibble < 10 ? 0x30 &+ nibble : 0x41 &+ (nibble &- 10)
  }

  /// `byte` with an ASCII lowercase letter folded to uppercase.
  static func uppercased(_ byte: UInt8) -> UInt8 {
    (0x61...0x7A).contains(byte) ? byte &- 0x20 : byte
  }

  /// Whether two byte strings are equal when ASCII letter case is ignored.
  static func equalIgnoringCase(_ lhs: some Collection<UInt8>, _ rhs: some Collection<UInt8>)
    -> Bool
  {
    guard lhs.count == rhs.count else { return false }
    return zip(lhs, rhs).allSatisfy { uppercased($0) == uppercased($1) }
  }

  /// Parses a whole byte string as an integer.
  ///
  /// The string is an optional sign, then either decimal digits or `0x` and hexadecimal digits.
  /// Returns `nil` when the string is empty, holds any other byte or overflows.
  static func integer(_ bytes: [UInt8]) -> Int64? {
    var digits = bytes[...]
    var negative = false
    if let first = digits.first, first == 0x2D || first == 0x2B {
      negative = first == 0x2D
      digits = digits.dropFirst()
    }
    var radix: Int64 = 10
    if digits.count > 2, digits.first == 0x30, uppercased(digits.dropFirst().first ?? 0) == 0x58 {
      radix = 16
      digits = digits.dropFirst(2)
    }
    guard !digits.isEmpty else { return nil }
    var result: Int64 = 0
    for byte in digits {
      guard let digit = hexValue(byte, allowLowercase: true) else { return nil }
      let value = Int64(truncatingIfNeeded: digit)
      guard value < radix else { return nil }
      let (product, productOverflow) = result.multipliedReportingOverflow(by: radix)
      let (sum, sumOverflow) = product.addingReportingOverflow(value)
      guard !productOverflow, !sumOverflow else { return nil }
      result = sum
    }
    return negative ? 0 &- result : result
  }
}
