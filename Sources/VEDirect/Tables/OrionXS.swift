/// The HEX registers of the Orion XS DC-DC battery charger.
///
/// Source: "VE.Direct Protocol – Orion XS DC-DC battery charger" (changelog 16-06-2025).
///
/// The document warns that the "Battery settings registers" are stored in non-volatile memory
/// and that continuous writing, for example from a control loop, leads to early failure. Marking
/// the engine shutdown, input voltage lockout, device function and BLE mode settings persistent
/// as well, and the two live measurements in the battery settings table (`0xEDEF`, `0xEDEC`)
/// not, is the library's inference.
public enum OrionXS {
  // MARK: Product information

  /// Product id, without a unit ("Product information registers", `0x0100`).
  ///
  /// The 4-byte response is byte 0 instance (`0x00`), bytes 1 and 2 the product id, byte 3
  /// reserved (`0xFF`). The document advises the product id command instead: a 2-byte response
  /// to this register has the wrong byte order on some builds and should be ignored.
  public static let productID = Register(0x0100, "productID", .un32)

  /// Firmware version, without a unit ("Product information registers", `0x0102`).
  ///
  /// Byte 0 is an identifier, currently `0x00`. Bytes 1 to 3 are a un24 version `0xHHMMLL`,
  /// read as vHH.MM; LL of `0xFF` means a release. The ping and application version commands
  /// give no version on this product.
  public static let firmwareVersion = Register(0x0102, "firmwareVersion", .un32)

  /// Group id, without a unit ("Product information registers", `0x0104`).
  public static let groupID = Register(0x0104, "groupID", .un8)

  /// Serial number as text ("Product information registers", `0x010A`).
  public static let serialNumber = Register(0x010A, "serialNumber", .text)

  /// Model name as text ("Product information registers", `0x010B`).
  public static let modelName = Register(0x010B, "modelName", .text)

  /// Capabilities bit field ("Product information registers", `0x0140`).
  ///
  /// Each bit is 1 when the feature is present. 0 load output, 1 rotary encoder, 2 history,
  /// 3 batterysafe mode, 4 adaptive mode, 5 manual equalise, 6 automatic equalise, 7 storage
  /// mode, 8 remote on/off via the RX pin, 9 solar timer/streetlighting, 10 alternative
  /// VE.Direct TX pin function, 11 user defined load switch, 12 load current in the text
  /// protocol, 13 panel current, 14 BMS support, 15 external control support, 16 synchronised
  /// charging support, 17 alarm relay, 18 alternative VE.Direct RX pin function, 19 virtual
  /// load output, 20 virtual relay, 21 plugin display support, 25 load automatic energy
  /// selector, 26 battery test, 27 PAYGO support, 28 hibernate mode, 29 AC apparent power,
  /// 30 PSU function, 31 needs battery to shut down.
  public static let capabilities = Register(0x0140, "capabilities", .un32)

  // MARK: Generic device control

  /// Device mode, without a unit ("Generic device control registers", `0x0200`).
  ///
  /// 0 or 4 charger off, 1 or 3 charger on.
  public static let deviceMode = Register(0x0200, "deviceMode", .un8)

  /// Device state, without a unit ("Generic device control registers", `0x0201`).
  ///
  /// 0 not charging, 2 fault, 3 bulk, 4 absorption, 5 float, 6 storage, 7 manual equalise,
  /// 11 power supply (PSU), 245 wake-up, 246 repeated absorption, 247 auto equalise,
  /// 248 battery safe, 250 blocked (unit being updated), 252 external control,
  /// 255 unavailable.
  public static let deviceState = Register(0x0201, "deviceState", .un8)

  /// Device off reason bit field ("Generic device control registers", `0x0207`).
  ///
  /// Bit 0 no input power, 2 soft power switch, 3 remote input, 4 internal reason,
  /// 5 pay-as-you-go out of credit, 6 BMS shutdown, 7 engine shutdown detection, 8 error.
  /// Bits 1 and 9 are not applicable.
  public static let deviceOffReason = Register(0x0207, "deviceOffReason", .un32)

  // MARK: Battery settings

  /// Batterysafe mode switch, without a unit ("Battery settings registers", `0xEDFF`).
  ///
  /// 0 off, 1 on.
  public static let batterySafeMode = Register(
    0xEDFF, "batterySafeMode", .un8, isPersistent: true)

  /// Adaptive mode switch, without a unit ("Battery settings registers", `0xEDFE`).
  ///
  /// 0 off, 1 on.
  public static let adaptiveMode = Register(0xEDFE, "adaptiveMode", .un8, isPersistent: true)

  /// Automatic equalisation mode, without a unit ("Battery settings registers", `0xEDFD`).
  ///
  /// 0 off, otherwise 1 to 250; the document does not say what the number counts.
  public static let automaticEqualisationMode = Register(
    0xEDFD, "automaticEqualisationMode", .un8, isPersistent: true)

  /// Battery bulk time limit in hours ("Battery settings registers", `0xEDFC`).
  public static let bulkTimeLimit = Register(
    0xEDFC, "bulkTimeLimit", .un16, scale: 0.01, unit: .hour, isPersistent: true)

  /// Battery absorption time limit in hours ("Battery settings registers", `0xEDFB`).
  public static let absorptionTimeLimit = Register(
    0xEDFB, "absorptionTimeLimit", .un16, scale: 0.01, unit: .hour, isPersistent: true)

  /// Battery absorption voltage in volts ("Battery settings registers", `0xEDF7`).
  public static let absorptionVoltage = Register(
    0xEDF7, "absorptionVoltage", .un16, scale: 0.01, unit: .volt, isPersistent: true)

  /// Battery float voltage in volts ("Battery settings registers", `0xEDF6`).
  public static let floatVoltage = Register(
    0xEDF6, "floatVoltage", .un16, scale: 0.01, unit: .volt, isPersistent: true)

  /// Battery equalisation voltage in volts ("Battery settings registers", `0xEDF4`).
  public static let equalisationVoltage = Register(
    0xEDF4, "equalisationVoltage", .un16, scale: 0.01, unit: .volt, isPersistent: true)

  /// Battery temperature compensation in millivolts per kelvin ("Battery settings registers",
  /// `0xEDF2`).
  public static let temperatureCompensation = Register(
    0xEDF2, "temperatureCompensation", .sn16, scale: 0.01, unit: .millivoltPerKelvin,
    isPersistent: true)

  /// Battery type, without a unit ("Battery settings registers", `0xEDF1`).
  ///
  /// 1 default (LiFePO4), 255 user defined.
  public static let batteryType = Register(0xEDF1, "batteryType", .un8, isPersistent: true)

  /// Battery maximum current in amperes ("Battery settings registers", `0xEDF0`).
  public static let batteryMaximumCurrent = Register(
    0xEDF0, "batteryMaximumCurrent", .un16, scale: 0.1, unit: .ampere, isPersistent: true)

  /// Battery voltage of the system in volts ("Battery settings registers", `0xEDEF`).
  ///
  /// 12, 24 or 48. Treated as a read-out, not a setting; the setting is `0xEDEA`.
  public static let batteryVoltage = Register(0xEDEF, "batteryVoltage", .un8, unit: .volt)

  /// Battery temperature in kelvin ("Battery settings registers" and "Charger data registers",
  /// `0xEDEC`).
  ///
  /// `0xFFFF` means not available; the charger data table notes that it will be `0xFFFF`.
  public static let batteryTemperature = Register(
    0xEDEC, "batteryTemperature", .un16, scale: 0.01, unit: .kelvin, notAvailable: 0xFFFF)

  /// Battery voltage setting in volts ("Battery settings registers", `0xEDEA`).
  ///
  /// 12, 24 or 48.
  public static let batteryVoltageSetting = Register(
    0xEDEA, "batteryVoltageSetting", .un8, unit: .volt, isPersistent: true)

  /// BMS present flag, without a unit ("Battery settings registers", `0xEDE8`).
  ///
  /// 0 no, 1 yes. While set, the charger does not operate stand-alone: without data from a BMS
  /// it stops charging and shows error 67. The charger sets and stores this flag itself when
  /// the BMS controlled bit of `0x200E` is used.
  public static let bmsPresent = Register(0xEDE8, "bmsPresent", .un8, isPersistent: true)

  /// Tail current, 0.1 per bit ("Battery settings registers", `0xEDE7`).
  ///
  /// The document gives the scale but no unit, so none is set here.
  public static let tailCurrent = Register(
    0xEDE7, "tailCurrent", .un16, scale: 0.1, isPersistent: true)

  /// Low temperature charge current in amperes ("Battery settings registers", `0xEDE6`).
  ///
  /// The wire value `0xFFFF` means use the maximum current.
  public static let lowTemperatureChargeCurrent = Register(
    0xEDE6, "lowTemperatureChargeCurrent", .un16, scale: 0.1, unit: .ampere, isPersistent: true)

  /// Whether automatic equalisation stops on voltage, without a unit ("Battery settings
  /// registers", `0xEDE5`).
  ///
  /// 0 no, 1 yes.
  public static let autoEqualiseStopOnVoltage = Register(
    0xEDE5, "autoEqualiseStopOnVoltage", .un8, isPersistent: true)

  /// Equalisation current level in percent of the battery maximum current `0xEDF0` ("Battery
  /// settings registers", `0xEDE4`).
  public static let equalisationCurrentLevel = Register(
    0xEDE4, "equalisationCurrentLevel", .un8, unit: .percent, isPersistent: true)

  /// Equalisation duration in hours ("Battery settings registers", `0xEDE3`).
  public static let equalisationDuration = Register(
    0xEDE3, "equalisationDuration", .un16, scale: 0.01, unit: .hour, isPersistent: true)

  /// Re-bulk voltage offset in volts ("Battery settings registers", `0xED2E`).
  public static let reBulkVoltageOffset = Register(
    0xED2E, "reBulkVoltageOffset", .un16, scale: 0.01, unit: .volt, isPersistent: true)

  /// Battery low temperature level in degrees Celsius ("Battery settings registers", `0xEDE0`).
  ///
  /// The document prints the id as "xEDE0".
  public static let batteryLowTemperatureLevel = Register(
    0xEDE0, "batteryLowTemperatureLevel", .sn16, scale: 0.01, unit: .celsius, isPersistent: true)

  /// Voltage compensation in volts ("Battery settings registers", `0xEDCA`).
  public static let voltageCompensation = Register(
    0xEDCA, "voltageCompensation", .un16, scale: 0.01, unit: .volt, isPersistent: true)

  // MARK: Engine shutdown settings

  /// Engine shutdown voltage in volts ("Engine shutdown settings", `0xEE36`).
  public static let engineShutdownVoltage = Register(
    0xEE36, "engineShutdownVoltage", .un16, scale: 0.01, unit: .volt, isPersistent: true)

  /// Engine start voltage in volts ("Engine shutdown settings", `0xEE37`).
  public static let engineStartVoltage = Register(
    0xEE37, "engineStartVoltage", .un16, scale: 0.01, unit: .volt, isPersistent: true)

  /// Engine delayed start voltage in volts ("Engine shutdown settings", `0xEE38`).
  public static let engineDelayedStartVoltage = Register(
    0xEE38, "engineDelayedStartVoltage", .un16, scale: 0.01, unit: .volt, isPersistent: true)

  /// Engine start delay in seconds ("Engine shutdown settings", `0xEE39`).
  public static let engineStartDelay = Register(
    0xEE39, "engineStartDelay", .un32, unit: .second, isPersistent: true)

  // MARK: Input voltage lockout settings

  /// Input voltage lockout level in volts ("Input voltage lockout settings", `0x0320`).
  ///
  /// The document gives a scale of 0.1 for this register.
  public static let inputVoltageLockout = Register(
    0x0320, "inputVoltageLockout", .un16, scale: 0.1, unit: .volt, isPersistent: true)

  /// Input voltage restart level in volts ("Input voltage lockout settings", `0x0321`).
  ///
  /// The document gives a scale of 0.1 for this register.
  public static let inputVoltageRestart = Register(
    0x0321, "inputVoltageRestart", .un16, scale: 0.1, unit: .volt, isPersistent: true)

  /// Device function, without a unit ("Device function (register 0x0206)", `0x0206`).
  ///
  /// 0 charger, 1 power supply (PSU). The document lists only the values; the un8 type and
  /// the persistent marking are the library's inference.
  public static let deviceFunction = Register(
    0x0206, "deviceFunction", .un8, isPersistent: true)

  // MARK: Charger data

  /// Input voltage in volts ("Charger data registers", `0xEDBB`).
  public static let inputVoltage = Register(
    0xEDBB, "inputVoltage", .un16, scale: 0.01, unit: .volt)

  /// Input current in amperes ("Charger data registers", `0xEDBD`).
  public static let inputCurrent = Register(
    0xEDBD, "inputCurrent", .un16, scale: 0.1, unit: .ampere)

  /// Input power in watts ("Charger data registers", `0xEDBC`).
  public static let inputPower = Register(0xEDBC, "inputPower", .un32, scale: 0.01, unit: .watt)

  /// Output voltage in volts ("Charger data registers", `0xED8D`).
  public static let outputVoltage = Register(
    0xED8D, "outputVoltage", .un16, scale: 0.01, unit: .volt)

  /// Output current in amperes ("Charger data registers", `0xED8F`).
  public static let outputCurrent = Register(
    0xED8F, "outputCurrent", .un16, scale: 0.1, unit: .ampere)

  /// Output power in watts ("Charger data registers", `0xED8E`).
  public static let outputPower = Register(
    0xED8E, "outputPower", .un32, scale: 0.01, unit: .watt)

  /// Battery voltage from a Victron smart battery sense in volts ("Charger data registers",
  /// `0xD18D`).
  ///
  /// `0x7FFFFFFF` when no smart battery sense is in use, decoded as not available.
  public static let sensedBatteryVoltage = Register(
    0xD18D, "sensedBatteryVoltage", .sn32, scale: 0.001, unit: .volt, notAvailable: 0x7FFF_FFFF)

  /// Charger temperature in degrees Celsius ("Charger data registers", `0xEDDB`).
  public static let chargerTemperature = Register(
    0xEDDB, "chargerTemperature", .sn16, scale: 0.01, unit: .celsius)

  /// Estimated battery temperature in kelvin ("Charger data registers", `0xEE12`).
  ///
  /// The document notes that this will be the charger temperature.
  public static let estimatedBatteryTemperature = Register(
    0xEE12, "estimatedBatteryTemperature", .un16, scale: 0.01, unit: .kelvin)

  /// Charger error or warning code, without a unit ("Charger error code and warning values
  /// (register 0xEDDA)", `0xEDDA`).
  ///
  /// Errors: 0 no error, 1 battery temperature too high, 2 battery voltage too high,
  /// 17 charger temperature too high, 21 current sense failure, 26 charger terminal
  /// temperature too high, 28 converter issue, 33 input voltage too high, 116 calibration data
  /// lost, 117 invalid firmware, 119 settings lost, 120 reference voltage failure.
  /// Warnings: 67 BMS connection lost, 150 battery temperature too high, 151 battery
  /// temperature too low, 160 charger overtemperature (derating), 161 short circuit detected,
  /// 162 converter issue.
  /// The document lists only the values; the un8 type follows the error field of the cycle
  /// history record.
  public static let chargerError = Register(0xEDDA, "chargerError", .un8)

  // MARK: Restore factory defaults

  /// Restore defaults command, without a value ("Restore factory defaults", `0x0004`).
  ///
  /// A write restores every setting except the factory calibration data to its factory
  /// default. The data part of the message is ignored.
  public static let restoreDefaults = Register(0x0004, "restoreDefaults", .none)

  // MARK: History

  /// Clear history command, without a value ("History data", `0x1030`).
  public static let clearHistory = Register(0x1030, "clearHistory", .none)

  /// Number of cycle history entries ("History data", `0x106F`).
  public static let cycleCount = Register(0x106F, "cycleCount", .un8)

  /// Start time of the current charge cycle in seconds ("History data", `0x1099`).
  ///
  /// The document names the register "Cycle sequence number".
  public static let cycleSequenceNumber = Register(
    0x1099, "cycleSequenceNumber", .un32, unit: .second)

  /// Cumulative user history record ("History data", `0x1043`).
  ///
  /// Little-endian fields by byte offset: 0 version (un8); 1 operation time (un32, 1 s);
  /// 5 charged (un32, 0.1 Ah); 9 charge cycles started (un32); 13 charge cycles completed
  /// (un32); 17 number of power-ups (un32); 21 number of deep discharges (un32).
  public static let cumulativeUserHistory = Register(0x1043, "cumulativeUserHistory", .bytes)

  /// Cumulative service history record ("History data", `0x1042`).
  ///
  /// The layout is that of the cumulative user history, `0x1043`.
  public static let cumulativeServiceHistory = Register(
    0x1042, "cumulativeServiceHistory", .bytes)

  /// The number of cycle history registers, `0x1070` to `0x1098`.
  public static let cycleHistoryCount = 41

  /// Returns the cycle history record of one charge cycle ("History data", `0x1070` to
  /// `0x1098`).
  ///
  /// Little-endian fields by byte offset: 0 version (un8); 1 start time (un32, 1 s); 5 time in
  /// bulk, 9 absorption, 13 re-condition/equalisation, 17 float, 21 storage (un32, 1 s each);
  /// 25 Ah in bulk, 29 absorption, 33 re-condition/equalisation, 37 float, 41 storage (un32,
  /// 0.1 Ah each); 45 voltage at the start, 47 at the end (un16, 0.01 V each); 49 battery type
  /// (un8, see `0xEDF1`); 50 error (un8, see `0xEDDA`).
  /// A field that is not available holds `0xFFFFFFFF`, `0xFFFF` or `0xFF` by its width. A
  /// register without data yet answers with an empty record and flags `0x04`.
  ///
  /// - Parameter index: 0 for the newest cycle (`0x1070`) up to 40 for the oldest (`0x1098`).
  /// - Returns: The register, or `nil` when `index` is outside 0 to 40.
  public static func cycleHistory(_ index: Int) -> Register? {
    guard (0..<cycleHistoryCount).contains(index),
      let id = UInt16(exactly: 0x1070 + index)
    else { return nil }
    return Register(RegisterID(rawValue: id), "cycleHistory\(index)", .bytes)
  }

  // MARK: Remote control

  /// Charge algorithm version, without a unit ("Remote control registers", `0x2000`).
  public static let chargeAlgorithmVersion = Register(0x2000, "chargeAlgorithmVersion", .un8)

  /// Charge voltage set-point in volts ("Remote control registers", `0x2001`).
  ///
  /// Can be read from the master unit and written to slave units so that a group behaves as
  /// one unit; see `0x200E`.
  public static let chargeVoltageSetPoint = Register(
    0x2001, "chargeVoltageSetPoint", .un16, scale: 0.01, unit: .volt)

  /// Battery voltage from a remote sensor in volts ("Remote control registers", `0x2002`).
  ///
  /// Written to the charger, which then adapts its charging voltage by up to ±2 V. It must be
  /// rewritten within 60 seconds and lie within ±5 V of the voltage on the charger terminals.
  /// The wire value `0xFFFF` says that the data is no longer available.
  public static let batteryVoltageSense = Register(
    0x2002, "batteryVoltageSense", .un16, scale: 0.01, unit: .volt, notAvailable: 0xFFFF)

  /// Battery temperature from a remote sensor in degrees Celsius ("Remote control registers",
  /// `0x2003`).
  ///
  /// Written to the charger and rewritten within 60 seconds. The wire value `0x7FFF` says that
  /// the data is no longer available.
  public static let batteryTemperatureSense = Register(
    0x2003, "batteryTemperatureSense", .sn16, scale: 0.01, unit: .celsius, notAvailable: 0x7FFF)

  /// Battery charge current in amperes ("Remote control registers", `0x200A`).
  public static let batteryChargeCurrent = Register(
    0x200A, "batteryChargeCurrent", .sn32, scale: 0.001, unit: .ampere)

  /// Link device state, without a unit ("Remote control registers", `0x200C`).
  ///
  /// 0 not charging, 2 fault, 3 bulk, 4 absorption, 5 float, 6 storage, 7 manual equalise,
  /// 11 power supply, 245 wake-up, 246 repeated absorption, 247 auto equalise, 248 battery
  /// safe, 249 load detect, 252 external control, 255 unavailable. States 6, 11, 246, 248, 249
  /// and 252 are only possible in slave mode, with the set-point sent by the master.
  public static let linkDeviceState = Register(0x200C, "linkDeviceState", .un8)

  /// Network info bit field ("Remote control registers", `0x200D`).
  ///
  /// Bit 0 controlled by a BMS, 1 voltage set-point controlled remotely, 2 charge slave,
  /// 3 charge master, 4 using ICHARGE (battery current estimate), 5 using ISENSE (actual
  /// battery current), 6 using TSENSE, 7 using VSENSE, 8 held in standby while the network
  /// initialises. The document lists bit 8 although it gives the type as un8.
  public static let networkInfo = Register(0x200D, "networkInfo", .un8)

  /// Network mode bit field ("Remote control registers", `0x200E`).
  ///
  /// Bit 0 networked (only a visual indication of remote control), 1 slave mode (remote
  /// control of voltage and current set-points and charge state), 2 external control mode
  /// (remote control of voltage and current set-points), 3 BMS controlled, 4 charge group
  /// master (not used), 5 charge instance master, 6 standby, 7 reserved.
  /// Zero is stand-alone operation with the internal charge profile. External control is
  /// bits 0 and 2, with `0x2001` and/or `0x2015` written as well; the charger falls back to
  /// stand-alone after 1 minute without data.
  /// Bit 3 makes the charger enable the BMS present setting `0xEDE8` and store it to flash,
  /// after which it stops with error 67 whenever the data stops.
  public static let networkMode = Register(0x200E, "networkMode", .un8)

  /// Network status, without a unit ("Remote control registers", `0x200F`).
  ///
  /// Low nibble: 0 slave mode, 1 group master, 2 instance master, 3 group and instance
  /// master, 4 stand-alone. Bit 4 using ICHARGE, 5 using ISENSE, 6 using TSENSE, 7 using
  /// VSENSE. Kept per interface.
  public static let networkStatus = Register(0x200F, "networkStatus", .un8)

  /// Total charge current, the estimated battery current ("Total charge current (register
  /// 0x2013)", `0x2013`).
  ///
  /// Used to check the tail current condition. The document describes the register but gives
  /// no type, scale or unit, so the value is left as bytes.
  public static let totalChargeCurrent = Register(0x2013, "totalChargeCurrent", .bytes)

  /// Charge current limit in amperes ("Remote control registers", `0x2015`).
  ///
  /// Written more than once a minute together with `0x200E`. The charger uses the lower of
  /// this limit and the battery maximum current `0xEDF0`.
  public static let chargeCurrentLimit = Register(
    0x2015, "chargeCurrentLimit", .un16, scale: 0.1, unit: .ampere)

  // MARK: BLE settings

  /// BLE capabilities bit field ("BLE settings", `0x0150`).
  ///
  /// Each bit is 1 for yes. 0 supports BLE mode, 1 BLE mode off is permanent, 2 supports BLE
  /// off recovery time, 3 recovery time zero off is permanent, 4 supports service mode,
  /// 5 supports trends, 6 supports advertisement key, 7 supports state-of-charge
  /// synchronisation via trend, 8 supports settings lock. Bits 9 to 31 are not defined.
  public static let bleCapabilities = Register(0x0150, "bleCapabilities", .un32)

  /// BLE mode, without a unit ("BLE settings", `0x0090`).
  ///
  /// 0 BLE disabled, 1 BLE enabled.
  public static let bleMode = Register(0x0090, "bleMode", .un8, isPersistent: true)

  // MARK: Table

  /// Every register of the family, in the order of the document.
  public static let registers: [Register] =
    [
      productID, firmwareVersion, groupID, serialNumber, modelName, capabilities,
      deviceMode, deviceState, deviceOffReason,
      batterySafeMode, adaptiveMode, automaticEqualisationMode, bulkTimeLimit,
      absorptionTimeLimit, absorptionVoltage, floatVoltage, equalisationVoltage,
      temperatureCompensation, batteryType, batteryMaximumCurrent, batteryVoltage,
      batteryTemperature, batteryVoltageSetting, bmsPresent, tailCurrent,
      lowTemperatureChargeCurrent, autoEqualiseStopOnVoltage, equalisationCurrentLevel,
      equalisationDuration, reBulkVoltageOffset, batteryLowTemperatureLevel,
      voltageCompensation,
      engineShutdownVoltage, engineStartVoltage, engineDelayedStartVoltage, engineStartDelay,
      inputVoltageLockout, inputVoltageRestart, deviceFunction,
      inputVoltage, inputCurrent, inputPower, outputVoltage, outputCurrent, outputPower,
      sensedBatteryVoltage, chargerTemperature, estimatedBatteryTemperature, chargerError,
      restoreDefaults,
      clearHistory, cycleCount, cycleSequenceNumber, cumulativeUserHistory,
      cumulativeServiceHistory,
    ] + (0..<cycleHistoryCount).compactMap { cycleHistory($0) } + [
      chargeAlgorithmVersion, chargeVoltageSetPoint, batteryVoltageSense,
      batteryTemperatureSense, batteryChargeCurrent, linkDeviceState, networkInfo, networkMode,
      networkStatus, totalChargeCurrent, chargeCurrentLimit,
      bleCapabilities, bleMode,
    ]
}
