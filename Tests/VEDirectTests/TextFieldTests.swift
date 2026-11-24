import Testing
import VEDirect

@Suite("VE.Direct Protocol 3.34: text fields")
struct TextFieldTests {
  @Test("FAQ question 8: the BMV-700 example block reads as typed values")
  func faqExampleValues() throws {
    let block = textBlock(faqBlockFields)
    #expect(try block.productID == 0x203)
    #expect(try #require(try block.mainVoltage).isApproximately(26.201))
    #expect(try block.current == 0)
    #expect(try block.power == 0)
    #expect(try block.consumedCharge == 0)
    #expect(try #require(try block.stateOfCharge).isApproximately(100))
    #expect(try block.timeToGo == .infinity)
    #expect(try block.isAlarmActive == false)
    #expect(try block.isRelayOn == false)
    #expect(try block.alarmReason == [])
    #expect(block.modelDescription == "700")
    #expect(try block.firmwareVersion == FirmwareVersion(major: 3, minor: 7))
  }

  @Test("A field the block does not hold reads as nil and an unknown label is kept")
  func missingAndUnknown() throws {
    let block = textBlock([(label: "NEWFIELD", value: "abc")])
    #expect(try block.mainVoltage == nil)
    #expect(block.serialNumber == nil)
    #expect(block["NEWFIELD"]?.value == "abc")
    #expect(block["newfield"]?.label == "NEWFIELD")
    #expect(block.fields.count == 1)
  }

  @Test("--- means not available and reads as nil")
  func notAvailable() throws {
    let block = textBlock([
      (label: "T", value: "---"), (label: "CE", value: "---"), (label: "SOC", value: "---"),
      (label: "TTG", value: "---"), (label: "H1", value: "---"), (label: "H4", value: "---"),
    ])
    #expect(try block.batteryTemperature == nil)
    #expect(try block.consumedCharge == nil)
    #expect(try block.stateOfCharge == nil)
    #expect(try block.timeToGo == nil)
    #expect(try block.deepestDischarge == nil)
    #expect(try block.chargeCycleCount == nil)
    #expect(block["T"]?.isNotAvailable == true)
  }

  @Test("Wire units are converted: mV, mA, mAh, per mille, minutes and 0.01 kWh")
  func units() throws {
    let block = textBlock([
      (label: "V", value: "12530"), (label: "I", value: "-1500"), (label: "CE", value: "-25400"),
      (label: "SOC", value: "876"), (label: "TTG", value: "90"), (label: "DM", value: "-12"),
      (label: "H19", value: "8272"), (label: "H9", value: "3600"), (label: "T", value: "-5"),
      (label: "AC_OUT_V", value: "23005"), (label: "AC_OUT_I", value: "12"),
      (label: "DC_IN_V", value: "1402"), (label: "DC_IN_I", value: "253"),
      (label: "DC_IN_P", value: "355"), (label: "PPV", value: "130"),
    ])
    #expect(try #require(try block.mainVoltage).isApproximately(12.53))
    #expect(try #require(try block.current).isApproximately(-1.5))
    #expect(try #require(try block.consumedCharge).isApproximately(-25.4))
    #expect(try #require(try block.stateOfCharge).isApproximately(87.6))
    #expect(try block.timeToGo == 5400)
    #expect(try #require(try block.midpointDeviation).isApproximately(-1.2))
    #expect(try #require(try block.totalYield).isApproximately(82.72))
    #expect(try block.timeSinceFullCharge == 3600)
    #expect(try block.batteryTemperature == -5)
    #expect(try #require(try block.acOutputVoltage).isApproximately(230.05))
    #expect(try #require(try block.acOutputCurrent).isApproximately(1.2))
    #expect(try #require(try block.dcInputVoltage).isApproximately(14.02))
    #expect(try #require(try block.dcInputCurrent).isApproximately(25.3))
    #expect(try block.dcInputPower == 355)
    #expect(try block.panelPower == 130)
  }

  @Test("ON and OFF are compared without regard to case", arguments: ["ON", "On", "on"])
  func onValues(value: String) throws {
    let block = textBlock([
      (label: "Alarm", value: value), (label: "Relay", value: value), (label: "LOAD", value: value),
    ])
    #expect(try block.isAlarmActive == true)
    #expect(try block.isRelayOn == true)
    #expect(try block.isLoadOutputOn == true)
  }

  @Test("OFF reads as false in any case", arguments: ["OFF", "Off", "off"])
  func offValues(value: String) throws {
    #expect(try textBlock([(label: "Relay", value: value)]).isRelayOn == false)
  }

  @Test("Enumerations and bit fields keep their wire values, known or not")
  func enumerations() throws {
    let block = textBlock([
      (label: "CS", value: "252"), (label: "ERR", value: "67"), (label: "MODE", value: "253"),
      (label: "MPPT", value: "2"), (label: "MON", value: "-9"), (label: "AR", value: "5"),
      (label: "WARN", value: "256"), (label: "OR", value: "0x00000081"),
      (label: "CAP_BLE", value: "0x00000003"), (label: "HSDS", value: "274"),
    ])
    #expect(try block.operationState == .externalControl)
    #expect(try block.chargerError == .bmsConnectionLost)
    #expect(try block.deviceMode == .hibernate)
    #expect(try block.trackerMode == .tracking)
    #expect(try block.monitorMode == .solarCharger)
    // "the value 5 means low SOC and low voltage"
    #expect(try block.alarmReason == [.lowStateOfCharge, .lowVoltage])
    #expect(try block.warningReason == .overload)
    #expect(try block.offReason == [.noInputPower, .engineShutdownDetection])
    #expect(try block.bluetoothCapabilities == [.supportsSwitchingOff, .switchingOffIsPermanent])
    #expect(try block.daySequenceNumber == 274)

    let unknown = textBlock([(label: "CS", value: "200"), (label: "ERR", value: "99")])
    #expect(try unknown.operationState == OperationState(rawValue: 200))
    #expect(try unknown.chargerError?.rawValue == 99)
  }

  @Test("The product id is read as a number whatever its width", arguments: ["0x300", "0x0300"])
  func productIDWidth(value: String) throws {
    #expect(try textBlock([(label: "PID", value: value)]).productID == 0x0300)
  }

  @Test("FW: 208 and 0208 are version 2.08 and C208 is release candidate C")
  func firmwareVersions() throws {
    func version(_ value: String) throws -> FirmwareVersion? {
      try textBlock([(label: "FW", value: value)]).firmwareVersion
    }
    #expect(try version("208") == FirmwareVersion(major: 2, minor: 8))
    #expect(try version("0208") == FirmwareVersion(major: 2, minor: 8))
    #expect(try version("139") == FirmwareVersion(major: 1, minor: 39))
    #expect(
      try version("C208") == FirmwareVersion(major: 2, minor: 8, candidate: UInt8(ascii: "C")))
    #expect(throws: VEDirectError.malformedValue(label: "FW")) { try version("") }
    #expect(throws: VEDirectError.malformedValue(label: "FW")) { try version("12345") }
    #expect(throws: VEDirectError.malformedValue(label: "FW")) { try version("2.08") }
  }

  @Test("FWE: 0208FF and 208FF are the release of 2.08 and 020801 is beta 1")
  func extendedFirmwareVersions() throws {
    func version(_ value: String) throws -> FirmwareVersion? {
      try textBlock([(label: "FWE", value: value)]).extendedFirmwareVersion
    }
    #expect(try version("0208FF") == FirmwareVersion(major: 2, minor: 8))
    #expect(try version("208FF") == FirmwareVersion(major: 2, minor: 8))
    #expect(try version("020801") == FirmwareVersion(major: 2, minor: 8, beta: 1))
    #expect(throws: VEDirectError.malformedValue(label: "FWE")) { try version("02") }
    #expect(throws: VEDirectError.malformedValue(label: "FWE")) { try version("0208FF0") }
    #expect(throws: VEDirectError.malformedValue(label: "FWE")) { try version("02Z8FF") }
  }

  @Test("A value that cannot be read throws and is never nil")
  func malformedValues() {
    let block = textBlock([
      (label: "V", value: "12.5"), (label: "I", value: ""), (label: "Relay", value: "MAYBE"),
      (label: "CS", value: "300"), (label: "AR", value: "-1"), (label: "PID", value: "0x"),
      (label: "H4", value: "99999999999999999999"), (label: "MON", value: "40000"),
    ])
    #expect(throws: VEDirectError.malformedValue(label: "V")) { try block.mainVoltage }
    #expect(throws: VEDirectError.malformedValue(label: "I")) { try block.current }
    #expect(throws: VEDirectError.malformedValue(label: "Relay")) { try block.isRelayOn }
    #expect(throws: VEDirectError.malformedValue(label: "CS")) { try block.operationState }
    #expect(throws: VEDirectError.malformedValue(label: "AR")) { try block.alarmReason }
    #expect(throws: VEDirectError.malformedValue(label: "PID")) { try block.productID }
    #expect(throws: VEDirectError.malformedValue(label: "H4")) { try block.chargeCycleCount }
    #expect(throws: VEDirectError.malformedValue(label: "MON")) { try block.monitorMode }
  }
}

extension Double {
  /// Whether two values differ by less than a millionth, for comparing scaled readings.
  func isApproximately(_ other: Double) -> Bool {
    abs(self - other) < 1e-6
  }
}
