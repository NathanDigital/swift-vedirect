/// The 16-bit id of a Victron product (text label `PID`, HEX command `4`, register `0x0100`).
public struct ProductID: RawRepresentable, Hashable, Sendable {
  /// The id on the wire.
  public let rawValue: UInt16

  /// Creates an id from its wire value; unknown ids are kept as they are.
  public init(rawValue: UInt16) { self.rawValue = rawValue }

  /// Creates an id from the bytes of ``HexResponse/done(_:)`` after a product ID command.
  public init(payload: [UInt8]) throws(VEDirectError) {
    self.rawValue = try LittleEndian.word(payload)
  }

  /// The product this id belongs to, or `nil` when Victron's documents do not list it.
  public var product: Product? {
    Product.all.first { $0.id == self }
  }

  /// The family this id belongs to; ``ProductFamily/unknown`` when it is not listed.
  public var family: ProductFamily {
    product?.family ?? .unknown
  }
}

extension ProductID: ExpressibleByIntegerLiteral {
  /// Creates an id from a literal such as `0xA381`.
  public init(integerLiteral value: UInt16) { self.rawValue = value }
}

/// A group of products that share text fields and a HEX register table.
public struct ProductFamily: RawRepresentable, Hashable, Sendable {
  /// The family's name.
  public let rawValue: String

  /// Creates a family from its name.
  public init(rawValue: String) { self.rawValue = rawValue }

  /// A product id that Victron's documents do not list.
  public static let unknown = ProductFamily(rawValue: "unknown")
  /// BMV-600 series battery monitors; text mode only.
  public static let bmv600 = ProductFamily(rawValue: "BMV-600")
  /// BMV-700 and BMV-710 series battery monitors.
  public static let bmv = ProductFamily(rawValue: "BMV")
  /// SmartShunt battery monitors; Victron publishes no HEX document for them.
  public static let smartShunt = ProductFamily(rawValue: "SmartShunt")
  /// BlueSolar and SmartSolar MPPT solar chargers, VE.Direct, VE.Can and RS models.
  public static let mppt = ProductFamily(rawValue: "MPPT")
  /// Phoenix inverters.
  public static let phoenixInverter = ProductFamily(rawValue: "Phoenix Inverter")
  /// Phoenix Smart IP43 chargers; Victron publishes no HEX document for them.
  public static let phoenixCharger = ProductFamily(rawValue: "Phoenix Charger")
  /// Orion XS DC-DC battery chargers.
  public static let orionXS = ProductFamily(rawValue: "Orion XS")

  /// The family's register definitions, empty when Victron publishes no HEX document for it.
  public var registers: [Register] {
    switch self {
    case .bmv: BMV.registers
    case .mppt: MPPT.registers
    case .phoenixInverter: PhoenixInverter.registers
    case .orionXS: OrionXS.registers
    default: []
    }
  }

  /// The family's definition of a register, or `nil` when the family does not list the id.
  public func register(_ id: RegisterID) -> Register? {
    registers.first { $0.id == id }
  }
}

/// One entry of Victron's product tables.
public struct Product: Sendable, Equatable {
  /// The product's id.
  public let id: ProductID
  /// The model name as Victron prints it.
  public let name: String
  /// The family the product belongs to.
  public let family: ProductFamily

  /// Creates a product entry.
  public init(_ id: ProductID, _ name: String, _ family: ProductFamily) {
    self.id = id
    self.name = name
    self.family = family
  }
}
