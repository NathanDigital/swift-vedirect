/// Typed readings of every label in Table I, "Supported Text-mode fields", of "VE.Direct
/// Protocol" rev 3.34, with the units from its "Detailed field description".
///
/// Each property is `nil` when the block does not hold the field or the device sent `---`, and
/// throws ``VEDirectError/malformedValue(label:)`` when the value cannot be read.
extension TextBlock {
  // MARK: Voltages, currents and power

  /// Main or channel 1 battery voltage in volts (`V`, sent in mV).
  public var mainVoltage: Double? { get throws(VEDirectError) { try scaled("V", by: 0.001) } }

  /// Channel 2 battery voltage in volts (`V2`, sent in mV).
  public var channel2Voltage: Double? { get throws(VEDirectError) { try scaled("V2", by: 0.001) } }

  /// Channel 3 battery voltage in volts (`V3`, sent in mV).
  public var channel3Voltage: Double? { get throws(VEDirectError) { try scaled("V3", by: 0.001) } }

  /// Auxiliary (starter) voltage in volts (`VS`, sent in mV).
  public var auxiliaryVoltage: Double? { get throws(VEDirectError) { try scaled("VS", by: 0.001) } }

  /// Mid-point voltage of the battery bank in volts (`VM`, sent in mV).
  public var midpointVoltage: Double? { get throws(VEDirectError) { try scaled("VM", by: 0.001) } }

  /// Mid-point deviation of the battery bank in percent (`DM`, sent in per mille).
  public var midpointDeviation: Double? { get throws(VEDirectError) { try scaled("DM", by: 0.1) } }

  /// Panel voltage in volts (`VPV`, sent in mV).
  public var panelVoltage: Double? { get throws(VEDirectError) { try scaled("VPV", by: 0.001) } }

  /// Panel power in watts (`PPV`).
  public var panelPower: Double? { get throws(VEDirectError) { try scaled("PPV", by: 1) } }

  /// Main or channel 1 battery current in amperes (`I`, sent in mA).
  ///
  /// Positive means the battery is being charged.
  public var current: Double? { get throws(VEDirectError) { try scaled("I", by: 0.001) } }

  /// Channel 2 battery current in amperes (`I2`, sent in mA).
  public var channel2Current: Double? { get throws(VEDirectError) { try scaled("I2", by: 0.001) } }

  /// Channel 3 battery current in amperes (`I3`, sent in mA).
  public var channel3Current: Double? { get throws(VEDirectError) { try scaled("I3", by: 0.001) } }

  /// Load current in amperes (`IL`, sent in mA).
  public var loadCurrent: Double? { get throws(VEDirectError) { try scaled("IL", by: 0.001) } }

  /// Whether the load output is on (`LOAD`).
  public var isLoadOutputOn: Bool? { get throws(VEDirectError) { try flag("LOAD") } }

  /// Battery temperature in degrees Celsius (`T`).
  public var batteryTemperature: Double? { get throws(VEDirectError) { try scaled("T", by: 1) } }

  /// Instantaneous power in watts (`P`).
  public var power: Double? { get throws(VEDirectError) { try scaled("P", by: 1) } }

  // MARK: Battery monitor

  /// Consumed charge in ampere-hours (`CE`, sent in mAh).
  public var consumedCharge: Double? { get throws(VEDirectError) { try scaled("CE", by: 0.001) } }

  /// State of charge in percent (`SOC`, sent in per mille).
  public var stateOfCharge: Double? { get throws(VEDirectError) { try scaled("SOC", by: 0.1) } }

  /// Time to go in seconds (`TTG`, sent in minutes); infinite when the battery is not discharging.
  public var timeToGo: Double? {
    get throws(VEDirectError) {
      guard let minutes = try integer("TTG") else { return nil }
      return minutes == -1 ? .infinity : Double(minutes) * 60
    }
  }

  /// Whether an alarm condition is active (`Alarm`).
  public var isAlarmActive: Bool? { get throws(VEDirectError) { try flag("Alarm") } }

  /// Whether the relay is on (`Relay`); what on means differs by device and setting.
  public var isRelayOn: Bool? { get throws(VEDirectError) { try flag("Relay") } }

  /// The reasons for the alarm (`AR`).
  public var alarmReason: AlarmReason? {
    get throws(VEDirectError) {
      try exactInteger("AR", as: UInt16.self).map { AlarmReason(rawValue: $0) }
    }
  }

  /// The reasons the device is off (`OR`).
  public var offReason: OffReason? {
    get throws(VEDirectError) {
      try exactInteger("OR", as: UInt32.self).map { OffReason(rawValue: $0) }
    }
  }

  /// The active warnings of an inverter (`WARN`).
  public var warningReason: AlarmReason? {
    get throws(VEDirectError) {
      try exactInteger("WARN", as: UInt16.self).map { AlarmReason(rawValue: $0) }
    }
  }

  /// What the battery monitor is set to measure (`MON`).
  public var monitorMode: MonitorMode? {
    get throws(VEDirectError) {
      try exactInteger("MON", as: Int16.self).map { MonitorMode(rawValue: $0) }
    }
  }

  // MARK: Battery monitor history

  /// Depth of the deepest discharge in ampere-hours (`H1`, sent in mAh).
  public var deepestDischarge: Double? { get throws(VEDirectError) { try scaled("H1", by: 0.001) } }

  /// Depth of the last discharge in ampere-hours (`H2`, sent in mAh).
  public var lastDischarge: Double? { get throws(VEDirectError) { try scaled("H2", by: 0.001) } }

  /// Depth of the average discharge in ampere-hours (`H3`, sent in mAh).
  public var averageDischarge: Double? { get throws(VEDirectError) { try scaled("H3", by: 0.001) } }

  /// Number of charge cycles (`H4`).
  public var chargeCycleCount: Int? { get throws(VEDirectError) { try count("H4") } }

  /// Number of full discharges (`H5`).
  public var fullDischargeCount: Int? { get throws(VEDirectError) { try count("H5") } }

  /// Cumulative charge drawn in ampere-hours (`H6`, sent in mAh).
  public var cumulativeChargeDrawn: Double? {
    get throws(VEDirectError) { try scaled("H6", by: 0.001) }
  }

  /// Minimum main battery voltage in volts (`H7`, sent in mV).
  public var minimumMainVoltage: Double? {
    get throws(VEDirectError) { try scaled("H7", by: 0.001) }
  }

  /// Maximum main battery voltage in volts (`H8`, sent in mV).
  public var maximumMainVoltage: Double? {
    get throws(VEDirectError) { try scaled("H8", by: 0.001) }
  }

  /// Time since the last full charge in seconds (`H9`).
  public var timeSinceFullCharge: Double? { get throws(VEDirectError) { try scaled("H9", by: 1) } }

  /// Number of automatic synchronisations (`H10`).
  public var automaticSynchronisationCount: Int? { get throws(VEDirectError) { try count("H10") } }

  /// Number of low main voltage alarms (`H11`).
  public var lowMainVoltageAlarmCount: Int? { get throws(VEDirectError) { try count("H11") } }

  /// Number of high main voltage alarms (`H12`).
  public var highMainVoltageAlarmCount: Int? { get throws(VEDirectError) { try count("H12") } }

  /// Number of low auxiliary voltage alarms (`H13`).
  public var lowAuxiliaryVoltageAlarmCount: Int? { get throws(VEDirectError) { try count("H13") } }

  /// Number of high auxiliary voltage alarms (`H14`).
  public var highAuxiliaryVoltageAlarmCount: Int? { get throws(VEDirectError) { try count("H14") } }

  /// Minimum auxiliary battery voltage in volts (`H15`, sent in mV).
  public var minimumAuxiliaryVoltage: Double? {
    get throws(VEDirectError) { try scaled("H15", by: 0.001) }
  }

  /// Maximum auxiliary battery voltage in volts (`H16`, sent in mV).
  public var maximumAuxiliaryVoltage: Double? {
    get throws(VEDirectError) { try scaled("H16", by: 0.001) }
  }

  /// Discharged energy in kilowatt-hours (`H17`, sent in 0.01 kWh); produced energy in DC monitor
  /// mode.
  public var dischargedEnergy: Double? { get throws(VEDirectError) { try scaled("H17", by: 0.01) } }

  /// Charged energy in kilowatt-hours (`H18`, sent in 0.01 kWh); consumed energy in DC monitor
  /// mode.
  public var chargedEnergy: Double? { get throws(VEDirectError) { try scaled("H18", by: 0.01) } }

  // MARK: Solar charger

  /// Total yield in kilowatt-hours (`H19`, sent in 0.01 kWh); the user can reset this counter.
  public var totalYield: Double? { get throws(VEDirectError) { try scaled("H19", by: 0.01) } }

  /// Yield today in kilowatt-hours (`H20`, sent in 0.01 kWh).
  public var yieldToday: Double? { get throws(VEDirectError) { try scaled("H20", by: 0.01) } }

  /// Maximum power today in watts (`H21`).
  public var maximumPowerToday: Double? { get throws(VEDirectError) { try scaled("H21", by: 1) } }

  /// Yield yesterday in kilowatt-hours (`H22`, sent in 0.01 kWh).
  public var yieldYesterday: Double? { get throws(VEDirectError) { try scaled("H22", by: 0.01) } }

  /// Maximum power yesterday in watts (`H23`).
  public var maximumPowerYesterday: Double? {
    get throws(VEDirectError) { try scaled("H23", by: 1) }
  }

  /// Day sequence number, `0` to `364` (`HSDS`); a change means a new day has started.
  public var daySequenceNumber: Int? { get throws(VEDirectError) { try count("HSDS") } }

  /// The tracker operation mode (`MPPT`).
  public var trackerMode: TrackerMode? {
    get throws(VEDirectError) {
      try exactInteger("MPPT", as: UInt8.self).map { TrackerMode(rawValue: $0) }
    }
  }

  // MARK: State

  /// The error code (`ERR`).
  public var chargerError: ChargerError? {
    get throws(VEDirectError) {
      try exactInteger("ERR", as: UInt8.self).map { ChargerError(rawValue: $0) }
    }
  }

  /// The state of operation (`CS`).
  public var operationState: OperationState? {
    get throws(VEDirectError) {
      try exactInteger("CS", as: UInt8.self).map { OperationState(rawValue: $0) }
    }
  }

  /// The device mode (`MODE`).
  public var deviceMode: DeviceMode? {
    get throws(VEDirectError) {
      try exactInteger("MODE", as: UInt8.self).map { DeviceMode(rawValue: $0) }
    }
  }

  // MARK: Inverter and DC input

  /// AC output voltage in volts (`AC_OUT_V`, sent in 0.01 V).
  public var acOutputVoltage: Double? {
    get throws(VEDirectError) { try scaled("AC_OUT_V", by: 0.01) }
  }

  /// AC output current in amperes (`AC_OUT_I`, sent in 0.1 A).
  public var acOutputCurrent: Double? {
    get throws(VEDirectError) { try scaled("AC_OUT_I", by: 0.1) }
  }

  /// AC output apparent power in volt-amperes (`AC_OUT_S`).
  public var acOutputApparentPower: Double? {
    get throws(VEDirectError) { try scaled("AC_OUT_S", by: 1) }
  }

  /// DC input voltage in volts (`DC_IN_V`, sent in 0.01 V).
  public var dcInputVoltage: Double? {
    get throws(VEDirectError) { try scaled("DC_IN_V", by: 0.01) }
  }

  /// DC input current in amperes (`DC_IN_I`, sent in 0.1 A).
  public var dcInputCurrent: Double? {
    get throws(VEDirectError) { try scaled("DC_IN_I", by: 0.1) }
  }

  /// DC input power in watts (`DC_IN_P`).
  public var dcInputPower: Double? { get throws(VEDirectError) { try scaled("DC_IN_P", by: 1) } }

  // MARK: Identity

  /// The product ID (`PID`).
  public var productID: ProductID? {
    get throws(VEDirectError) {
      try exactInteger("PID", as: UInt16.self).map { ProductID(rawValue: $0) }
    }
  }

  /// The 16-bit firmware version (`FW`).
  public var firmwareVersion: FirmwareVersion? {
    get throws(VEDirectError) {
      guard let field = self["FW"] else { return nil }
      return try FirmwareVersion(text: field.valueBytes)
    }
  }

  /// The 24-bit firmware version (`FWE`).
  public var extendedFirmwareVersion: FirmwareVersion? {
    get throws(VEDirectError) {
      guard let field = self["FWE"] else { return nil }
      return try FirmwareVersion(extendedText: field.valueBytes)
    }
  }

  /// The serial number (`SER#`).
  public var serialNumber: String? { text("SER#") }

  /// The model description of a BMV (`BMV`); Victron marks this field deprecated.
  public var modelDescription: String? { text("BMV") }

  /// What the Bluetooth interface supports (`CAP_BLE`).
  public var bluetoothCapabilities: BluetoothCapabilities? {
    get throws(VEDirectError) {
      try exactInteger("CAP_BLE", as: UInt32.self).map { BluetoothCapabilities(rawValue: $0) }
    }
  }
}
