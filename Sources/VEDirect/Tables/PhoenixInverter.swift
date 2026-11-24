/// The HEX registers of the Phoenix inverters with a VE.Direct port.
///
/// Source: "VE.Direct Protocol – Phoenix Inverters" (Rev 5, 2021-09-06).
///
/// The document says that registers used for user settings are saved to non-volatile memory,
/// but, unlike most Victron products, not automatically: a changed setting is kept only after
/// `1` (NvmSave) is written to `0xEB99`, and until then it reverts to the last saved value at a
/// power cycle or reset. Which registers count as user settings is the library's inference:
/// those marked W or R/W in the AC-out control, battery control and relay control tables, and
/// BLE mode.
///
/// The document marks most settings "W"; it does not say that they cannot be read.
public enum PhoenixInverter {
  // MARK: Saving and reverting

  /// Non-volatile memory command, without a unit ("Saving and Reverting registers", `0xEB99`).
  ///
  /// Write-only. 0 no command (the value read back), 1 NvmSave: save the current user settings,
  /// 2 NvmRevert: cancel modified settings and load the last saved ones, 3 NvmBackup: undo the
  /// last save and load the settings saved before it (reverts instead when no backup exists,
  /// as can happen after a firmware update), 4 NvmDefault: load the factory defaults, as
  /// `0x0004` does.
  public static let nonVolatileMemoryCommand = Register(
    0xEB99, "nonVolatileMemoryCommand", .un8)

  /// Restore defaults command, without a value ("Saving and Reverting registers", `0x0004`).
  ///
  /// Write-only. Restores every user setting to its factory default and keeps the factory
  /// calibration data. The data part of the message is not required and is ignored.
  public static let restoreDefaults = Register(0x0004, "restoreDefaults", .none)

  // MARK: Product information

  /// Product id, without a unit ("Product information registers", `0x0100`).
  ///
  /// Read-only. Byte 0 is 0, bytes 1 and 2 are the product id (un16), byte 3 is `0xFE`.
  public static let productID = Register(0x0100, "productID", .un32)

  /// Hardware revision, without a unit ("Product information registers", `0x0101`).
  ///
  /// Read-only. Byte 0 is 0, bytes 1 and 2 are the hardware revision number (un16).
  public static let productRevision = Register(0x0101, "productRevision", .un24)

  /// Firmware application version, without a unit ("Product information registers", `0x0102`).
  ///
  /// Read-only. Byte 0 is 0, byte 1 the minor version, byte 2 the major version with the
  /// firmware type in bits 7 and 6: 0 bootloader, 1 application (released), 2 tester,
  /// 3 release candidate (beta). The document describes three bytes of the un32.
  public static let applicationVersion = Register(0x0102, "applicationVersion", .un32)

  /// Serial number as text ("Product information registers", `0x010A`).
  ///
  /// Read-only.
  public static let serialNumber = Register(0x010A, "serialNumber", .text)

  /// Model name as text ("Product information registers", `0x010B`).
  ///
  /// Read-only.
  public static let modelName = Register(0x010B, "modelName", .text)

  /// Rated AC output power in volt-amperes ("Product information registers", `0x2203`).
  ///
  /// Read-only. Since version 1.10.
  public static let acOutputRatedPower = Register(
    0x2203, "acOutputRatedPower", .sn16, unit: .voltAmpere)

  /// Capabilities bit field ("Product information registers", `0x0140`).
  ///
  /// Read-only. Since version 1.15. Bit 8 remote input available. Bit 17 built-in user relay
  /// and registers `0x034F` and `0x034E` (Smart models). Bit 27 OpenPaygo token compatible
  /// (version 1.17 and later). Bit 28 device hibernation, device mode `0xFD` (Smart models).
  /// Bit 29 improved load current measurement and registers `0x2205`, `0x2206` and `0x2207`
  /// (Smart models, and small models from product revision 7).
  public static let capabilities = Register(0x0140, "capabilities", .un32)

  /// BLE capabilities bit field ("Product information registers", `0x0150`).
  ///
  /// Since version 1.17, Smart inverters only. Read it only; the write access is for internal
  /// purposes. Bit 0 supports switching the Bluetooth transceiver on and off (true from
  /// Bluetooth software 2.17). Bit 1 BLE mode off is permanent (false: it can be enabled again
  /// via VE.Direct). The heading of the document's bit table says `0x0160`; its register table
  /// says `0x0150`, which is used here.
  public static let bleCapabilities = Register(0x0150, "bleCapabilities", .un32)

  /// Nominal AC output voltage in volts ("Product information registers", `0x2202`).
  ///
  /// Read-only. Since version 1.10.
  public static let acOutputNominalVoltage = Register(
    0x2202, "acOutputNominalVoltage", .un8, unit: .volt)

  /// Nominal battery voltage in volts ("Product information registers", `0xEDEF`).
  ///
  /// Read-only. Since version 1.10.
  public static let batteryVoltage = Register(0xEDEF, "batteryVoltage", .un8, unit: .volt)

  // MARK: Generic device status

  /// Device state, without a unit ("Generic device status registers", `0x0201`).
  ///
  /// Read-only. 0 off: not inverting, and after a protection the inverter restarts by itself
  /// once the cause is solved. 1 low power: Eco load search active. 2 fault: not inverting
  /// because of a fatal protection, and an off-on cycle is needed. 9 inverting.
  public static let deviceState = Register(0x0201, "deviceState", .un8)

  /// Device off reason bit field ("Generic device status registers", `0x0207`).
  ///
  /// Read-only. Since version 1.17. Bit 0 no input power (also causes a battery alarm), 2 soft
  /// power button or software control (VE.Direct or Bluetooth), 3 hardware remote input
  /// connector, 4 internal reason (see the alarm reason), 5 PayGo: out of credit, token
  /// needed.
  public static let deviceOffReason = Register(0x0207, "deviceOffReason", .un32)

  /// Warning reason bit field ("Generic device status registers", `0x031C`).
  ///
  /// Read-only. Bit 0 low battery voltage, 1 high battery voltage, 5 low temperature, 6 high
  /// temperature, 8 overload, 9 poor DC connection (battery current ripple, or a hot DC
  /// terminal on the larger models), 10 low AC output voltage, 11 high AC output voltage
  /// (occurs when the AC output is connected to mains while the inverter is on).
  public static let warningReason = Register(0x031C, "warningReason", .un16)

  /// Alarm reason bit field ("Generic device status registers", `0x031E`).
  ///
  /// Read-only. The bits of the warning reason `0x031C`, but only the reason that made the
  /// inverter switch off is set.
  public static let alarmReason = Register(0x031E, "alarmReason", .un16)

  // MARK: Generic device control

  /// BLE mode, without a unit ("Generic device control registers", `0x0090`).
  ///
  /// Since version 1.17, Smart inverters only. 0 BLE off, 1 BLE on. Once off, the Bluetooth
  /// transceiver can be enabled again via VE.Direct only.
  public static let bleMode = Register(0x0090, "bleMode", .un8, isPersistent: true)

  /// Device mode, without a unit ("Generic device control registers", `0x0200`).
  ///
  /// 2 inverter on. 3 device on (since version 1.15; the response reads 2). 4 device off, with
  /// VE.Direct still enabled. 5 Eco mode. `0xFD` hibernate (since version 1.15, see capability
  /// bit 28): communication can then start only after the device sends a text frame, at least
  /// once per 30 seconds, or after the user button is pressed, and the device stays awake
  /// while a VE.Direct message arrives every 24 seconds. The document calls this register a
  /// user setting.
  public static let deviceMode = Register(0x0200, "deviceMode", .un8)

  /// Time of the last settings change as a Unix timestamp ("Generic device control registers",
  /// `0xEC41`).
  ///
  /// Since version 1.17. Default `0xFFFFFFFF`. External applications may read and write it;
  /// the inverter does not control it and it has no effect on operation. The document gives
  /// no unit.
  public static let settingsChanged = Register(0xEC41, "settingsChanged", .un32)

  // MARK: Inverter operation

  /// Lifetime operation time in seconds ("Inverter operation registers", `0x1040`).
  ///
  /// Read-only. Since version 1.17.
  public static let historyTime = Register(0x1040, "historyTime", .un32, unit: .second)

  /// Lifetime energy in kilovolt-ampere-hours ("Inverter operation registers", `0x1041`).
  ///
  /// Read-only. Since version 1.17.
  public static let historyEnergy = Register(
    0x1041, "historyEnergy", .un32, scale: 0.01, unit: .kilovoltAmpereHour)

  /// AC output current in amperes ("Inverter operation registers", `0x2201`).
  ///
  /// Read-only.
  public static let acOutputCurrent = Register(
    0x2201, "acOutputCurrent", .sn16, scale: 0.1, unit: .ampere)

  /// AC output voltage in volts ("Inverter operation registers", `0x2200`).
  ///
  /// Read-only.
  public static let acOutputVoltage = Register(
    0x2200, "acOutputVoltage", .sn16, scale: 0.01, unit: .volt)

  /// AC output apparent power in volt-amperes ("Inverter operation registers", `0x2205`).
  ///
  /// Read-only. Since version 1.15, see capability bit 29.
  public static let acOutputApparentPower = Register(
    0x2205, "acOutputApparentPower", .sn32, unit: .voltAmpere)

  /// Inverter current of the control loop in amperes ("Inverter operation registers",
  /// `0xEB4E`).
  ///
  /// Read-only. The document gives only the name VE_REG_INV_LOOP_GET_IINV.
  public static let inverterLoopCurrent = Register(
    0xEB4E, "inverterLoopCurrent", .sn16, scale: 0.001, unit: .ampere)

  /// Battery voltage (DC channel 1) in volts ("Inverter operation registers", `0xED8D`).
  ///
  /// Read-only.
  public static let dcVoltage = Register(0xED8D, "dcVoltage", .sn16, scale: 0.01, unit: .volt)

  // MARK: User AC-out control

  /// AC output voltage set-point in volts ("User AC-out control registers", `0x0230`).
  ///
  /// A value outside `0x0231` to `0x0232` is clamped to those limits.
  public static let acOutputVoltageSetPoint = Register(
    0x0230, "acOutputVoltageSetPoint", .un16, scale: 0.01, unit: .volt, isPersistent: true)

  /// Lowest allowed AC output voltage set-point in volts ("User AC-out control registers",
  /// `0x0231`).
  ///
  /// Read-only.
  public static let acOutputVoltageSetPointMinimum = Register(
    0x0231, "acOutputVoltageSetPointMinimum", .un16, scale: 0.01, unit: .volt)

  /// Highest allowed AC output voltage set-point in volts ("User AC-out control registers",
  /// `0x0232`).
  ///
  /// Read-only.
  public static let acOutputVoltageSetPointMaximum = Register(
    0x0232, "acOutputVoltageSetPointMaximum", .un16, scale: 0.01, unit: .volt)

  /// Apparent power below which Eco load search becomes active, in volt-amperes ("User AC-out
  /// control registers", `0x2206`).
  ///
  /// Since version 1.15, see capability bit 29; replaces `0xEB04`. Smart inverters and
  /// VE.Direct inverters from product revision 7.
  public static let loadSensePowerThreshold = Register(
    0x2206, "loadSensePowerThreshold", .un16, unit: .voltAmpere, isPersistent: true)

  /// Apparent power above which Eco load search ends, in volt-amperes ("User AC-out control
  /// registers", `0x2207`).
  ///
  /// Since version 1.15, see capability bit 29. Typically set higher than `0x2206` to prevent
  /// continuous switching.
  public static let loadSensePowerClear = Register(
    0x2207, "loadSensePowerClear", .un16, unit: .voltAmpere, isPersistent: true)

  /// AC output frequency selection, without a unit ("User AC-out control registers", `0xEB03`).
  ///
  /// 0 is 60 Hz, 1 is 50 Hz. A change takes effect only after NvmSave (`0xEB99`).
  public static let acOutputFrequencyIs50Hz = Register(
    0xEB03, "acOutputFrequencyIs50Hz", .un8, isPersistent: true)

  /// Eco search threshold as an AC current in amperes ("User AC-out control registers",
  /// `0xEB04`).
  ///
  /// Only for versions 1.00 to 1.14; later replaced by `0x2206` and `0x2207`.
  public static let ecoModeMinimumCurrent = Register(
    0xEB04, "ecoModeMinimumCurrent", .sn16, scale: 0.001, unit: .ampere, isPersistent: true)

  /// Interval between the power test bursts of Eco load search, in seconds ("User AC-out
  /// control registers", `0xEB06`).
  public static let ecoModeRetryTime = Register(
    0xEB06, "ecoModeRetryTime", .un8, scale: 0.25, unit: .second, isPersistent: true)

  /// Duration of an Eco load search power test burst, in periods of the AC output frequency
  /// ("User AC-out control registers", `0xEB10`).
  ///
  /// Since version 1.17. The document gives the scale as 0.02 s or 0.016 s per period, for
  /// 50 Hz and 60 Hz, so no single scale is set and the value is the number of periods.
  /// Loads that turn on with a delay, such as dimmable LED bulbs, may need more than the
  /// default.
  public static let ecoLoadDetectPeriods = Register(
    0xEB10, "ecoLoadDetectPeriods", .un8, isPersistent: true)

  // MARK: User battery control

  /// Low battery voltage shutdown threshold in volts ("User battery control registers",
  /// `0x2210`).
  ///
  /// Clamped to `0x2211` to `0x2212`.
  public static let shutdownLowVoltage = Register(
    0x2210, "shutdownLowVoltage", .un16, scale: 0.01, unit: .volt, isPersistent: true)

  /// Low battery warning threshold in volts ("User battery control registers", `0x0320`).
  ///
  /// Below this level the inverter also does not start after a shutdown. Clamped to `0x2211`
  /// to `0x2212`.
  public static let alarmLowVoltage = Register(
    0x0320, "alarmLowVoltage", .un16, scale: 0.01, unit: .volt, isPersistent: true)

  /// Charge detect threshold in volts ("User battery control registers", `0x0321`).
  ///
  /// After a long-term low voltage shutdown the alarm clears and the inverter restarts when
  /// the battery voltage exceeds this level.
  public static let alarmLowVoltageClear = Register(
    0x0321, "alarmLowVoltageClear", .un16, scale: 0.01, unit: .volt, isPersistent: true)

  /// Lower limit of the battery threshold settings in volts ("User battery control registers",
  /// `0x2211`).
  ///
  /// Read-only.
  public static let voltageRangeMinimum = Register(
    0x2211, "voltageRangeMinimum", .un16, scale: 0.01, unit: .volt)

  /// Upper limit of the battery threshold settings in volts ("User battery control registers",
  /// `0x2212`).
  ///
  /// Read-only.
  public static let voltageRangeMaximum = Register(
    0x2212, "voltageRangeMaximum", .un16, scale: 0.01, unit: .volt)

  /// Dynamic cut-off switch, without a unit ("User battery control registers", `0xEBBA`).
  ///
  /// Since version 1.03. 0 disabled: the shutdown threshold is `0x2210`. 1 enabled: the
  /// threshold is a function of the AC output current, read from `0xEBB1`, and overrules
  /// `0x2210` and `0x0320`.
  public static let dynamicCutoffEnabled = Register(
    0xEBBA, "dynamicCutoffEnabled", .un8, isPersistent: true)

  /// Dynamic cut-off factor, without a unit ("User battery control registers", `0xEBB7`).
  ///
  /// Since version 1.03. The document gives no scale, unit or meaning beyond the name
  /// VE_REG_INV_PROT_UBAT_DYN_CUTOFF_FACTOR.
  public static let dynamicCutoffFactor = Register(
    0xEBB7, "dynamicCutoffFactor", .un16, isPersistent: true)

  /// Dynamic cut-off factor "2000", without a unit ("User battery control registers",
  /// `0xEBB5`).
  ///
  /// Since version 1.03. The document gives only the name
  /// VE_REG_INV_PROT_UBAT_DYN_CUTOFF_FACTOR2000.
  public static let dynamicCutoffFactor2000 = Register(
    0xEBB5, "dynamicCutoffFactor2000", .un16, isPersistent: true)

  /// Dynamic cut-off factor "250", without a unit ("User battery control registers",
  /// `0xEBB3`).
  ///
  /// Since version 1.03. The document gives only the name
  /// VE_REG_INV_PROT_UBAT_DYN_CUTOFF_FACTOR250.
  public static let dynamicCutoffFactor250 = Register(
    0xEBB3, "dynamicCutoffFactor250", .un16, isPersistent: true)

  /// Dynamic cut-off factor "5", without a unit ("User battery control registers", `0xEBB2`).
  ///
  /// Since version 1.03. The document gives only the name
  /// VE_REG_INV_PROT_UBAT_DYN_CUTOFF_FACTOR5.
  public static let dynamicCutoffFactor5 = Register(
    0xEBB2, "dynamicCutoffFactor5", .un16, isPersistent: true)

  /// Effective dynamic cut-off voltage in volts ("User battery control registers", `0xEBB1`).
  ///
  /// Read-only. Since version 1.03. The actual shutdown threshold while dynamic cut-off is
  /// enabled.
  public static let dynamicCutoffVoltage = Register(
    0xEBB1, "dynamicCutoffVoltage", .un16, scale: 0.001, unit: .volt)

  // MARK: Relay control

  /// Relay control and status, without a unit ("Relay control registers", `0x034E`).
  ///
  /// Since version 1.15, see capability bit 17. 0 off (NO open, NC closed), 1 on (NO closed,
  /// NC open). A read always gives the current state. A write controls the relay only in the
  /// remote relay mode and is ignored otherwise.
  public static let relayControl = Register(0x034E, "relayControl", .un8, isPersistent: true)

  /// Relay mode, without a unit ("Relay control registers", `0x034F`).
  ///
  /// Since version 1.15, see capability bit 17. 4 normal operation (default): on during normal
  /// operation, warnings ignored. 0 warnings and alarms: off when one is active. 5 battery
  /// low: off when a low battery warning or alarm is active. 6 external fan: on when the
  /// internal fan is on. 3 disabled: always off. 2 remote: controlled by writing `0x034E`.
  public static let relayMode = Register(0x034F, "relayMode", .un8, isPersistent: true)

  // MARK: Table

  /// Every register of the family, in the order of the document.
  public static let registers: [Register] = [
    nonVolatileMemoryCommand, restoreDefaults,
    productID, productRevision, applicationVersion, serialNumber, modelName,
    acOutputRatedPower, capabilities, bleCapabilities, acOutputNominalVoltage, batteryVoltage,
    deviceState, deviceOffReason, warningReason, alarmReason,
    bleMode, deviceMode, settingsChanged,
    historyTime, historyEnergy, acOutputCurrent, acOutputVoltage, acOutputApparentPower,
    inverterLoopCurrent, dcVoltage,
    acOutputVoltageSetPoint, acOutputVoltageSetPointMinimum, acOutputVoltageSetPointMaximum,
    loadSensePowerThreshold, loadSensePowerClear, acOutputFrequencyIs50Hz,
    ecoModeMinimumCurrent, ecoModeRetryTime, ecoLoadDetectPeriods,
    shutdownLowVoltage, alarmLowVoltage, alarmLowVoltageClear, voltageRangeMinimum,
    voltageRangeMaximum, dynamicCutoffEnabled, dynamicCutoffFactor, dynamicCutoffFactor2000,
    dynamicCutoffFactor250, dynamicCutoffFactor5, dynamicCutoffVoltage,
    relayControl, relayMode,
  ]
}
