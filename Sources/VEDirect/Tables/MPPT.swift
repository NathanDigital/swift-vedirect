/// The HEX registers of BlueSolar and SmartSolar MPPT solar chargers.
///
/// Source: "VE.Direct Protocol – BlueSolar and SmartSolar MPPT chargers", Rev 18.
///
/// The document marks only the "Battery settings registers" as stored in non-volatile memory.
/// Marking the settings of the load output, relay, lighting controller, VE.Direct port, display
/// and 2-wire BMS input groups as persistent is this library's inference, made so that none of
/// them is written from a control loop by mistake.
public enum MPPT {
  // MARK: Product information

  /// Product id, no unit ("Product information registers", `0x0100`).
  ///
  /// Two bytes since firmware 1.12, four bytes since 1.30. The 2-byte form has the wrong byte
  /// order on some builds and should be ignored; the document recommends HEX command 4 instead.
  /// 4-byte form: byte 0 instance (`0x00`), bytes 1 and 2 product id, byte 3 reserved (`0xFF`).
  public static let productID = Register(0x0100, "productID", .un32)

  /// Group id used for synchronised charging, no unit ("Product information registers",
  /// `0x0104`).
  ///
  /// Available since firmware 1.17.
  public static let groupID = Register(0x0104, "groupID", .un8)

  /// Serial number as text ("Product information registers", `0x010A`).
  ///
  /// Available since firmware 1.12.
  public static let serialNumber = Register(0x010A, "serialNumber", .text)

  /// Model name as text ("Product information registers", `0x010B`).
  ///
  /// Available since firmware 1.12.
  public static let modelName = Register(0x010B, "modelName", .text)

  /// Capabilities bit field, no unit ("Product information registers" and "Capabilities
  /// (register 0x0140)", `0x0140`).
  ///
  /// Available since firmware 1.16. A set bit means the feature is present.
  /// Bit 0 load output, 1 rotary encoder, 2 history, 3 batterysafe mode, 4 adaptive mode,
  /// 5 manual equalise, 6 automatic equalise, 7 storage mode, 8 remote on/off via RX pin,
  /// 9 solar timer or street lighting, 10 alternative VE.Direct TX pin function,
  /// 11 user defined load switch, 12 load current in the text protocol, 13 panel current,
  /// 14 BMS support, 15 external control support, 16 synchronised charging support,
  /// 17 alarm relay, 18 alternative VE.Direct RX pin function, 19 virtual load output,
  /// 20 virtual relay, 21 plug-in display support, 25 load automatic energy selector,
  /// 26 battery test, 27 PAYGO support.
  public static let capabilities = Register(0x0140, "capabilities", .un32)

  // MARK: Generic device control

  /// Device mode enumeration, no unit ("Generic device control registers" and "Device mode
  /// values (register 0x0200)", `0x0200`).
  ///
  /// 0 or 4 charger off, 1 charger on. Firmware 1.16 and lower reports off as 0 and reports
  /// whether the unit is actually charging; 1.17 and higher reports off as 4 and reports the
  /// soft on/off switch. Both 0 and 4 are accepted as an off command. The charger obeys on/off
  /// commands only when bit 1 of `0x0202` is set.
  public static let deviceMode = Register(0x0200, "deviceMode", .un8)

  /// Device state enumeration, no unit ("Generic device control registers" and "Device state
  /// values (register 0x0201)", `0x0201`).
  ///
  /// 0 not charging, 2 fault, 3 bulk, 4 absorption, 5 float, 6 storage, 7 manual equalise,
  /// 245 wake-up, 247 auto equalise, 250 blocked (unit being updated), 252 external control,
  /// 255 unavailable. Batterysafe mode reports as 3 (until firmware 1.13). Automatic
  /// equalisation reports as 4 up to firmware 1.39 and as 247 from 1.42; see `0xEDD4`.
  public static let deviceState = Register(0x0201, "deviceState", .un8)

  /// Remote control used bit mask, no unit ("Generic device control registers" and "Remote
  /// control used bit-mask (register 0x0202)", `0x0202`).
  ///
  /// Bit 1 enables remote on/off control through `0x0200`; all other bits are reserved. Bits
  /// can only be set, and are cleared when the unit restarts. Before firmware 1.42 the value
  /// `0x00000002` must be written once after power-up; from 1.42 bit 1 is set by default.
  public static let remoteControlUsed = Register(0x0202, "remoteControlUsed", .un32)

  /// Device off reason bit mask in its 8-bit form, no unit ("Generic device control registers"
  /// and "Device off reason bit-mask (registers 0x0205,0x0207)", `0x0205`).
  ///
  /// Firmware 1.29 up to 1.43, SmartSolar models only. Bits as for `0x0207`.
  public static let deviceOffReasonShort = Register(0x0205, "deviceOffReasonShort", .un8)

  /// Device off reason bit mask, no unit ("Generic device control registers" and "Device off
  /// reason bit-mask (registers 0x0205,0x0207)", `0x0207`).
  ///
  /// Firmware 1.44, SmartSolar and MPPT RS models only.
  /// Bit 0 no input power (solar panels), 1 physical power switch (MPPT RS only), 2 soft power
  /// switch (device mode or pluggable display), 3 remote input, 4 internal reason,
  /// 5 pay-as-you-go out of credit, 6 BMS shutdown, 7 and 8 reserved, 9 battery temperature too
  /// low (charging not allowed).
  public static let deviceOffReason = Register(0x0207, "deviceOffReason", .un32)

  // MARK: Battery settings

  /// Batterysafe mode, no unit: 0 off, 1 on ("Battery settings registers", `0xEDFF`).
  ///
  /// Permanently disabled since firmware 1.13 and removed in 1.42.
  public static let batterySafeMode = Register(
    0xEDFF, "batterySafeMode", .un8, isPersistent: true)

  /// Adaptive mode, no unit: 0 off, 1 on ("Battery settings registers", `0xEDFE`).
  ///
  /// Introduced in firmware 1.42.
  public static let adaptiveMode = Register(0xEDFE, "adaptiveMode", .un8, isPersistent: true)

  /// Automatic equalisation mode, no unit ("Battery settings registers", `0xEDFD`).
  ///
  /// 0 off, 1 every day, 2 every other day, and so on up to 250. Introduced in firmware 1.16.
  public static let automaticEqualisationMode = Register(
    0xEDFD, "automaticEqualisationMode", .un8, isPersistent: true)

  /// Battery bulk time limit in hours ("Battery settings registers", `0xEDFC`).
  ///
  /// Removed in firmware 1.42.
  public static let bulkTimeLimit = Register(
    0xEDFC, "bulkTimeLimit", .un16, scale: 0.01, unit: .hour, isPersistent: true)

  /// Battery absorption time limit in hours ("Battery settings registers", `0xEDFB`).
  public static let absorptionTimeLimit = Register(
    0xEDFB, "absorptionTimeLimit", .un16, scale: 0.01, unit: .hour, isPersistent: true)

  /// Battery absorption voltage in volts ("Battery settings registers", `0xEDF7`).
  ///
  /// Writable only when the battery type `0xEDF1` is user defined (`0xFF`). For a 12 V system
  /// voltage settings must lie between 8 V and 17.4 V, otherwise the charger raises error 119.
  public static let absorptionVoltage = Register(
    0xEDF7, "absorptionVoltage", .un16, scale: 0.01, unit: .volt, isPersistent: true)

  /// Battery float voltage in volts ("Battery settings registers", `0xEDF6`).
  ///
  /// Writable only when the battery type `0xEDF1` is user defined; limits as for `0xEDF7`.
  public static let floatVoltage = Register(
    0xEDF6, "floatVoltage", .un16, scale: 0.01, unit: .volt, isPersistent: true)

  /// Battery equalisation voltage in volts ("Battery settings registers", `0xEDF4`).
  ///
  /// Introduced in firmware 1.16. Writable only when the battery type `0xEDF1` is user defined;
  /// limits as for `0xEDF7`.
  public static let equalisationVoltage = Register(
    0xEDF4, "equalisationVoltage", .un16, scale: 0.01, unit: .volt, isPersistent: true)

  /// Battery temperature compensation in millivolts per kelvin ("Battery settings registers",
  /// `0xEDF2`).
  ///
  /// Writable only when the battery type `0xEDF1` is user defined. For a 12 V system the value
  /// must lie between -21 mV and +21 mV, otherwise the charger raises error 119.
  public static let temperatureCompensation = Register(
    0xEDF2, "temperatureCompensation", .sn16, scale: 0.01, unit: .millivoltPerKelvin,
    isPersistent: true)

  /// Battery type enumeration, no unit ("Battery settings registers" and "Battery type values
  /// (register 0xEDF1)", `0xEDF1`).
  ///
  /// Chargers without a rotary switch (10 A, 15 A, 20 A): 1 gel Victron deep discharge,
  /// 255 user defined.
  /// Chargers with a rotary switch, as the document's table prints them: 1 gel Victron long
  /// life (14.1 V), 2 gel Victron deep discharge (14.3 V), 2 gel Victron deep discharge
  /// (14.4 V), 3 AGM Victron deep discharge (14.7 V), 5 tubular plate cyclic mode 1 (14.9 V),
  /// 6 tubular plate cyclic mode 2 (15.1 V), 7 tubular plate cyclic mode 3 (15.3 V),
  /// 8 LiFePO4 (14.2 V), 255 user defined. The table names these TYPE_1 to TYPE_8, so the
  /// values 2 and 3 printed for TYPE_3 and TYPE_4 are probably misprints of 3 and 4. On these
  /// models only 255 can be written; any other value reverts to the rotary switch setting.
  /// MPPT RS: 1 gel Victron deep discharge (57.6 V), 2 AGM Victron deep discharge (58.8 V),
  /// 3 LiFePO4 (56.8 V) with 2-wire BMS, 255 user defined.
  public static let batteryType = Register(0xEDF1, "batteryType", .un8, isPersistent: true)

  /// Battery maximum current in amperes ("Battery settings registers", `0xEDF0`).
  public static let batteryMaximumCurrent = Register(
    0xEDF0, "batteryMaximumCurrent", .un16, scale: 0.1, unit: .ampere, isPersistent: true)

  /// Battery system voltage in volts ("Battery settings registers" and "Battery voltage setting
  /// values (register 0xEDEF and 0xEDEA)", `0xEDEF`).
  ///
  /// A read always returns the operational voltage: 12, 24, 36 or 48. A write of one of those
  /// fixes the voltage and disables automatic detection; a write of 0 selects automatic
  /// detection at start-up. 36 V is never detected automatically. Read-only on fixed voltage
  /// models.
  public static let batteryVoltage = Register(
    0xEDEF, "batteryVoltage", .un8, unit: .volt, isPersistent: true)

  /// Battery temperature in kelvin ("Battery settings registers" and "Charger data registers",
  /// `0xEDEC`).
  ///
  /// A measurement, although the document also lists it with the battery settings. Introduced
  /// in firmware 1.30; from 1.42 it shows the temperature received from a BMV or Smart Battery
  /// Sense over VE.Smart networking. `0xFFFF` means not available.
  public static let batteryTemperature = Register(
    0xEDEC, "batteryTemperature", .un16, scale: 0.01, unit: .kelvin, notAvailable: 0xFFFF)

  /// Battery system voltage setting in volts ("Battery settings registers" and "Battery voltage
  /// setting values (register 0xEDEF and 0xEDEA)", `0xEDEA`).
  ///
  /// 0 automatic detection at start-up, otherwise 12, 24, 36 or 48. Added in firmware 1.12;
  /// writable from 1.17, with the same effect as writing `0xEDEF`. Read-only on fixed voltage
  /// models.
  public static let batteryVoltageSetting = Register(
    0xEDEA, "batteryVoltageSetting", .un8, unit: .volt, isPersistent: true)

  /// BMS present, no unit: 0 no, 1 yes ("Battery settings registers", `0xEDE8`).
  ///
  /// Introduced in firmware 1.17. The charger sets it to 1 itself when it detects a BMS, and
  /// then no longer operates stand-alone: without BMS data it stops charging with error 67.
  /// Writing 0 returns the unit to stand-alone operation.
  public static let bmsPresent = Register(0xEDE8, "bmsPresent", .un8, isPersistent: true)

  /// Tail current, with no unit ("Battery settings registers", `0xEDE7`).
  ///
  /// The document gives a scale of 0.1 and leaves the unit column empty. Introduced in firmware
  /// 1.42.
  public static let tailCurrent = Register(
    0xEDE7, "tailCurrent", .un16, scale: 0.1, isPersistent: true)

  /// Low temperature charge current in amperes ("Battery settings registers", `0xEDE6`).
  ///
  /// `0xFFFF` means use the maximum current. Introduced in firmware 1.30.
  public static let lowTemperatureChargeCurrent = Register(
    0xEDE6, "lowTemperatureChargeCurrent", .un16, scale: 0.1, unit: .ampere, isPersistent: true)

  /// Automatic equalisation stop on voltage, no unit: 0 no, 1 yes ("Battery settings
  /// registers", `0xEDE5`).
  ///
  /// Introduced in firmware 1.42.
  public static let automaticEqualisationStopOnVoltage = Register(
    0xEDE5, "automaticEqualisationStopOnVoltage", .un8, isPersistent: true)

  /// Equalisation current level in percent of `0xEDF0` ("Battery settings registers",
  /// `0xEDE4`).
  ///
  /// Introduced in firmware 1.42.
  public static let equalisationCurrentLevel = Register(
    0xEDE4, "equalisationCurrentLevel", .un8, unit: .percent, isPersistent: true)

  /// Equalisation duration in hours ("Battery settings registers", `0xEDE3`).
  ///
  /// Introduced in firmware 1.42.
  public static let equalisationDuration = Register(
    0xEDE3, "equalisationDuration", .un16, scale: 0.01, unit: .hour, isPersistent: true)

  /// Re-bulk voltage offset in volts ("Battery settings registers", `0xED2E`).
  ///
  /// Introduced in firmware 1.42.
  public static let rebulkVoltageOffset = Register(
    0xED2E, "rebulkVoltageOffset", .un16, scale: 0.01, unit: .volt, isPersistent: true)

  /// Battery low temperature level in degrees Celsius ("Battery settings registers",
  /// `0xEDE0`).
  ///
  /// Introduced in firmware 1.30.
  public static let batteryLowTemperatureLevel = Register(
    0xEDE0, "batteryLowTemperatureLevel", .sn16, scale: 0.01, unit: .celsius,
    isPersistent: true)

  /// Voltage compensation in volts ("Battery settings registers", `0xEDCA`).
  ///
  /// Introduced in firmware 1.42.
  public static let voltageCompensation = Register(
    0xEDCA, "voltageCompensation", .un16, scale: 0.01, unit: .volt, isPersistent: true)

  // MARK: 2-wire BMS input (MPPT RS models only)

  /// Remote input mode configuration, no unit ("2-wire BMS input - MPPT RS models only",
  /// `0xD0C0`).
  ///
  /// 0 remote on/off, 1 2-wire BMS signals. Selects the function of the REMOTE_L and REMOTE_H
  /// pins. Writable only when the battery type `0xEDF1` is user defined.
  public static let remoteInputMode = Register(
    0xD0C0, "remoteInputMode", .un8, isPersistent: true)

  /// 2-wire BMS input states bit field, no unit ("2-wire BMS input - MPPT RS models only",
  /// `0xD01F`).
  ///
  /// Bit 0 2-wire BMS input enabled, 1 allow to discharge active, 2 allow to charge active.
  public static let twoWireBMSInputStates = Register(0xD01F, "twoWireBMSInputStates", .un8)

  // MARK: Charger data

  /// Charger maximum current in amperes ("Charger data registers", `0xEDDF`).
  ///
  /// Available in firmware 1.16 and higher.
  public static let chargerMaximumCurrent = Register(
    0xEDDF, "chargerMaximumCurrent", .un16, scale: 0.1, unit: .ampere)

  /// System yield in kilowatt-hours ("Charger data registers", `0xEDDD`).
  ///
  /// History data is not available on the BlueSolar MPPT 70|15 (product id `0x0300`).
  public static let systemYield = Register(
    0xEDDD, "systemYield", .un32, scale: 0.01, unit: .kilowattHour)

  /// User yield, resettable, in kilowatt-hours ("Charger data registers", `0xEDDC`).
  ///
  /// History data is not available on the BlueSolar MPPT 70|15 (product id `0x0300`).
  public static let userYield = Register(
    0xEDDC, "userYield", .un32, scale: 0.01, unit: .kilowattHour)

  /// Charger internal temperature in degrees Celsius ("Charger data registers", `0xEDDB`).
  public static let chargerInternalTemperature = Register(
    0xEDDB, "chargerInternalTemperature", .sn16, scale: 0.01, unit: .celsius)

  /// Charger error code enumeration, no unit ("Charger data registers" and "Charger error code
  /// values (register 0xEDDA)", `0xEDDA`).
  ///
  /// 0 no error, 2 battery voltage too high, 3 to 5 battery temperature sensor issue, 6 to 8
  /// battery voltage sensor issue, 14 battery temperature too low (charging not allowed),
  /// 17 charger internal temperature too high, 18 charger excessive output current, 19 charger
  /// current polarity reversed, 20 charger bulk time expired, 21 charger current sensor issue,
  /// 22 and 23 charger internal temperature sensor issue, 26 charger terminals overheated,
  /// 27 charger short-circuit, 28 converter issue, 29 battery over-charge protection, 33 input
  /// voltage too high, 34 input excessive current, 38 input shutdown (excessive battery
  /// voltage), 39 input shutdown (current flowing while the converter is switched off),
  /// 66 incompatible device in the network, 67 BMS connection lost, 68 network misconfigured,
  /// 116 calibration data lost, 117 incompatible firmware, 119 settings data invalid or
  /// corrupted.
  /// Error 19 is disabled since firmware 1.15. Error 21 can be ignored for 5 minutes around
  /// start-up and shutdown before firmware 1.16. Errors 26 and 38 were added in 1.16 and error
  /// 34 was removed in 1.29.
  public static let chargerErrorCode = Register(0xEDDA, "chargerErrorCode", .un8)

  /// Charger current in amperes ("Charger data registers", `0xEDD7`).
  ///
  /// The sum of the current to the battery and to the load output; subtract the load current
  /// `0xEDAD` to get the battery current.
  public static let chargerCurrent = Register(
    0xEDD7, "chargerCurrent", .un16, scale: 0.1, unit: .ampere)

  /// Charger voltage in volts, measured across the charger's battery terminals ("Charger data
  /// registers", `0xEDD5`).
  public static let chargerVoltage = Register(
    0xEDD5, "chargerVoltage", .un16, scale: 0.01, unit: .volt)

  /// Additional charger state info bit mask, no unit ("Charger data registers" and "Additional
  /// charger state info bit-mask (register 0xEDD4)", `0xEDD4`).
  ///
  /// Bit 0 safe mode active, 1 automatic equalisation active, 4 temperature dimming active,
  /// 6 input current dimming active. Bits 0 and 1 are no longer used since firmware 1.42, which
  /// reports that information in `0x0201`.
  public static let additionalChargerState = Register(0xEDD4, "additionalChargerState", .un8)

  /// Yield today in kilowatt-hours ("Charger data registers", `0xEDD3`).
  ///
  /// The document's type is un32 up to and including firmware 1.12 and un16 in higher versions.
  public static let yieldToday = Register(
    0xEDD3, "yieldToday", .un16, scale: 0.01, unit: .kilowattHour)

  /// Maximum power today in watts ("Charger data registers", `0xEDD2`).
  public static let maximumPowerToday = Register(
    0xEDD2, "maximumPowerToday", .un16, unit: .watt)

  /// Yield yesterday in kilowatt-hours ("Charger data registers", `0xEDD1`).
  ///
  /// The document's type is un32 up to and including firmware 1.12 and un16 in higher versions.
  public static let yieldYesterday = Register(
    0xEDD1, "yieldYesterday", .un16, scale: 0.01, unit: .kilowattHour)

  /// Maximum power yesterday in watts ("Charger data registers", `0xEDD0`).
  public static let maximumPowerYesterday = Register(
    0xEDD0, "maximumPowerYesterday", .un16, unit: .watt)

  /// Voltage settings range as two packed bytes ("Charger data registers", `0xEDCE`).
  ///
  /// The document's type is un16. Byte 0 (the low byte): minimum system voltage, un8, 1 V.
  /// Byte 1 (the high byte): maximum system voltage, un8, 1 V. Available in firmware 1.16 and
  /// higher.
  public static let voltageSettingsRange = Register(0xEDCE, "voltageSettingsRange", .bytes)

  /// History version, no unit ("Charger data registers", `0xEDCD`).
  ///
  /// Available in firmware 1.16 and higher.
  public static let historyVersion = Register(0xEDCD, "historyVersion", .un8)

  /// Street light version, no unit ("Charger data registers", `0xEDCC`).
  ///
  /// Available in firmware 1.16 and higher.
  public static let streetLightVersion = Register(0xEDCC, "streetLightVersion", .un8)

  /// Equalise current maximum in percent ("Charger data registers", `0xEDC7`).
  ///
  /// MPPT RS models only.
  public static let equaliseCurrentMaximum = Register(
    0xEDC7, "equaliseCurrentMaximum", .un8, unit: .percent)

  /// Equalise voltage maximum in volts ("Charger data registers", `0xEDC6`).
  ///
  /// MPPT RS models only.
  public static let equaliseVoltageMaximum = Register(
    0xEDC6, "equaliseVoltageMaximum", .un16, scale: 0.01, unit: .volt)

  /// Adjustable voltage minimum in volts ("Charger data registers", `0x2211`).
  ///
  /// The lower end of the range allowed for the absorption, float and equalisation voltage
  /// settings. Available in firmware 1.30.
  public static let adjustableVoltageMinimum = Register(
    0x2211, "adjustableVoltageMinimum", .un16, scale: 0.01, unit: .volt)

  /// Adjustable voltage maximum in volts ("Charger data registers", `0x2212`).
  ///
  /// The upper end of the range allowed for the absorption, float and equalisation voltage
  /// settings. Available in firmware 1.30.
  public static let adjustableVoltageMaximum = Register(
    0x2212, "adjustableVoltageMaximum", .un16, scale: 0.01, unit: .volt)

  // MARK: DC channel (MPPT RS models only)

  /// Battery ripple voltage in volts ("DC channel registers - MPPT RS models only", `0xED8B`).
  public static let batteryRippleVoltage = Register(
    0xED8B, "batteryRippleVoltage", .un16, scale: 0.01, unit: .volt)

  /// Battery voltage in volts on MPPT RS models, replacing `0xEDD5` ("DC channel registers -
  /// MPPT RS models only", `0xED8D`).
  public static let batteryChannelVoltage = Register(
    0xED8D, "batteryChannelVoltage", .sn16, scale: 0.01, unit: .volt)

  /// Battery current in amperes on MPPT RS models, replacing `0xEDD7` ("DC channel registers -
  /// MPPT RS models only", `0xED8F`).
  public static let batteryChannelCurrent = Register(
    0xED8F, "batteryChannelCurrent", .sn16, scale: 0.1, unit: .ampere)

  // MARK: Solar panel data

  /// Number of MPPT trackers, no unit ("Solar panel data registers", `0x0244`).
  ///
  /// MPPT RS models only.
  public static let trackerCount = Register(0x0244, "trackerCount", .un8)

  /// Panel maximum current in amperes ("Solar panel data registers", `0xEDBF`).
  ///
  /// MPPT RS models only.
  public static let panelMaximumCurrent = Register(
    0xEDBF, "panelMaximumCurrent", .un16, scale: 0.1, unit: .ampere)

  /// Panel power in watts ("Solar panel data registers", `0xEDBC`).
  ///
  /// On an MPPT RS this is the combined power of all trackers.
  public static let panelPower = Register(
    0xEDBC, "panelPower", .un32, scale: 0.01, unit: .watt)

  /// Panel voltage in volts ("Solar panel data registers", `0xEDBB`).
  public static let panelVoltage = Register(
    0xEDBB, "panelVoltage", .un16, scale: 0.01, unit: .volt)

  /// Panel current in amperes ("Solar panel data registers", `0xEDBD`).
  ///
  /// Not available in the 10 A, 15 A and 20 A chargers.
  public static let panelCurrent = Register(
    0xEDBD, "panelCurrent", .un16, scale: 0.1, unit: .ampere)

  /// Panel maximum allowed voltage in volts ("Solar panel data registers", `0xEDB8`).
  ///
  /// Added in firmware 1.16.
  public static let panelMaximumVoltage = Register(
    0xEDB8, "panelMaximumVoltage", .un16, scale: 0.01, unit: .volt)

  /// Tracker mode enumeration, no unit ("Solar panel data registers", `0xEDB3`).
  ///
  /// 0 off, 1 voltage or current limited, 2 MPP tracker. Added in firmware 1.42.
  public static let trackerMode = Register(0xEDB3, "trackerMode", .un8)

  /// Panel starting voltage in volts ("Solar panel data registers", `0xEDB2`).
  ///
  /// MPPT RS models only.
  public static let panelStartingVoltage = Register(
    0xEDB2, "panelStartingVoltage", .un16, scale: 0.01, unit: .volt)

  /// Panel input resistance in ohms ("Solar panel data registers", `0xEDB1`).
  ///
  /// MPPT RS models only.
  public static let panelInputResistance = Register(
    0xEDB1, "panelInputResistance", .un32, unit: .ohm)

  // MARK: Individual MPPT trackers (MPPT RS models only)

  /// Panel power of tracker 1 in watts ("Solar panel data individual MPPT trackers registers",
  /// `0xECCC`; see `0xEDBC`).
  public static let tracker1PanelPower = Register(
    0xECCC, "tracker1PanelPower", .un32, scale: 0.01, unit: .watt)

  /// Panel power of tracker 2 in watts ("Solar panel data individual MPPT trackers registers",
  /// `0xECDC`; see `0xEDBC`).
  public static let tracker2PanelPower = Register(
    0xECDC, "tracker2PanelPower", .un32, scale: 0.01, unit: .watt)

  /// Panel power of tracker 3 in watts ("Solar panel data individual MPPT trackers registers",
  /// `0xECEC`; see `0xEDBC`).
  public static let tracker3PanelPower = Register(
    0xECEC, "tracker3PanelPower", .un32, scale: 0.01, unit: .watt)

  /// Panel power of tracker 4 in watts ("Solar panel data individual MPPT trackers registers",
  /// `0xECFC`; see `0xEDBC`).
  public static let tracker4PanelPower = Register(
    0xECFC, "tracker4PanelPower", .un32, scale: 0.01, unit: .watt)

  /// Panel voltage of tracker 1 in volts ("Solar panel data individual MPPT trackers
  /// registers", `0xECCB`; see `0xEDBB`).
  public static let tracker1PanelVoltage = Register(
    0xECCB, "tracker1PanelVoltage", .un16, scale: 0.01, unit: .volt)

  /// Panel voltage of tracker 2 in volts ("Solar panel data individual MPPT trackers
  /// registers", `0xECDB`; see `0xEDBB`).
  public static let tracker2PanelVoltage = Register(
    0xECDB, "tracker2PanelVoltage", .un16, scale: 0.01, unit: .volt)

  /// Panel voltage of tracker 3 in volts ("Solar panel data individual MPPT trackers
  /// registers", `0xECEB`; see `0xEDBB`).
  public static let tracker3PanelVoltage = Register(
    0xECEB, "tracker3PanelVoltage", .un16, scale: 0.01, unit: .volt)

  /// Panel voltage of tracker 4 in volts ("Solar panel data individual MPPT trackers
  /// registers", `0xECFB`; see `0xEDBB`).
  public static let tracker4PanelVoltage = Register(
    0xECFB, "tracker4PanelVoltage", .un16, scale: 0.01, unit: .volt)

  /// Panel current of tracker 1 in amperes ("Solar panel data individual MPPT trackers
  /// registers", `0xECCD`; see `0xEDBD`).
  public static let tracker1PanelCurrent = Register(
    0xECCD, "tracker1PanelCurrent", .un16, scale: 0.1, unit: .ampere)

  /// Panel current of tracker 2 in amperes ("Solar panel data individual MPPT trackers
  /// registers", `0xECDD`; see `0xEDBD`).
  public static let tracker2PanelCurrent = Register(
    0xECDD, "tracker2PanelCurrent", .un16, scale: 0.1, unit: .ampere)

  /// Panel current of tracker 3 in amperes ("Solar panel data individual MPPT trackers
  /// registers", `0xECED`; see `0xEDBD`).
  public static let tracker3PanelCurrent = Register(
    0xECED, "tracker3PanelCurrent", .un16, scale: 0.1, unit: .ampere)

  /// Panel current of tracker 4 in amperes ("Solar panel data individual MPPT trackers
  /// registers", `0xECFD`; see `0xEDBD`).
  public static let tracker4PanelCurrent = Register(
    0xECFD, "tracker4PanelCurrent", .un16, scale: 0.1, unit: .ampere)

  /// Mode of tracker 1, no unit ("Solar panel data individual MPPT trackers registers",
  /// `0xECC3`; values as for `0xEDB3`).
  public static let tracker1Mode = Register(0xECC3, "tracker1Mode", .un8)

  /// Mode of tracker 2, no unit ("Solar panel data individual MPPT trackers registers",
  /// `0xECD3`; values as for `0xEDB3`).
  public static let tracker2Mode = Register(0xECD3, "tracker2Mode", .un8)

  /// Mode of tracker 3, no unit ("Solar panel data individual MPPT trackers registers",
  /// `0xECE3`; values as for `0xEDB3`).
  public static let tracker3Mode = Register(0xECE3, "tracker3Mode", .un8)

  /// Mode of tracker 4, no unit ("Solar panel data individual MPPT trackers registers",
  /// `0xECF3`; values as for `0xEDB3`).
  public static let tracker4Mode = Register(0xECF3, "tracker4Mode", .un8)

  // MARK: Load output data and settings (models with a load output)

  /// Load current in amperes ("Load output data/settings registers", `0xEDAD`).
  public static let loadCurrent = Register(
    0xEDAD, "loadCurrent", .un16, scale: 0.1, unit: .ampere)

  /// Load offset voltage in volts ("Load output data/settings registers", `0xEDAC`).
  ///
  /// The document does not say whether this is a setting; it is marked persistent as a
  /// precaution.
  public static let loadOffsetVoltage = Register(
    0xEDAC, "loadOffsetVoltage", .un8, scale: 0.01, unit: .volt, isPersistent: true)

  /// Load output control enumeration, no unit ("Load output data/settings registers" and "Load
  /// output control values (register 0xEDAB)", `0xEDAB`).
  ///
  /// The lower 4 bits hold the value and must be masked: 0 off, 1 automatic control or
  /// BatteryLife (default), 2 alternative control 1 (off below 11.1 V, on above 13.1 V),
  /// 3 alternative control 2 (off below 11.8 V, on above 14.0 V), 4 on (no discharge guard),
  /// 5 user defined settings 1 (off below `0xED9C`, on above `0xED9D`), 6 user defined
  /// settings 2 (off below low, on between low and high, off above high), 7 automatic energy
  /// selector. Bit 7 is set while the lighting controller timer is active. Values 5 and 6
  /// need firmware 1.15, value 7 needs 1.26 and a SmartSolar model.
  public static let loadOutputControl = Register(
    0xEDAB, "loadOutputControl", .un8, isPersistent: true)

  /// Load output voltage in volts ("Load output data/settings registers", `0xEDA9`).
  ///
  /// Only on SmartSolar 10 A, 15 A and 20 A chargers.
  public static let loadOutputVoltage = Register(
    0xEDA9, "loadOutputVoltage", .un16, scale: 0.01, unit: .volt)

  /// Load output state, no unit: 0 off, 1 on ("Load output data/settings registers" and "Load
  /// output state values (register 0xEDA8)", `0xEDA8`).
  public static let loadOutputState = Register(0xEDA8, "loadOutputState", .un8)

  /// Load switch high level in volts ("Load output data/settings registers", `0xED9D`).
  ///
  /// Introduced in firmware 1.15; with 24 V operation it needs 1.16. Not on the MPPT 70|15.
  public static let loadSwitchHighLevel = Register(
    0xED9D, "loadSwitchHighLevel", .un16, scale: 0.01, unit: .volt, isPersistent: true)

  /// Load switch low level in volts ("Load output data/settings registers", `0xED9C`).
  ///
  /// Introduced in firmware 1.15; with 24 V operation it needs 1.16. Not on the MPPT 70|15.
  public static let loadSwitchLowLevel = Register(
    0xED9C, "loadSwitchLowLevel", .un16, scale: 0.01, unit: .volt, isPersistent: true)

  /// Load output off reason bit mask, no unit ("Load output data/settings registers" and "Load
  /// output off reason bit-mask (register 0xED91)", `0xED91`).
  ///
  /// Bit 0 battery low, 1 short circuit, 2 timer program, 3 remote input (VE.Direct RX pin
  /// alternate function), 4 pay-as-you-go out of credit, 5 and 6 reserved, 7 device starting
  /// up. Added in firmware 1.20, SmartSolar models only.
  public static let loadOutputOffReason = Register(0xED91, "loadOutputOffReason", .un8)

  /// Load automatic energy selector timer in minutes ("Load output data/settings registers"
  /// and "Lighting controller timer", `0xED90`).
  ///
  /// The time the load stays on while the voltage is between the on and off levels. Added in
  /// firmware 1.26, SmartSolar models with a load output only.
  public static let loadAESTimer = Register(
    0xED90, "loadAESTimer", .un16, unit: .minute, isPersistent: true)

  // MARK: Relay settings (models with a relay output)

  /// Relay operation mode enumeration, no unit ("Relay settings registers" and "Relay operation
  /// modes (register 0xEDD9)", `0xEDD9`).
  ///
  /// 0 relay always off, 1 panel voltage high (uses `0xEDBA`, `0xEDB9`), 2 internal temperature
  /// high (above 85 °C), 3 battery voltage too low (uses `0x0350`, `0x0351`), 4 equalisation
  /// active, 5 error condition present, 6 internal temperature low (below -20 °C), 7 battery
  /// voltage too high (uses `0x0352`, `0x0353`), 8 charger in float or storage, 9 day
  /// detection (panels irradiated), 10 load control.
  public static let relayOperationMode = Register(
    0xEDD9, "relayOperationMode", .un8, isPersistent: true)

  /// Relay battery low voltage set level in volts ("Relay settings registers", `0x0350`).
  public static let relayBatteryLowVoltageSet = Register(
    0x0350, "relayBatteryLowVoltageSet", .un16, scale: 0.01, unit: .volt, isPersistent: true)

  /// Relay battery low voltage clear level in volts ("Relay settings registers", `0x0351`).
  public static let relayBatteryLowVoltageClear = Register(
    0x0351, "relayBatteryLowVoltageClear", .un16, scale: 0.01, unit: .volt, isPersistent: true)

  /// Relay battery high voltage set level in volts ("Relay settings registers", `0x0352`).
  public static let relayBatteryHighVoltageSet = Register(
    0x0352, "relayBatteryHighVoltageSet", .un16, scale: 0.01, unit: .volt, isPersistent: true)

  /// Relay battery high voltage clear level in volts ("Relay settings registers", `0x0353`).
  public static let relayBatteryHighVoltageClear = Register(
    0x0353, "relayBatteryHighVoltageClear", .un16, scale: 0.01, unit: .volt, isPersistent: true)

  /// Relay panel high voltage set level in volts ("Relay settings registers", `0xEDBA`).
  public static let relayPanelHighVoltageSet = Register(
    0xEDBA, "relayPanelHighVoltageSet", .un16, scale: 0.01, unit: .volt, isPersistent: true)

  /// Relay panel high voltage clear level in volts ("Relay settings registers", `0xEDB9`).
  public static let relayPanelHighVoltageClear = Register(
    0xEDB9, "relayPanelHighVoltageClear", .un16, scale: 0.01, unit: .volt, isPersistent: true)

  /// Relay minimum enabled time in minutes ("Relay settings registers", `0x100A`).
  public static let relayMinimumEnabledTime = Register(
    0x100A, "relayMinimumEnabledTime", .un16, unit: .minute, isPersistent: true)

  // MARK: Lighting controller timer

  /// Lighting controller timer event 0 as a packed record ("Lighting controller timer" and
  /// "Timer events (registers 0xEDA0..0xEDA5)", `0xEDA0`).
  ///
  /// The document's type is un32, sent little-endian. Bytes 0 and 1 (bits 0 to 15): time
  /// offset, sn16, 1 min. Byte 2 (bits 16 to 23): anchor point, un8: 1 sunset, 2 midnight,
  /// 3 sunrise. Byte 3 (bits 24 to 31): dim action, un8, 1 %, 0 to 100. Sunset and sunrise are
  /// absolute; midnight needs the charger to be synchronised with the solar activity.
  /// The lighting controller needs firmware 1.15 and a 10 A, 15 A or 20 A model with a load
  /// output other than the BlueSolar MPPT 70|15.
  public static let timerEvent0 = Register(0xEDA0, "timerEvent0", .bytes, isPersistent: true)

  /// Lighting controller timer event 1 as a packed record ("Lighting controller timer",
  /// `0xEDA1`); layout as for `0xEDA0`.
  public static let timerEvent1 = Register(0xEDA1, "timerEvent1", .bytes, isPersistent: true)

  /// Lighting controller timer event 2 as a packed record ("Lighting controller timer",
  /// `0xEDA2`); layout as for `0xEDA0`.
  public static let timerEvent2 = Register(0xEDA2, "timerEvent2", .bytes, isPersistent: true)

  /// Lighting controller timer event 3 as a packed record ("Lighting controller timer",
  /// `0xEDA3`); layout as for `0xEDA0`.
  public static let timerEvent3 = Register(0xEDA3, "timerEvent3", .bytes, isPersistent: true)

  /// Lighting controller timer event 4 as a packed record ("Lighting controller timer",
  /// `0xEDA4`); layout as for `0xEDA0`.
  public static let timerEvent4 = Register(0xEDA4, "timerEvent4", .bytes, isPersistent: true)

  /// Lighting controller timer event 5 as a packed record ("Lighting controller timer",
  /// `0xEDA5`); layout as for `0xEDA0`.
  public static let timerEvent5 = Register(0xEDA5, "timerEvent5", .bytes, isPersistent: true)

  /// Mid-point shift in minutes ("Lighting controller timer", `0xEDA7`).
  ///
  /// Compensates the difference between solar midnight (halfway between sunset and sunrise)
  /// and clock midnight.
  public static let midPointShift = Register(
    0xEDA7, "midPointShift", .sn16, unit: .minute, isPersistent: true)

  /// Gradual dim speed in seconds per 1 % change ("Lighting controller timer", `0xED9B`).
  ///
  /// 0 (the default) disables gradual dimming. Introduced in firmware 1.16.
  public static let gradualDimSpeed = Register(
    0xED9B, "gradualDimSpeed", .un8, unit: .second, isPersistent: true)

  /// Panel voltage for night detection in volts ("Lighting controller timer", `0xED9A`).
  ///
  /// 0 uses the built-in default. Must be lower than `0xED99`. The lowest detectable voltage
  /// is 11.4 V before firmware 1.26. Introduced in firmware 1.16.
  public static let panelVoltageNight = Register(
    0xED9A, "panelVoltageNight", .un16, scale: 0.01, unit: .volt, isPersistent: true)

  /// Panel voltage for day detection in volts ("Lighting controller timer", `0xED99`).
  ///
  /// 0 uses the built-in default. Must be higher than `0xED9A`. The lowest detectable voltage
  /// is 11.4 V before firmware 1.26. Introduced in firmware 1.16.
  public static let panelVoltageDay = Register(
    0xED99, "panelVoltageDay", .un16, scale: 0.01, unit: .volt, isPersistent: true)

  /// Sunset delay in minutes ("Lighting controller timer", `0xED96`).
  ///
  /// Introduced in firmware 1.26.
  public static let sunsetDelay = Register(
    0xED96, "sunsetDelay", .un16, unit: .minute, isPersistent: true)

  /// Sunrise delay in minutes ("Lighting controller timer", `0xED97`).
  ///
  /// Introduced in firmware 1.26.
  public static let sunriseDelay = Register(
    0xED97, "sunriseDelay", .un16, unit: .minute, isPersistent: true)

  /// Solar activity, no unit: 0 dark, 1 light ("Lighting controller timer", `0x2030`).
  public static let solarActivity = Register(0x2030, "solarActivity", .un8)

  /// Time of day in minutes since midnight ("Lighting controller timer", `0x2031`).
  ///
  /// `0xFFFF` means the time is unknown, for example before the charger has synchronised. It
  /// can be written with the current time, which the charger uses for 5 days before falling
  /// back to the solar activity.
  public static let timeOfDay = Register(
    0x2031, "timeOfDay", .un16, unit: .minute, notAvailable: 0xFFFF)

  // MARK: VE.Direct port functions

  /// VE.Direct TX port operation mode enumeration, no unit ("VE.Direct port functions" and
  /// "VE.Direct TX Port operation modes (register 0xED9E)", `0xED9E`).
  ///
  /// 0 normal VE.Direct communication (default), 1 pulse for every 0.01 kWh harvested (100 ms
  /// low), 2 lighting control PWM normal (160 Hz, 0 % = 0 V), 3 lighting control PWM inverted
  /// (160 Hz, 0 % = 5 V), 4 virtual load output (selected models without a load output,
  /// firmware 1.17). Any mode other than 0 stops the text protocol; the charger still answers
  /// a valid HEX frame before returning to the configured mode. Modes 2 and 3 need the
  /// lighting controller timer.
  public static let txPortOperationMode = Register(
    0xED9E, "txPortOperationMode", .un8, isPersistent: true)

  /// VE.Direct RX port operation mode enumeration, no unit ("VE.Direct port functions" and
  /// "VE.Direct RX Port operation modes (register 0xED98)", `0xED98`).
  ///
  /// 0 remote on/off (default without a load output), 1 load output configuration (default
  /// with a load output), 2 load output on/off remote control (inverted), 3 load output on/off
  /// remote control (normal, firmware 1.26). Only on the 10 A, 15 A and 20 A models since
  /// firmware 1.17.
  public static let rxPortOperationMode = Register(
    0xED98, "rxPortOperationMode", .un8, isPersistent: true)

  // MARK: Restore factory defaults

  /// Restore every setting except the factory calibration to its default, no value ("Restore
  /// factory defaults", `0x0004`).
  ///
  /// Triggered by a write; the data of the write is ignored.
  public static let restoreDefaults = Register(0x0004, "restoreDefaults", .none)

  // MARK: History data

  /// Clear the history, no value ("History data", `0x1030`).
  ///
  /// History is available from firmware 1.16 on all models except the BlueSolar MPPT 70|15
  /// (product id `0x0300`).
  public static let clearHistory = Register(0x1030, "clearHistory", .none)

  /// History totals as a packed record ("History data" and "History total record (register
  /// 0x104F)", `0x104F`).
  ///
  /// Firmware 1.16, 19 bytes:
  /// - 0: reserved (0), un8
  /// - 1: error database (0), un8
  /// - 2: error 0, the most recent, un8, codes as for `0xEDDA`
  /// - 3: error 1, un8
  /// - 4: error 2, un8
  /// - 5: error 3, the oldest, un8
  /// - 6: total yield, user resettable, un32, 0.01 kWh
  /// - 10: total yield, system, un32, 0.01 kWh
  /// - 14: panel voltage maximum, un16, 0.01 V
  /// - 16: battery voltage maximum, un16, 0.01 V
  /// - 18: number of days available, un8
  ///
  /// Firmware 1.17 and higher, 34 bytes: byte 0 is 1, bytes 1 to 18 are as above, then
  /// - 19: battery voltage minimum, un16, 0.01 V
  /// - 21: 13 reserved bytes (`0xFF`)
  public static let historyTotals = Register(0x104F, "historyTotals", .bytes)

  /// Returns the history day record of the day a number of days ago, a packed record ("History
  /// data" and "History day record (registers 0x1050..0x106E)", `0x1050` to `0x106E`).
  ///
  /// `0x1050` is today, `0x1051` yesterday, and so on. A day without data answers with an
  /// empty record and response flag `0x04`. The record is 34 bytes:
  /// - 0: reserved (0), un8
  /// - 1: yield, un32, 0.01 kWh
  /// - 5: consumed, un32, 0.01 kWh; `0xFFFFFFFF` on models without a load output
  /// - 9: battery voltage maximum, un16, 0.01 V
  /// - 11: battery voltage minimum, un16, 0.01 V
  /// - 13: error database (0), un8
  /// - 14: error 0, the most recent, un8, codes as for `0xEDDA`
  /// - 15: error 1, un8
  /// - 16: error 2, un8
  /// - 17: error 3, the oldest, un8
  /// - 18: time in bulk, un16, 1 min
  /// - 20: time in absorption, un16, 1 min
  /// - 22: time in float, un16, 1 min
  /// - 24: power maximum, un32, 1 W
  /// - 28: battery current maximum, un16, 0.1 A
  /// - 30: panel voltage maximum, un16, 0.01 V
  /// - 32: day sequence number, un16; increases by 1 each day and wraps to 0 at 365
  ///
  /// - Parameter daysAgo: 0 for today up to 30.
  /// - Returns: The register, or `nil` when `daysAgo` is outside 0 to 30.
  public static func dayHistory(daysAgo: Int) -> Register? {
    guard (0...30).contains(daysAgo), let offset = UInt16(exactly: daysAgo) else { return nil }
    return Register(RegisterID(rawValue: 0x1050 + offset), "dayHistory\(daysAgo)", .bytes)
  }

  /// Returns the per-tracker history day record of the day a number of days ago, a packed
  /// record ("History data" and "History MPPT day record (registers 0x10A0..0x10BD)",
  /// `0x10A0` to `0x10BE`).
  ///
  /// `0x10A0` is today, `0x10A1` yesterday, and so on. Only on units with several trackers,
  /// such as the MPPT RS. The "History data" table ends the range at `0x10BE` and the record's
  /// heading at `0x10BD`; this function follows the table. A field of a tracker the unit does
  /// not have reads `0xFFFF`. The record is 36 bytes:
  /// - 0: reserved (0), un8
  /// - 1: day sequence number, un16
  /// - 3, 5, 7, 9: energy of trackers 1 to 4, un16, 0.01 kWh
  /// - 11, 13, 15, 17: peak power of trackers 1 to 4, un16, 1 W
  /// - 19, 21, 23, 25: maximum open-circuit voltage of trackers 1 to 4, un16, 0.01 V
  /// - 27: 9 reserved bytes (`0xFF`)
  ///
  /// - Parameter daysAgo: 0 for today up to 30.
  /// - Returns: The register, or `nil` when `daysAgo` is outside 0 to 30.
  public static func trackerDayHistory(daysAgo: Int) -> Register? {
    guard (0...30).contains(daysAgo), let offset = UInt16(exactly: daysAgo) else { return nil }
    return Register(RegisterID(rawValue: 0x10A0 + offset), "trackerDayHistory\(daysAgo)", .bytes)
  }

  // MARK: Display settings

  /// Pluggable display backlight mode, no unit: 0 keypress, 1 on, 2 auto ("Pluggable display
  /// settings", `0x0400`).
  ///
  /// Only on models with the pluggable LCD display.
  public static let displayBacklightMode = Register(
    0x0400, "displayBacklightMode", .un8, isPersistent: true)

  /// Display backlight intensity, no unit: 0 always off, 1 on ("Pluggable display settings"
  /// and "Internal display settings", `0x0401`).
  public static let displayBacklightIntensity = Register(
    0x0401, "displayBacklightIntensity", .un8, isPersistent: true)

  /// Display scroll text speed, no unit: 1 slow to 5 fast ("Pluggable display settings" and
  /// "Internal display settings", `0x0402`).
  public static let displayScrollTextSpeed = Register(
    0x0402, "displayScrollTextSpeed", .un8, isPersistent: true)

  /// Pluggable display setup lock, no unit: 0 unlocked, 1 locked ("Pluggable display
  /// settings", `0x0403`).
  ///
  /// Since firmware 1.30.
  public static let displaySetupLock = Register(
    0x0403, "displaySetupLock", .un8, isPersistent: true)

  /// Display temperature unit, no unit: 0 Celsius, 1 Fahrenheit ("Pluggable display settings"
  /// and "Internal display settings", `0x0404`).
  ///
  /// Since firmware 1.30 on the pluggable display.
  public static let displayTemperatureUnit = Register(
    0x0404, "displayTemperatureUnit", .un8, isPersistent: true)

  /// Internal display contrast, no unit ("Internal display settings", `0x0406`).
  ///
  /// MPPT RS models only, and only displays whose hardware can adjust contrast.
  public static let displayContrast = Register(
    0x0406, "displayContrast", .un8, isPersistent: true)

  /// Internal display backlight mode, no unit: 0 off, 1 on, 2 auto ("Internal display
  /// settings", `0x0408`).
  ///
  /// MPPT RS models only.
  public static let internalDisplayBacklightMode = Register(
    0x0408, "internalDisplayBacklightMode", .un8, isPersistent: true)

  // MARK: Remote control

  /// Charge algorithm version, no unit ("Remote control registers", `0x2000`).
  ///
  /// Used with `0x0104` to identify and group chargers for synchronised charging. Firmware
  /// 1.44 or higher, on SmartSolar models that support synchronised charging.
  public static let chargeAlgorithmVersion = Register(0x2000, "chargeAlgorithmVersion", .un8)

  /// Charge voltage set-point in volts ("Remote control registers", `0x2001`).
  ///
  /// Read from the master unit and written to the others so that a group behaves as one unit,
  /// or written under external control; see `0x200E`.
  public static let chargeVoltageSetPoint = Register(
    0x2001, "chargeVoltageSetPoint", .un16, scale: 0.01, unit: .volt)

  /// Battery voltage sense in volts ("Remote control registers", `0x2002`).
  ///
  /// Remote sensor data written to the charger. It must be rewritten within 60 seconds and lie
  /// within 5 V of the voltage on the charger terminals; the charger adapts its charge voltage
  /// by up to 2 V. `0xFFFF` means the data is no longer available, and the charger sends it
  /// asynchronously on timeout (firmware 1.26).
  public static let batteryVoltageSense = Register(
    0x2002, "batteryVoltageSense", .un16, scale: 0.01, unit: .volt, notAvailable: 0xFFFF)

  /// Battery temperature sense in degrees Celsius ("Remote control registers", `0x2003`).
  ///
  /// Remote sensor data written to the charger. It must be rewritten within 60 seconds.
  /// `0x7FFF` means the data is no longer available, and the charger sends it asynchronously
  /// on timeout (firmware 1.26).
  public static let batteryTemperatureSense = Register(
    0x2003, "batteryTemperatureSense", .sn16, scale: 0.01, unit: .celsius, notAvailable: 0x7FFF)

  /// Remote command enumeration, no unit ("Remote control registers" and "Remote commands
  /// (register 0x2004)", `0x2004`).
  ///
  /// 1 start equalise, 2 stop equalise (both only on models with manual equalisation, see
  /// `0x0140`), 3 synchronise user interface, 4 synchronise day event (3 and 4 are not used on
  /// VE.Direct).
  public static let remoteCommand = Register(0x2004, "remoteCommand", .un8)

  /// Charge state elapsed time in milliseconds ("Remote control registers", `0x2007`).
  ///
  /// Copied from the master unit to the other units. Firmware 1.44 or higher, on SmartSolar
  /// models that support synchronised charging.
  public static let chargeStateElapsedTime = Register(
    0x2007, "chargeStateElapsedTime", .un32, unit: .millisecond)

  /// Absorption time in hours ("Remote control registers" and "Absorption time (register
  /// 0x2008)", `0x2008`).
  ///
  /// Up to firmware 1.39 the available absorption time; from 1.42 the time spent in
  /// absorption. Copied from the master unit to the other units. Firmware 1.44 or higher, on
  /// SmartSolar models that support synchronised charging.
  public static let absorptionTime = Register(
    0x2008, "absorptionTime", .un16, scale: 0.01, unit: .hour)

  /// Error code injected by the network master, no unit ("Remote control registers" and "Error
  /// code (register 0x2009)", `0x2009`).
  ///
  /// Codes as for `0xEDDA`. Firmware 1.44 or higher, on SmartSolar models that support
  /// synchronised charging.
  public static let networkErrorCode = Register(0x2009, "networkErrorCode", .un8)

  /// Battery charge current in amperes ("Remote control registers" and "Battery charge current
  /// (register 0x200A)", `0x200A`).
  ///
  /// The actual battery current from a battery monitor, used for the tail current condition.
  /// Firmware 1.44 or higher, on SmartSolar models that support synchronised charging.
  public static let batteryChargeCurrent = Register(
    0x200A, "batteryChargeCurrent", .sn32, scale: 0.001, unit: .ampere)

  /// Battery idle voltage in volts ("Remote control registers" and "Battery idle voltage
  /// (register 0x200B)", `0x200B`).
  ///
  /// The battery voltage measured before charging starts, by the first unit to start.
  /// Firmware 1.44 or higher, on SmartSolar models that support synchronised charging.
  public static let batteryIdleVoltage = Register(
    0x200B, "batteryIdleVoltage", .un16, scale: 0.01, unit: .volt)

  /// Device state for synchronised charging, no unit ("Remote control registers" and "Device
  /// state (register 0x200C)", `0x200C`).
  ///
  /// 0 not charging, 2 fault, 3 bulk, 4 absorption, 5 float, 6 storage, 7 manual equalise,
  /// 11 power supply, 245 wake-up, 246 repeated absorption, 247 auto equalise, 248 battery
  /// safe, 249 load detect, 252 external control, 255 unavailable. States 6, 11, 246, 248, 249
  /// and 252 occur only in slave mode, with the voltage set-point sent by the master.
  /// Firmware 1.44 or higher, on SmartSolar models that support synchronised charging.
  public static let networkDeviceState = Register(0x200C, "networkDeviceState", .un8)

  /// Network info bit field, no unit ("Remote control registers" and "Network info (register
  /// 0x200D)", `0x200D`).
  ///
  /// Bit 0 controlled by a BMS, 1 voltage set-point controlled remotely, 2 charge slave,
  /// 3 charge master, 4 using ICHARGE (battery current estimate), 5 using ISENSE (actual
  /// battery current), 6 using TSENSE, 7 using VSENSE, 8 held in standby while the network
  /// initialises. The document's type is un8 although it lists bit 8. Added in firmware 1.42.
  public static let networkInfo = Register(0x200D, "networkInfo", .un8)

  /// Network mode bit field, no unit ("Remote control registers" and "Network mode bit
  /// definitions (register 0x200E)", `0x200E`).
  ///
  /// Bit 0 networked (visual indication only), 1 slave mode (remote control of voltage
  /// set-point, current set-point and charge state), 2 external control mode (remote control
  /// of voltage and current set-points), 3 BMS controlled (as bit 2, with BMS protection
  /// active), 4 charge group master (not used), 5 charge instance master, 6 standby,
  /// 7 reserved. Zero is stand-alone operation, the default.
  /// The charger returns to stand-alone operation after 1 minute without data. With bit 3 set,
  /// a written current limit or voltage set-point makes the charger store the BMS present
  /// setting `0xEDE8`, after which it no longer operates stand-alone.
  public static let networkMode = Register(0x200E, "networkMode", .un8)

  /// Network status, no unit ("Remote control registers" and "Network status (register
  /// 0x200F)", `0x200F`).
  ///
  /// Low nibble: 0 slave mode, 1 group master, 2 instance master, 3 group and instance master,
  /// 4 stand-alone (default). Bit 4 using ICHARGE, 5 using ISENSE (both firmware 1.44),
  /// 6 using TSENSE, 7 using VSENSE (both firmware 1.26). Maintained per interface.
  public static let networkStatus = Register(0x200F, "networkStatus", .un8)

  /// Total charge current in amperes ("Remote control registers" and "Total charge current
  /// (register 0x2013)", `0x2013`).
  ///
  /// The estimated battery current, the sum of the known DC battery currents in the system.
  /// Firmware 1.44 or higher, on SmartSolar models that support synchronised charging.
  public static let totalChargeCurrent = Register(
    0x2013, "totalChargeCurrent", .sn32, scale: 0.001, unit: .ampere)

  /// Charge current percentage in percent ("Remote control registers", `0x2014`).
  ///
  /// Deprecated: present in firmware 1.17 only and replaced by `0x2015`.
  public static let chargeCurrentPercentage = Register(
    0x2014, "chargeCurrentPercentage", .un8, unit: .percent)

  /// Charge current limit in amperes ("Remote control registers" and "Charge current limit
  /// (register 0x2015)", `0x2015`).
  ///
  /// Must be written more than once a minute together with `0x200E`. The charger uses the
  /// lower of this limit and the battery maximum current `0xEDF0`. Firmware 1.19 and higher.
  public static let chargeCurrentLimit = Register(
    0x2015, "chargeCurrentLimit", .un16, scale: 0.1, unit: .ampere)

  /// Manual equalisation pending, no unit ("Remote control registers", `0x2018`).
  ///
  /// Firmware 1.44 or higher, on SmartSolar models that support synchronised charging.
  public static let manualEqualisationPending = Register(
    0x2018, "manualEqualisationPending", .un8)

  /// Total DC input power in watts ("Remote control registers" and "Total DC input power
  /// (register 0x2027)", `0x2027`).
  ///
  /// The sum of the panel powers `0xEDBC` of a synchronised charging system, written to every
  /// unit by the network master. Firmware 1.44 or higher, on SmartSolar models that support
  /// synchronised charging.
  public static let totalDCInputPower = Register(
    0x2027, "totalDCInputPower", .un32, scale: 0.01, unit: .watt)

  // MARK: All registers

  /// Every register of the family, in the order of the document.
  public static let registers: [Register] =
    [
      productID, groupID, serialNumber, modelName, capabilities,
      deviceMode, deviceState, remoteControlUsed, deviceOffReasonShort, deviceOffReason,
      batterySafeMode, adaptiveMode, automaticEqualisationMode, bulkTimeLimit,
      absorptionTimeLimit, absorptionVoltage, floatVoltage, equalisationVoltage,
      temperatureCompensation, batteryType, batteryMaximumCurrent, batteryVoltage,
      batteryTemperature, batteryVoltageSetting, bmsPresent, tailCurrent,
      lowTemperatureChargeCurrent, automaticEqualisationStopOnVoltage, equalisationCurrentLevel,
      equalisationDuration, rebulkVoltageOffset, batteryLowTemperatureLevel, voltageCompensation,
      remoteInputMode, twoWireBMSInputStates,
      chargerMaximumCurrent, systemYield, userYield, chargerInternalTemperature,
      chargerErrorCode, chargerCurrent, chargerVoltage, additionalChargerState, yieldToday,
      maximumPowerToday, yieldYesterday, maximumPowerYesterday, voltageSettingsRange,
      historyVersion, streetLightVersion, equaliseCurrentMaximum, equaliseVoltageMaximum,
      adjustableVoltageMinimum, adjustableVoltageMaximum,
      batteryRippleVoltage, batteryChannelVoltage, batteryChannelCurrent,
      trackerCount, panelMaximumCurrent, panelPower, panelVoltage, panelCurrent,
      panelMaximumVoltage, trackerMode, panelStartingVoltage, panelInputResistance,
      tracker1PanelPower, tracker2PanelPower, tracker3PanelPower, tracker4PanelPower,
      tracker1PanelVoltage, tracker2PanelVoltage, tracker3PanelVoltage, tracker4PanelVoltage,
      tracker1PanelCurrent, tracker2PanelCurrent, tracker3PanelCurrent, tracker4PanelCurrent,
      tracker1Mode, tracker2Mode, tracker3Mode, tracker4Mode,
      loadCurrent, loadOffsetVoltage, loadOutputControl, loadOutputVoltage, loadOutputState,
      loadSwitchHighLevel, loadSwitchLowLevel, loadOutputOffReason, loadAESTimer,
      relayOperationMode, relayBatteryLowVoltageSet, relayBatteryLowVoltageClear,
      relayBatteryHighVoltageSet, relayBatteryHighVoltageClear, relayPanelHighVoltageSet,
      relayPanelHighVoltageClear, relayMinimumEnabledTime,
      timerEvent0, timerEvent1, timerEvent2, timerEvent3, timerEvent4, timerEvent5,
      midPointShift, gradualDimSpeed, panelVoltageNight, panelVoltageDay, sunsetDelay,
      sunriseDelay, solarActivity, timeOfDay,
      txPortOperationMode, rxPortOperationMode,
      restoreDefaults,
      clearHistory, historyTotals,
    ]
    + (0...30).compactMap { dayHistory(daysAgo: $0) }
    + (0...30).compactMap { trackerDayHistory(daysAgo: $0) }
    + [
      displayBacklightMode, displayBacklightIntensity, displayScrollTextSpeed, displaySetupLock,
      displayTemperatureUnit, displayContrast, internalDisplayBacklightMode,
      chargeAlgorithmVersion, chargeVoltageSetPoint, batteryVoltageSense,
      batteryTemperatureSense, remoteCommand, chargeStateElapsedTime, absorptionTime,
      networkErrorCode, batteryChargeCurrent, batteryIdleVoltage, networkDeviceState,
      networkInfo, networkMode, networkStatus, totalChargeCurrent, chargeCurrentPercentage,
      chargeCurrentLimit, manualEqualisationPending, totalDCInputPower,
    ]
}
