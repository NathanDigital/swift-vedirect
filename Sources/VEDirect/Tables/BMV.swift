/// The HEX registers of the BMV-700 series battery monitors.
///
/// Source: "BMV700 Series Hex Protocol" (Rev 7, 01-07-2021).
///
/// The settings tables of the document give a "Step" and a "Unit" column but no scale. This table
/// uses the step as the scale. That is an inference: the document confirms it only for battery
/// capacity (`0x1000`), whose example reads `0x00C8` as 200 Ah.
///
/// The document says nothing about non-volatile storage. Every writable register of its "Monitor
/// settings registers" chapter is marked persistent here as the library's inference; commands,
/// read-only items and all other registers are not.
///
/// Notes used below: "BMV-702 and BMV-712 only" is the document's note 1, "BMV-712 from v4.01" its
/// note 2, "BMV-70x from v3.09" its note 3.
public enum BMV {
  // MARK: Product information

  /// Product id, without a unit ("Product information registers", `0x0100`).
  ///
  /// Read-only.
  public static let productID = Register(0x0100, "productID", .un32)

  /// Product revision, without a unit ("Product information registers", `0x0101`).
  ///
  /// Read-only. BMV-712 only.
  public static let productRevision = Register(0x0101, "productRevision", .un24)

  /// Serial number as text ("Product information registers", `0x010A`).
  ///
  /// Read-only. At most 32 bytes, zero-ended when shorter.
  public static let serialNumber = Register(0x010A, "serialNumber", .text)

  /// Model name as text ("Product information registers", `0x010B`).
  ///
  /// Read-only. At most 32 bytes, zero-ended when shorter.
  public static let modelName = Register(0x010B, "modelName", .text)

  /// User-set description of the device as text ("Product information registers", `0x010C`).
  ///
  /// Writable. BMV-712 only. At most 20 bytes, zero-ended when shorter.
  public static let deviceDescription = Register(0x010C, "deviceDescription", .text)

  /// Device uptime in seconds ("Product information registers", `0x0120`).
  ///
  /// Read-only.
  public static let deviceUptime = Register(0x0120, "deviceUptime", .un32, unit: .second)

  /// Bluetooth capabilities bit field ("Product information registers", `0x0150`).
  ///
  /// BMV-712 from v4.01. Bit 0: the Bluetooth module supports Bluetooth mode (`0x0090`).
  /// Bit 1: switching Bluetooth off is permanent (not the case for the BMV, which has a
  /// display). Bits 2 to 31 are reserved.
  public static let bluetoothCapabilities = Register(0x0150, "bluetoothCapabilities", .un32)

  // MARK: Monitor

  /// Main battery voltage in volts ("Monitor related registers", `0xED8D`).
  public static let mainVoltage = Register(
    0xED8D, "mainVoltage", .sn16, scale: 0.01, unit: .volt)

  /// Auxiliary (starter) battery voltage in volts ("Monitor related registers", `0xED7D`).
  ///
  /// BMV-702 and BMV-712 only.
  public static let auxiliaryVoltage = Register(
    0xED7D, "auxiliaryVoltage", .sn16, scale: 0.01, unit: .volt)

  /// Battery current in amperes, 0.1 A per bit ("Monitor related registers", `0xED8F`).
  public static let current = Register(0xED8F, "current", .sn16, scale: 0.1, unit: .ampere)

  /// Battery current in amperes, 0.001 A per bit ("Monitor related registers", `0xED8C`).
  ///
  /// BMV-712 from v4.01, BMV-70x from v3.09.
  public static let highResolutionCurrent = Register(
    0xED8C, "highResolutionCurrent", .sn32, scale: 0.001, unit: .ampere)

  /// Power in watts ("Monitor related registers", `0xED8E`).
  public static let power = Register(0xED8E, "power", .sn16, unit: .watt)

  /// Consumed charge in ampere-hours ("Monitor related registers", `0xEEFF`).
  public static let consumedAmpereHours = Register(
    0xEEFF, "consumedAmpereHours", .sn32, scale: 0.1, unit: .ampereHour)

  /// State of charge in percent ("Monitor related registers", `0x0FFF`).
  public static let stateOfCharge = Register(
    0x0FFF, "stateOfCharge", .un16, scale: 0.01, unit: .percent)

  /// Time to go in minutes ("Monitor related registers", `0x0FFE`).
  public static let timeToGo = Register(0x0FFE, "timeToGo", .un16, unit: .minute)

  /// Battery temperature in kelvin ("Monitor related registers", `0xEDEC`).
  ///
  /// BMV-702 and BMV-712 only.
  public static let temperature = Register(
    0xEDEC, "temperature", .un16, scale: 0.01, unit: .kelvin)

  /// Mid-point voltage in volts ("Monitor related registers", `0x0382`).
  ///
  /// BMV-702 and BMV-712 only.
  public static let midPointVoltage = Register(
    0x0382, "midPointVoltage", .un16, scale: 0.01, unit: .volt)

  /// Mid-point voltage deviation in percent ("Monitor related registers", `0x0383`).
  ///
  /// BMV-702 and BMV-712 only.
  public static let midPointVoltageDeviation = Register(
    0x0383, "midPointVoltageDeviation", .sn16, scale: 0.1, unit: .percent)

  /// Synchronisation state, without a unit ("Monitor related registers", `0xEEB6`).
  ///
  /// The document does not list the values.
  public static let synchronisationState = Register(0xEEB6, "synchronisationState", .un8)

  // MARK: History

  /// Depth of the deepest discharge in ampere-hours ("Historic data registers", `0x0300`).
  public static let deepestDischarge = Register(
    0x0300, "deepestDischarge", .sn32, scale: 0.1, unit: .ampereHour)

  /// Depth of the last discharge in ampere-hours ("Historic data registers", `0x0301`).
  public static let lastDischarge = Register(
    0x0301, "lastDischarge", .sn32, scale: 0.1, unit: .ampereHour)

  /// Depth of the average discharge in ampere-hours ("Historic data registers", `0x0302`).
  public static let averageDischarge = Register(
    0x0302, "averageDischarge", .sn32, scale: 0.1, unit: .ampereHour)

  /// Number of charge cycles ("Historic data registers", `0x0303`).
  public static let cycleCount = Register(0x0303, "cycleCount", .un32)

  /// Number of full discharges ("Historic data registers", `0x0304`).
  public static let fullDischargeCount = Register(0x0304, "fullDischargeCount", .un32)

  /// Cumulative charge drawn from the battery in ampere-hours ("Historic data registers",
  /// `0x0305`).
  public static let cumulativeAmpereHours = Register(
    0x0305, "cumulativeAmpereHours", .sn32, scale: 0.1, unit: .ampereHour)

  /// Minimum main battery voltage in volts ("Historic data registers", `0x0306`).
  public static let minimumVoltage = Register(
    0x0306, "minimumVoltage", .sn32, scale: 0.01, unit: .volt)

  /// Maximum main battery voltage in volts ("Historic data registers", `0x0307`).
  public static let maximumVoltage = Register(
    0x0307, "maximumVoltage", .sn32, scale: 0.01, unit: .volt)

  /// Time since the last full charge in seconds ("Historic data registers", `0x0308`).
  public static let timeSinceFullCharge = Register(
    0x0308, "timeSinceFullCharge", .un32, unit: .second)

  /// Number of automatic synchronisations ("Historic data registers", `0x0309`).
  public static let automaticSynchronisationCount = Register(
    0x0309, "automaticSynchronisationCount", .un32)

  /// Number of low voltage alarms ("Historic data registers", `0x030A`).
  public static let lowVoltageAlarmCount = Register(0x030A, "lowVoltageAlarmCount", .un32)

  /// Number of high voltage alarms ("Historic data registers", `0x030B`).
  public static let highVoltageAlarmCount = Register(0x030B, "highVoltageAlarmCount", .un32)

  /// Minimum starter battery voltage in volts ("Historic data registers", `0x030E`).
  ///
  /// BMV-702 and BMV-712 only.
  public static let minimumStarterVoltage = Register(
    0x030E, "minimumStarterVoltage", .sn32, scale: 0.01, unit: .volt)

  /// Maximum starter battery voltage in volts ("Historic data registers", `0x030F`).
  ///
  /// BMV-702 and BMV-712 only.
  public static let maximumStarterVoltage = Register(
    0x030F, "maximumStarterVoltage", .sn32, scale: 0.01, unit: .volt)

  /// Discharged (or produced) energy in kilowatt-hours ("Historic data registers", `0x0310`).
  public static let dischargedEnergy = Register(
    0x0310, "dischargedEnergy", .un32, scale: 0.01, unit: .kilowattHour)

  /// Charged (or consumed) energy in kilowatt-hours ("Historic data registers", `0x0311`).
  public static let chargedEnergy = Register(
    0x0311, "chargedEnergy", .un32, scale: 0.01, unit: .kilowattHour)

  // MARK: Battery settings

  /// Battery capacity in ampere-hours ("Monitor settings registers", `0x1000`).
  ///
  /// Range 1 to 9999, default 200.
  public static let batteryCapacity = Register(
    0x1000, "batteryCapacity", .un16, unit: .ampereHour, isPersistent: true)

  /// Charged voltage in volts ("Monitor settings registers", `0x1001`).
  ///
  /// Range 0 to 95, default 13.2.
  public static let chargedVoltage = Register(
    0x1001, "chargedVoltage", .un16, scale: 0.1, unit: .volt, isPersistent: true)

  /// Tail current in percent ("Monitor settings registers", `0x1002`).
  ///
  /// Range 0.5 to 10, default 4.
  public static let tailCurrent = Register(
    0x1002, "tailCurrent", .un16, scale: 0.1, unit: .percent, isPersistent: true)

  /// Charged detection time in minutes ("Monitor settings registers", `0x1003`).
  ///
  /// Range 1 to 50, default 3.
  public static let chargedDetectionTime = Register(
    0x1003, "chargedDetectionTime", .un16, unit: .minute, isPersistent: true)

  /// Charge efficiency in percent ("Monitor settings registers", `0x1004`).
  ///
  /// Range 50 to 99, default 90.
  public static let chargeEfficiency = Register(
    0x1004, "chargeEfficiency", .un16, unit: .percent, isPersistent: true)

  /// Peukert coefficient, without a unit ("Monitor settings registers", `0x1005`).
  ///
  /// Range 1 to 1.5, default 1.25.
  public static let peukertCoefficient = Register(
    0x1005, "peukertCoefficient", .un16, scale: 0.01, isPersistent: true)

  /// Current threshold in amperes ("Monitor settings registers", `0x1006`).
  ///
  /// Range 0 to 2, default 0.1.
  public static let currentThreshold = Register(
    0x1006, "currentThreshold", .un16, scale: 0.01, unit: .ampere, isPersistent: true)

  /// Time-to-go averaging period ("TTG Delta T") in minutes ("Monitor settings registers",
  /// `0x1007`).
  ///
  /// Range 0 to 12, default 3.
  public static let timeToGoAveragingPeriod = Register(
    0x1007, "timeToGoAveragingPeriod", .un16, unit: .minute, isPersistent: true)

  /// Discharge floor, the state of charge at which the relay closes, in percent ("Monitor
  /// settings registers", `0x1008`).
  ///
  /// Range 0 to 99, default 50.
  public static let dischargeFloor = Register(
    0x1008, "dischargeFloor", .un16, scale: 0.1, unit: .percent, isPersistent: true)

  /// State of charge at which the low state-of-charge relay opens again, in percent ("Monitor
  /// settings registers", `0x1009`).
  ///
  /// Range 0 to 99, default 90.
  public static let relayLowStateOfChargeClear = Register(
    0x1009, "relayLowStateOfChargeClear", .un16, scale: 0.1, unit: .percent, isPersistent: true)

  /// User current zero offset in ADC counts ("Monitor settings registers", `0x1034`).
  ///
  /// Read-only. Range -32768 to 32767, default 0.
  public static let userCurrentZero = Register(0x1034, "userCurrentZero", .sn16)

  // MARK: Alarm settings

  /// Alarm buzzer switch, without a unit ("Monitor settings registers", `0xEEFC`).
  ///
  /// 0 off, 1 on (default).
  public static let alarmBuzzer = Register(0xEEFC, "alarmBuzzer", .un8, isPersistent: true)

  /// Low voltage alarm level in volts ("Monitor settings registers", `0x0320`).
  ///
  /// Range 0 to 95, default 0.
  public static let alarmLowVoltage = Register(
    0x0320, "alarmLowVoltage", .un16, scale: 0.1, unit: .volt, isPersistent: true)

  /// Low voltage alarm clear level in volts ("Monitor settings registers", `0x0321`).
  ///
  /// Range 0 to 95, default 0.
  public static let alarmLowVoltageClear = Register(
    0x0321, "alarmLowVoltageClear", .un16, scale: 0.1, unit: .volt, isPersistent: true)

  /// High voltage alarm level in volts ("Monitor settings registers", `0x0322`).
  ///
  /// Range 0 to 95, default 0.
  public static let alarmHighVoltage = Register(
    0x0322, "alarmHighVoltage", .un16, scale: 0.1, unit: .volt, isPersistent: true)

  /// High voltage alarm clear level in volts ("Monitor settings registers", `0x0323`).
  ///
  /// Range 0 to 95, default 0.
  public static let alarmHighVoltageClear = Register(
    0x0323, "alarmHighVoltageClear", .un16, scale: 0.1, unit: .volt, isPersistent: true)

  /// Low starter voltage alarm level in volts ("Monitor settings registers", `0x0324`).
  ///
  /// BMV-702 and BMV-712 only. Range 0 to 95, default 0.
  public static let alarmLowStarterVoltage = Register(
    0x0324, "alarmLowStarterVoltage", .un16, scale: 0.1, unit: .volt, isPersistent: true)

  /// Low starter voltage alarm clear level in volts ("Monitor settings registers", `0x0325`).
  ///
  /// BMV-702 and BMV-712 only. Range 0 to 95, default 0.
  public static let alarmLowStarterVoltageClear = Register(
    0x0325, "alarmLowStarterVoltageClear", .un16, scale: 0.1, unit: .volt, isPersistent: true)

  /// High starter voltage alarm level in volts ("Monitor settings registers", `0x0326`).
  ///
  /// BMV-702 and BMV-712 only. Range 0 to 95, default 0.
  public static let alarmHighStarterVoltage = Register(
    0x0326, "alarmHighStarterVoltage", .un16, scale: 0.1, unit: .volt, isPersistent: true)

  /// High starter voltage alarm clear level in volts ("Monitor settings registers", `0x0327`).
  ///
  /// BMV-702 and BMV-712 only. Range 0 to 95, default 0.
  public static let alarmHighStarterVoltageClear = Register(
    0x0327, "alarmHighStarterVoltageClear", .un16, scale: 0.1, unit: .volt, isPersistent: true)

  /// Low state-of-charge alarm level in percent ("Monitor settings registers", `0x0328`).
  ///
  /// Range 0 to 99, default 0.
  public static let alarmLowStateOfCharge = Register(
    0x0328, "alarmLowStateOfCharge", .un16, scale: 0.1, unit: .percent, isPersistent: true)

  /// Low state-of-charge alarm clear level in percent ("Monitor settings registers", `0x0329`).
  ///
  /// Range 0 to 99, default 0.
  public static let alarmLowStateOfChargeClear = Register(
    0x0329, "alarmLowStateOfChargeClear", .un16, scale: 0.1, unit: .percent, isPersistent: true)

  /// Low temperature alarm level in kelvin ("Monitor settings registers", `0x032A`).
  ///
  /// BMV-702 and BMV-712 only. 0 means disabled (default); otherwise 174 to 372.
  public static let alarmLowTemperature = Register(
    0x032A, "alarmLowTemperature", .un16, scale: 0.01, unit: .kelvin, isPersistent: true)

  /// Low temperature alarm clear level in kelvin ("Monitor settings registers", `0x032B`).
  ///
  /// BMV-702 and BMV-712 only. 0 means disabled (default); otherwise 174 to 372.
  public static let alarmLowTemperatureClear = Register(
    0x032B, "alarmLowTemperatureClear", .un16, scale: 0.01, unit: .kelvin, isPersistent: true)

  /// High temperature alarm level in kelvin ("Monitor settings registers", `0x032C`).
  ///
  /// BMV-702 and BMV-712 only. 0 means disabled (default); otherwise 174 to 372.
  public static let alarmHighTemperature = Register(
    0x032C, "alarmHighTemperature", .un16, scale: 0.01, unit: .kelvin, isPersistent: true)

  /// High temperature alarm clear level in kelvin ("Monitor settings registers", `0x032D`).
  ///
  /// BMV-702 and BMV-712 only. 0 means disabled (default); otherwise 174 to 372.
  public static let alarmHighTemperatureClear = Register(
    0x032D, "alarmHighTemperatureClear", .un16, scale: 0.01, unit: .kelvin, isPersistent: true)

  /// Mid-point voltage deviation alarm level in percent ("Monitor settings registers",
  /// `0x0331`).
  ///
  /// Range 0 to 99, default 0. The document marks this row with an asterisk that the table
  /// does not explain; mid-point voltage needs a BMV-702 or BMV-712.
  public static let alarmMidVoltage = Register(
    0x0331, "alarmMidVoltage", .un16, scale: 0.1, unit: .percent, isPersistent: true)

  /// Mid-point voltage deviation alarm clear level in percent ("Monitor settings registers",
  /// `0x0332`).
  ///
  /// Range 0 to 99, default 0. Marked with the same unexplained asterisk as `0x0331`.
  public static let alarmMidVoltageClear = Register(
    0x0332, "alarmMidVoltageClear", .un16, scale: 0.1, unit: .percent, isPersistent: true)

  /// Alarm acknowledge command, without a value ("Monitor settings registers", `0x031F`).
  ///
  /// The document gives no type, range or access for this row.
  public static let alarmAcknowledge = Register(0x031F, "alarmAcknowledge", .none)

  // MARK: Relay settings

  /// Relay mode, without a unit ("Monitor settings registers", `0x034F`).
  ///
  /// 0 default (DFLT), 1 charger (CHRG), 2 remote (REM).
  public static let relayMode = Register(0x034F, "relayMode", .un8, isPersistent: true)

  /// Relay inversion switch, without a unit ("Monitor settings registers", `0x034D`).
  ///
  /// 0 off (default), 1 on.
  public static let relayInvert = Register(0x034D, "relayInvert", .un8, isPersistent: true)

  /// Relay state and control, without a unit ("Monitor settings registers", `0x034E`).
  ///
  /// 0 open (default), 1 closed.
  public static let relayState = Register(0x034E, "relayState", .un8, isPersistent: true)

  /// Minimum time the relay stays enabled, in minutes ("Monitor settings registers", `0x100A`).
  ///
  /// Range 0 to 500, default 0.
  public static let relayMinimumEnableTime = Register(
    0x100A, "relayMinimumEnableTime", .un16, unit: .minute, isPersistent: true)

  /// Relay disable delay in minutes ("Monitor settings registers", `0x100B`).
  ///
  /// Range 0 to 500, default 0.
  public static let relayDisableTime = Register(
    0x100B, "relayDisableTime", .un16, unit: .minute, isPersistent: true)

  /// Low voltage relay level in volts ("Monitor settings registers", `0x0350`).
  ///
  /// Range 0 to 95, default 0.
  public static let relayLowVoltage = Register(
    0x0350, "relayLowVoltage", .un16, scale: 0.1, unit: .volt, isPersistent: true)

  /// Low voltage relay clear level in volts ("Monitor settings registers", `0x0351`).
  ///
  /// Range 0 to 95, default 0.
  public static let relayLowVoltageClear = Register(
    0x0351, "relayLowVoltageClear", .un16, scale: 0.1, unit: .volt, isPersistent: true)

  /// High voltage relay level in volts ("Monitor settings registers", `0x0352`).
  ///
  /// Range 0 to 95, default 0.
  public static let relayHighVoltage = Register(
    0x0352, "relayHighVoltage", .un16, scale: 0.1, unit: .volt, isPersistent: true)

  /// High voltage relay clear level in volts ("Monitor settings registers", `0x0353`).
  ///
  /// Range 0 to 95, default 0.
  public static let relayHighVoltageClear = Register(
    0x0353, "relayHighVoltageClear", .un16, scale: 0.1, unit: .volt, isPersistent: true)

  /// Low starter voltage relay level in volts ("Monitor settings registers", `0x0354`).
  ///
  /// BMV-702 and BMV-712 only. Range 0 to 95, default 0.
  public static let relayLowStarterVoltage = Register(
    0x0354, "relayLowStarterVoltage", .un16, scale: 0.1, unit: .volt, isPersistent: true)

  /// Low starter voltage relay clear level in volts ("Monitor settings registers", `0x0355`).
  ///
  /// BMV-702 and BMV-712 only. Range 0 to 95, default 0.
  public static let relayLowStarterVoltageClear = Register(
    0x0355, "relayLowStarterVoltageClear", .un16, scale: 0.1, unit: .volt, isPersistent: true)

  /// High starter voltage relay level in volts ("Monitor settings registers", `0x0356`).
  ///
  /// BMV-702 and BMV-712 only. Range 0 to 95, default 0.
  public static let relayHighStarterVoltage = Register(
    0x0356, "relayHighStarterVoltage", .un16, scale: 0.1, unit: .volt, isPersistent: true)

  /// High starter voltage relay clear level in volts ("Monitor settings registers", `0x0357`).
  ///
  /// BMV-702 and BMV-712 only. Range 0 to 95, default 0.
  public static let relayHighStarterVoltageClear = Register(
    0x0357, "relayHighStarterVoltageClear", .un16, scale: 0.1, unit: .volt, isPersistent: true)

  /// Low temperature relay level in kelvin ("Monitor settings registers", `0x035A`).
  ///
  /// BMV-702 and BMV-712 only. 0 means disabled (default); otherwise 174 to 372.
  public static let relayLowTemperature = Register(
    0x035A, "relayLowTemperature", .un16, scale: 0.01, unit: .kelvin, isPersistent: true)

  /// Low temperature relay clear level in kelvin ("Monitor settings registers", `0x035B`).
  ///
  /// BMV-702 and BMV-712 only. 0 means disabled (default); otherwise 174 to 372.
  public static let relayLowTemperatureClear = Register(
    0x035B, "relayLowTemperatureClear", .un16, scale: 0.01, unit: .kelvin, isPersistent: true)

  /// High temperature relay level in kelvin ("Monitor settings registers", `0x035C`).
  ///
  /// BMV-702 and BMV-712 only. 0 means disabled (default); otherwise 174 to 372.
  public static let relayHighTemperature = Register(
    0x035C, "relayHighTemperature", .un16, scale: 0.01, unit: .kelvin, isPersistent: true)

  /// High temperature relay clear level in kelvin ("Monitor settings registers", `0x035D`).
  ///
  /// BMV-702 and BMV-712 only. 0 means disabled (default); otherwise 174 to 372.
  public static let relayHighTemperatureClear = Register(
    0x035D, "relayHighTemperatureClear", .un16, scale: 0.01, unit: .kelvin, isPersistent: true)

  /// Mid-point voltage deviation relay level in percent ("Monitor settings registers",
  /// `0x0361`).
  ///
  /// BMV-702 and BMV-712 only. Range 0 to 99, default 0.
  public static let relayMidVoltage = Register(
    0x0361, "relayMidVoltage", .un16, scale: 0.1, unit: .percent, isPersistent: true)

  /// Mid-point voltage deviation relay clear level in percent ("Monitor settings registers",
  /// `0x0362`).
  ///
  /// BMV-702 and BMV-712 only. Range 0 to 99, default 0.
  public static let relayMidVoltageClear = Register(
    0x0362, "relayMidVoltageClear", .un16, scale: 0.1, unit: .percent, isPersistent: true)

  // MARK: Display settings

  /// Backlight intensity, without a unit ("Monitor settings registers", `0xEEFE`).
  ///
  /// Range 0 to 9, default 5.
  public static let backlightIntensity = Register(
    0xEEFE, "backlightIntensity", .un8, isPersistent: true)

  /// Backlight always-on switch, without a unit ("Monitor settings registers", `0x0400`).
  ///
  /// 0 off (default), 1 on.
  public static let backlightAlwaysOn = Register(
    0x0400, "backlightAlwaysOn", .un8, isPersistent: true)

  /// Display scroll speed, without a unit ("Monitor settings registers", `0xEEF5`).
  ///
  /// Range 1 to 5, default 3.
  public static let scrollSpeed = Register(0xEEF5, "scrollSpeed", .un8, isPersistent: true)

  /// Whether the display shows the main voltage ("Monitor settings registers", `0xEEE0`).
  ///
  /// 0 off, 1 on (default).
  public static let showVoltage = Register(0xEEE0, "showVoltage", .un8, isPersistent: true)

  /// Whether the display shows the auxiliary voltage ("Monitor settings registers", `0xEEE1`).
  ///
  /// BMV-702 and BMV-712 only. 0 off, 1 on (default).
  public static let showAuxiliaryVoltage = Register(
    0xEEE1, "showAuxiliaryVoltage", .un8, isPersistent: true)

  /// Whether the display shows the mid-point voltage ("Monitor settings registers", `0xEEE2`).
  ///
  /// BMV-702 and BMV-712 only. 0 off, 1 on (default).
  public static let showMidVoltage = Register(
    0xEEE2, "showMidVoltage", .un8, isPersistent: true)

  /// Whether the display shows the current ("Monitor settings registers", `0xEEE3`).
  ///
  /// 0 off, 1 on (default).
  public static let showCurrent = Register(0xEEE3, "showCurrent", .un8, isPersistent: true)

  /// Whether the display shows the consumed ampere-hours ("Monitor settings registers",
  /// `0xEEE4`).
  ///
  /// 0 off, 1 on (default).
  public static let showConsumedAmpereHours = Register(
    0xEEE4, "showConsumedAmpereHours", .un8, isPersistent: true)

  /// Whether the display shows the state of charge ("Monitor settings registers", `0xEEE5`).
  ///
  /// 0 off, 1 on (default).
  public static let showStateOfCharge = Register(
    0xEEE5, "showStateOfCharge", .un8, isPersistent: true)

  /// Whether the display shows the time to go ("Monitor settings registers", `0xEEE6`).
  ///
  /// 0 off, 1 on (default).
  public static let showTimeToGo = Register(0xEEE6, "showTimeToGo", .un8, isPersistent: true)

  /// Whether the display shows the temperature ("Monitor settings registers", `0xEEE7`).
  ///
  /// BMV-702 and BMV-712 only. 0 off, 1 on (default).
  public static let showTemperature = Register(
    0xEEE7, "showTemperature", .un8, isPersistent: true)

  /// Whether the display shows the power ("Monitor settings registers", `0xEEE8`).
  ///
  /// 0 off, 1 on (default).
  public static let showPower = Register(0xEEE8, "showPower", .un8, isPersistent: true)

  // MARK: Commands

  /// Zero current command, without a value ("Monitor settings registers", `0x1029`).
  ///
  /// Write-only.
  public static let zeroCurrent = Register(0x1029, "zeroCurrent", .none)

  /// Synchronise command, without a value ("Monitor settings registers", `0x102C`).
  ///
  /// Write-only.
  public static let synchronise = Register(0x102C, "synchronise", .none)

  /// Restore defaults command, without a value ("Monitor settings registers", `0x0004`).
  ///
  /// Write-only.
  public static let restoreDefaults = Register(0x0004, "restoreDefaults", .none)

  /// Clear history command, without a value ("Monitor settings registers", `0x1030`).
  ///
  /// Write-only.
  public static let clearHistory = Register(0x1030, "clearHistory", .none)

  // MARK: Miscellaneous settings

  /// Software version, without a unit ("Monitor settings registers", `0xEEF9`).
  ///
  /// Read-only. Read in hexadecimal as AA.BB.
  public static let softwareVersion = Register(0xEEF9, "softwareVersion", .un16)

  /// Setup lock switch, without a unit ("Monitor settings registers", `0xEEF6`).
  ///
  /// 0 off (default), 1 on.
  public static let setupLock = Register(0xEEF6, "setupLock", .un8, isPersistent: true)

  /// Rated current of the shunt in amperes ("Monitor settings registers", `0xEEFB`).
  ///
  /// Range 1 to 9999, default 500.
  public static let shuntCurrent = Register(
    0xEEFB, "shuntCurrent", .un16, unit: .ampere, isPersistent: true)

  /// Voltage across the shunt at its rated current, in volts ("Monitor settings registers",
  /// `0xEEFA`).
  ///
  /// Range 0.001 to 0.1, default 0.05.
  public static let shuntVoltage = Register(
    0xEEFA, "shuntVoltage", .un16, scale: 0.001, unit: .volt, isPersistent: true)

  /// Temperature unit of the display, without a unit ("Monitor settings registers", `0xEEF7`).
  ///
  /// BMV-702 and BMV-712 only. 0 Celsius (default), 1 Fahrenheit.
  public static let temperatureUnit = Register(
    0xEEF7, "temperatureUnit", .un8, isPersistent: true)

  /// Temperature coefficient of the battery capacity, in percent of capacity per degree Celsius
  /// ("Monitor settings registers", `0xEEF4`).
  ///
  /// BMV-702 and BMV-712 only. Range 0 to 20, default 0. The unit "%CAP/°C" has no
  /// ``RegisterUnit``.
  public static let temperatureCoefficient = Register(
    0xEEF4, "temperatureCoefficient", .un16, scale: 0.1, isPersistent: true)

  /// Function of the auxiliary input, without a unit ("Monitor settings registers", `0xEEF8`).
  ///
  /// BMV-702 and BMV-712 only. 0 starter battery (default), 1 mid-point, 2 temperature.
  public static let auxiliaryInput = Register(
    0xEEF8, "auxiliaryInput", .un8, isPersistent: true)

  /// Whether the monitor starts synchronised, without a unit ("Monitor settings registers",
  /// `0x0FFD`).
  ///
  /// BMV-712 from v4.01, BMV-70x from v3.09. 0 off, 1 on (default).
  public static let startSynchronised = Register(
    0x0FFD, "startSynchronised", .un8, isPersistent: true)

  /// Time of the last settings change in seconds since 1 January 1970 ("Monitor settings
  /// registers", `0xEC41`).
  ///
  /// BMV-712 from v4.01. 0: changed through the display's settings menu. 1 to `0xFFFFFFFE`:
  /// time of a change made by VictronConnect. `0xFFFFFFFF` (default): no setting was ever
  /// modified.
  public static let settingsChangedTimestamp = Register(
    0xEC41, "settingsChangedTimestamp", .un32, unit: .second, isPersistent: true)

  /// Bluetooth mode, without a unit ("Monitor settings registers", `0x0090`).
  ///
  /// BMV-712 from v4.01. 0 Bluetooth interface disabled, 1 enabled (default); 2 to 7 are
  /// reserved.
  public static let bluetoothMode = Register(0x0090, "bluetoothMode", .un8, isPersistent: true)

  /// DC monitor mode, without a unit ("Monitor settings registers", `0xEEB8`).
  ///
  /// BMV-712 from v4.07. -9 solar charger, -8 wind turbine, -7 shaft generator, -6 alternator,
  /// -5 fuel cell, -4 water generator, -3 DC/DC charger, -2 AC charger, -1 generic source,
  /// 0 battery monitor (default), 1 generic load, 2 electric drive, 3 fridge, 4 water pump,
  /// 5 bilge pump, 6 DC system, 7 inverter, 8 water heater. More may be added: negative for
  /// sources, positive for loads. Current and power are negative while the monitored device
  /// produces energy.
  public static let dcMonitorMode = Register(0xEEB8, "dcMonitorMode", .sn16, isPersistent: true)

  // MARK: Table

  /// Every register of the family, in the order of the document.
  public static let registers: [Register] = [
    productID, productRevision, serialNumber, modelName, deviceDescription, deviceUptime,
    bluetoothCapabilities,
    mainVoltage, auxiliaryVoltage, current, highResolutionCurrent, power, consumedAmpereHours,
    stateOfCharge, timeToGo, temperature, midPointVoltage, midPointVoltageDeviation,
    synchronisationState,
    deepestDischarge, lastDischarge, averageDischarge, cycleCount, fullDischargeCount,
    cumulativeAmpereHours, minimumVoltage, maximumVoltage, timeSinceFullCharge,
    automaticSynchronisationCount, lowVoltageAlarmCount, highVoltageAlarmCount,
    minimumStarterVoltage, maximumStarterVoltage, dischargedEnergy, chargedEnergy,
    batteryCapacity, chargedVoltage, tailCurrent, chargedDetectionTime, chargeEfficiency,
    peukertCoefficient, currentThreshold, timeToGoAveragingPeriod, dischargeFloor,
    relayLowStateOfChargeClear, userCurrentZero,
    alarmBuzzer, alarmLowVoltage, alarmLowVoltageClear, alarmHighVoltage, alarmHighVoltageClear,
    alarmLowStarterVoltage, alarmLowStarterVoltageClear, alarmHighStarterVoltage,
    alarmHighStarterVoltageClear, alarmLowStateOfCharge, alarmLowStateOfChargeClear,
    alarmLowTemperature, alarmLowTemperatureClear, alarmHighTemperature,
    alarmHighTemperatureClear, alarmMidVoltage, alarmMidVoltageClear, alarmAcknowledge,
    relayMode, relayInvert, relayState, relayMinimumEnableTime, relayDisableTime,
    relayLowVoltage, relayLowVoltageClear, relayHighVoltage, relayHighVoltageClear,
    relayLowStarterVoltage, relayLowStarterVoltageClear, relayHighStarterVoltage,
    relayHighStarterVoltageClear, relayLowTemperature, relayLowTemperatureClear,
    relayHighTemperature, relayHighTemperatureClear, relayMidVoltage, relayMidVoltageClear,
    backlightIntensity, backlightAlwaysOn, scrollSpeed, showVoltage, showAuxiliaryVoltage,
    showMidVoltage, showCurrent, showConsumedAmpereHours, showStateOfCharge, showTimeToGo,
    showTemperature, showPower,
    zeroCurrent, synchronise, restoreDefaults, clearHistory,
    softwareVersion, setupLock, shuntCurrent, shuntVoltage, temperatureUnit,
    temperatureCoefficient, auxiliaryInput, startSynchronised, settingsChangedTimestamp,
    bluetoothMode, dcMonitorMode,
  ]
}
