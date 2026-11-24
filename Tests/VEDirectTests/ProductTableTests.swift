import Testing
import VEDirect

/// The product table against the `PID` table of "VE.Direct Protocol" rev 3.34 and the product
/// tables of the HEX protocol documents.
@Suite("VE.Direct Protocol 3.34: product ids")
struct VEDirectProtocol334ProductTableTests {
  @Test("Ids are unique and sorted")
  func idsAreUniqueAndSorted() {
    let ids = Product.all.map(\.id.rawValue)
    #expect(Set(ids).count == ids.count)
    #expect(ids == ids.sorted())
  }

  @Test("The table holds every id of the text and HEX documents")
  func entryCount() {
    // 153 ids in the text document and 21 more that only the HEX documents list.
    #expect(Product.all.count == 174)
  }

  @Test(
    "Each family has the documented number of products",
    arguments: [
      (ProductFamily.bmv600, 3),
      (ProductFamily.bmv, 6),
      (ProductFamily.smartShunt, 3),
      (ProductFamily.mppt, 89),
      (ProductFamily.phoenixInverter, 63),
      (ProductFamily.phoenixCharger, 8),
      (ProductFamily.orionXS, 2),
      (ProductFamily.unknown, 0),
    ])
  func countPerFamily(family: ProductFamily, count: Int) {
    #expect(Product.all.count { $0.family == family } == count)
  }

  @Test("No name is empty or keeps the `|` separator or a phased-out mark")
  func namesAreNormalised() {
    for product in Product.all {
      #expect(!product.name.isEmpty)
      #expect(!product.name.contains("|"))
      #expect(!product.name.contains("*"))
    }
  }

  @Test(
    "The first supported devices are listed",
    arguments: [
      (UInt16(0xA381), "BMV-712 Smart", ProductFamily.bmv),
      (UInt16(0xA383), "BMV-712 Smart Rev2", ProductFamily.bmv),
      (UInt16(0xA057), "SmartSolar MPPT 100/50", ProductFamily.mppt),
      (UInt16(0xA3F0), "Orion XS 12V/12V-50A", ProductFamily.orionXS),
    ])
  func supportedDevice(rawValue: UInt16, name: String, family: ProductFamily) throws {
    let id = ProductID(rawValue: rawValue)
    let product = try #require(id.product)
    #expect(product.id == id)
    #expect(product.name == name)
    #expect(product.family == family)
    #expect(id.family == family)
  }

  @Test(
    "Ids that only a HEX document lists are present",
    arguments: [
      (UInt16(0x0200), "BMV600S", ProductFamily.bmv600),
      (UInt16(0xA048), "BlueSolar MPPT 75/50 rev2", ProductFamily.mppt),
      (UInt16(0xA110), "SmartSolar MPPT RS 450/100", ProductFamily.mppt),
      (UInt16(0xA2B1), "Phoenix Inverter Smart 12V 5000VA 230Vac", ProductFamily.phoenixInverter),
      (UInt16(0xA2FC), "Phoenix Inverter 48V 1200VA 120Vac", ProductFamily.phoenixInverter),
    ])
  func hexOnlyProduct(rawValue: UInt16, name: String, family: ProductFamily) throws {
    let product = try #require(ProductID(rawValue: rawValue).product)
    #expect(product.name == name)
    #expect(product.family == family)
  }

  @Test("An unlisted id has no product and the unknown family")
  func unlistedID() {
    let id = ProductID(rawValue: 0x1234)
    #expect(id.product == nil)
    #expect(id.family == .unknown)
    #expect(id.rawValue == 0x1234)
  }

  @Test("A product ID payload is little-endian")
  func payloadIsLittleEndian() throws {
    let id = try ProductID(payload: [0x81, 0xA3])
    #expect(id == ProductID(rawValue: 0xA381))
    #expect(id.product?.name == "BMV-712 Smart")
  }

  @Test("A one-byte product ID payload is truncated")
  func shortPayloadThrows() {
    #expect(throws: VEDirectError.truncatedPayload) {
      try ProductID(payload: [0x81])
    }
  }
}
