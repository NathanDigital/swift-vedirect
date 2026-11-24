/// One label and value from a text block, exactly as received.
public struct TextField: Sendable, Equatable {
  /// The label's bytes, for example `V` or `SER#`.
  public let labelBytes: [UInt8]
  /// The value's bytes, without the tab before it or the line break after it.
  public let valueBytes: [UInt8]

  /// Creates a field from its raw bytes.
  public init(labelBytes: [UInt8], valueBytes: [UInt8]) {
    self.labelBytes = labelBytes
    self.valueBytes = valueBytes
  }

  /// The label as a string; any byte that is not valid UTF-8 becomes U+FFFD.
  public var label: String { String(decoding: labelBytes, as: UTF8.self) }

  /// The value as a string; any byte that is not valid UTF-8 becomes U+FFFD.
  public var value: String { String(decoding: valueBytes, as: UTF8.self) }

  /// Whether the value is `---`, which a device sends when it has no reading.
  public var isNotAvailable: Bool { valueBytes == [0x2D, 0x2D, 0x2D] }
}

/// The fields of one text block whose checksum was valid.
///
/// A device may spread its fields over several blocks, so a missing field is normal and reads as
/// `nil`. Fields with labels the library does not know are kept in ``fields``.
///
/// Source: "VE.Direct Protocol" rev 3.34, sections "Message format" and "Data integrity".
public struct TextBlock: Sendable, Equatable {
  /// Every field in the order received, without the `Checksum` field.
  public let fields: [TextField]

  /// Creates a block from its fields.
  public init(fields: [TextField]) {
    self.fields = fields
  }

  /// The first field with the given label, compared without regard to ASCII letter case.
  public subscript(label: String) -> TextField? {
    fields.first { ASCII.equalIgnoringCase($0.labelBytes, label.utf8) }
  }

  // MARK: Typed reading

  /// The integer value of a field, or `nil` when the field is absent or `---`.
  func integer(_ label: String) throws(VEDirectError) -> Int64? {
    guard let field = self[label], !field.isNotAvailable else { return nil }
    guard let value = ASCII.integer(field.valueBytes) else {
      throw .malformedValue(label: label)
    }
    return value
  }

  /// The value of a field multiplied by `scale`, or `nil` when the field is absent or `---`.
  func scaled(_ label: String, by scale: Double) throws(VEDirectError) -> Double? {
    guard let value = try integer(label) else { return nil }
    return Double(value) * scale
  }

  /// The whole-number value of a field, or `nil` when the field is absent or `---`.
  func count(_ label: String) throws(VEDirectError) -> Int? {
    guard let value = try integer(label) else { return nil }
    guard let count = Int(exactly: value) else { throw .malformedValue(label: label) }
    return count
  }

  /// The value of a field as an integer of the given type, which it must fit exactly.
  func exactInteger<T: FixedWidthInteger>(_ label: String, as type: T.Type) throws(VEDirectError)
    -> T?
  {
    guard let value = try integer(label) else { return nil }
    guard let exact = T(exactly: value) else { throw .malformedValue(label: label) }
    return exact
  }

  /// The value of an `ON` or `OFF` field, compared without regard to letter case.
  func flag(_ label: String) throws(VEDirectError) -> Bool? {
    guard let field = self[label], !field.isNotAvailable else { return nil }
    if ASCII.equalIgnoringCase(field.valueBytes, "ON".utf8) { return true }
    if ASCII.equalIgnoringCase(field.valueBytes, "OFF".utf8) { return false }
    throw .malformedValue(label: label)
  }

  /// The value of a field as text, or `nil` when the field is absent.
  func text(_ label: String) -> String? {
    self[label]?.value
  }
}
