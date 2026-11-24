/// The state of operation of a charger or inverter (text label `CS`, HEX register `0x0201`).
///
/// Source: "VE.Direct Protocol" rev 3.34, "Detailed field description", table for `CS`. Load
/// detect, blocked and unavailable are from the tables for registers `0x0201` and `0x200C` in
/// "VE.Direct Protocol – BlueSolar and SmartSolar MPPT chargers" Rev 18.
public struct OperationState: RawRepresentable, Hashable, Sendable {
  /// The value on the wire.
  public let rawValue: UInt8

  /// Creates a state from its wire value; unknown values are kept as they are.
  public init(rawValue: UInt8) { self.rawValue = rawValue }

  /// Off.
  public static let off = OperationState(rawValue: 0)
  /// Low power, also called load search (inverters).
  public static let lowPower = OperationState(rawValue: 1)
  /// Fault; the error code says why.
  public static let fault = OperationState(rawValue: 2)
  /// Bulk charging.
  public static let bulk = OperationState(rawValue: 3)
  /// Absorption charging.
  public static let absorption = OperationState(rawValue: 4)
  /// Float charging.
  public static let float = OperationState(rawValue: 5)
  /// Storage (chargers).
  public static let storage = OperationState(rawValue: 6)
  /// Manual equalisation.
  public static let manualEqualize = OperationState(rawValue: 7)
  /// Inverting.
  public static let inverting = OperationState(rawValue: 9)
  /// Power supply mode (chargers).
  public static let powerSupply = OperationState(rawValue: 11)
  /// Starting up.
  public static let startingUp = OperationState(rawValue: 245)
  /// Repeated absorption (chargers).
  public static let repeatedAbsorption = OperationState(rawValue: 246)
  /// Automatic equalisation or recondition.
  public static let autoEqualize = OperationState(rawValue: 247)
  /// BatterySafe (chargers).
  public static let batterySafe = OperationState(rawValue: 248)
  /// Load detect (reported over a network link only).
  public static let loadDetect = OperationState(rawValue: 249)
  /// Blocked.
  public static let blocked = OperationState(rawValue: 250)
  /// External control: another device sets the charge voltage or current.
  public static let externalControl = OperationState(rawValue: 252)
  /// The state is not available.
  public static let unavailable = OperationState(rawValue: 255)
}

/// The error code of a charger (text label `ERR`, HEX register `0xEDDA`).
///
/// Source: "VE.Direct Protocol" rev 3.34, "Detailed field description", table for `ERR`. Codes
/// 14, 27 and 29 are from the table for register `0xEDDA` in "VE.Direct Protocol – BlueSolar and
/// SmartSolar MPPT chargers" Rev 18, which also lists sensor faults as the ranges 3 to 8 and 22
/// to 23. The Orion XS document defines further codes for that product.
public struct ChargerError: RawRepresentable, Hashable, Sendable {
  /// The value on the wire.
  public let rawValue: UInt8

  /// Creates an error code from its wire value; unknown values are kept as they are.
  public init(rawValue: UInt8) { self.rawValue = rawValue }

  /// No error.
  public static let none = ChargerError(rawValue: 0)
  /// Battery voltage too high.
  public static let batteryVoltageTooHigh = ChargerError(rawValue: 2)
  /// Battery temperature too low; charging is not allowed.
  public static let batteryTemperatureTooLow = ChargerError(rawValue: 14)
  /// Charger temperature too high.
  public static let chargerTemperatureTooHigh = ChargerError(rawValue: 17)
  /// Charger over current.
  public static let chargerOverCurrent = ChargerError(rawValue: 18)
  /// Charger current reversed.
  public static let chargerCurrentReversed = ChargerError(rawValue: 19)
  /// Bulk time limit exceeded.
  public static let bulkTimeLimitExceeded = ChargerError(rawValue: 20)
  /// Current sensor issue (sensor bias or sensor broken).
  public static let currentSensorIssue = ChargerError(rawValue: 21)
  /// Terminals overheated.
  public static let terminalsOverheated = ChargerError(rawValue: 26)
  /// Charger short circuit.
  public static let chargerShortCircuit = ChargerError(rawValue: 27)
  /// Converter issue (dual converter models only).
  public static let converterIssue = ChargerError(rawValue: 28)
  /// Battery over-charge protection.
  public static let batteryOverChargeProtection = ChargerError(rawValue: 29)
  /// Input voltage too high (solar panel).
  public static let inputVoltageTooHigh = ChargerError(rawValue: 33)
  /// Input current too high (solar panel).
  public static let inputCurrentTooHigh = ChargerError(rawValue: 34)
  /// Input shutdown due to excessive battery voltage.
  public static let inputShutdownBatteryVoltage = ChargerError(rawValue: 38)
  /// Input shutdown due to current flow during off mode.
  public static let inputShutdownCurrentFlow = ChargerError(rawValue: 39)
  /// Lost communication with one of the devices.
  public static let lostCommunication = ChargerError(rawValue: 65)
  /// Synchronised charging device configuration issue.
  public static let synchronisedChargingConfiguration = ChargerError(rawValue: 66)
  /// BMS connection lost.
  public static let bmsConnectionLost = ChargerError(rawValue: 67)
  /// Network misconfigured.
  public static let networkMisconfigured = ChargerError(rawValue: 68)
  /// Factory calibration data lost.
  public static let factoryCalibrationLost = ChargerError(rawValue: 116)
  /// Invalid or incompatible firmware.
  public static let invalidFirmware = ChargerError(rawValue: 117)
  /// User settings invalid.
  public static let userSettingsInvalid = ChargerError(rawValue: 119)
}

/// The reasons a device is switched off (text label `OR`, HEX register `0x0207`).
///
/// Source: "VE.Direct Protocol" rev 3.34, "Detailed field description", table for `OR`.
public struct OffReason: OptionSet, Hashable, Sendable {
  /// The bits on the wire.
  public let rawValue: UInt32

  /// Creates a set of reasons from its wire bits; unknown bits are kept.
  public init(rawValue: UInt32) { self.rawValue = rawValue }

  /// No input power.
  public static let noInputPower = OffReason(rawValue: 0x0000_0001)
  /// Switched off by the power switch.
  public static let powerSwitch = OffReason(rawValue: 0x0000_0002)
  /// Switched off by the device mode register.
  public static let deviceModeRegister = OffReason(rawValue: 0x0000_0004)
  /// Remote input.
  public static let remoteInput = OffReason(rawValue: 0x0000_0008)
  /// Protection active.
  public static let protectionActive = OffReason(rawValue: 0x0000_0010)
  /// Paygo.
  public static let paygo = OffReason(rawValue: 0x0000_0020)
  /// BMS.
  public static let bms = OffReason(rawValue: 0x0000_0040)
  /// Engine shutdown detection.
  public static let engineShutdownDetection = OffReason(rawValue: 0x0000_0080)
  /// Analysing input voltage.
  public static let analysingInputVoltage = OffReason(rawValue: 0x0000_0100)
}

/// The conditions behind an alarm or warning (text labels `AR` and `WARN`).
///
/// Source: "VE.Direct Protocol" rev 3.34, "Detailed field description", table for `AR`.
public struct AlarmReason: OptionSet, Hashable, Sendable {
  /// The bits on the wire.
  public let rawValue: UInt16

  /// Creates a set of conditions from its wire bits; unknown bits are kept.
  public init(rawValue: UInt16) { self.rawValue = rawValue }

  /// Low voltage.
  public static let lowVoltage = AlarmReason(rawValue: 1)
  /// High voltage.
  public static let highVoltage = AlarmReason(rawValue: 2)
  /// Low state of charge.
  public static let lowStateOfCharge = AlarmReason(rawValue: 4)
  /// Low starter voltage.
  public static let lowStarterVoltage = AlarmReason(rawValue: 8)
  /// High starter voltage.
  public static let highStarterVoltage = AlarmReason(rawValue: 16)
  /// Low temperature.
  public static let lowTemperature = AlarmReason(rawValue: 32)
  /// High temperature.
  public static let highTemperature = AlarmReason(rawValue: 64)
  /// Mid-point voltage.
  public static let midVoltage = AlarmReason(rawValue: 128)
  /// Overload.
  public static let overload = AlarmReason(rawValue: 256)
  /// DC ripple.
  public static let dcRipple = AlarmReason(rawValue: 512)
  /// Low AC output voltage.
  public static let lowACOutputVoltage = AlarmReason(rawValue: 1024)
  /// High AC output voltage.
  public static let highACOutputVoltage = AlarmReason(rawValue: 2048)
  /// Short circuit.
  public static let shortCircuit = AlarmReason(rawValue: 4096)
  /// BMS lockout.
  public static let bmsLockout = AlarmReason(rawValue: 8192)
}

/// The mode a device is set to (text label `MODE`, HEX register `0x0200`).
///
/// Source: "VE.Direct Protocol" rev 3.34, "Detailed field description", table for `MODE`. On is
/// from the table for register `0x0200` in "VE.Direct Protocol – Phoenix Inverters" Rev 5.
public struct DeviceMode: RawRepresentable, Hashable, Sendable {
  /// The value on the wire.
  public let rawValue: UInt8

  /// Creates a mode from its wire value; unknown values are kept as they are.
  public init(rawValue: UInt8) { self.rawValue = rawValue }

  /// Charger.
  public static let charger = DeviceMode(rawValue: 1)
  /// Inverter.
  public static let inverter = DeviceMode(rawValue: 2)
  /// On.
  public static let on = DeviceMode(rawValue: 3)
  /// Off.
  public static let off = DeviceMode(rawValue: 4)
  /// Eco.
  public static let eco = DeviceMode(rawValue: 5)
  /// Hibernate (Smart inverters only).
  public static let hibernate = DeviceMode(rawValue: 253)
}

/// The tracker operation mode of a solar charger (text label `MPPT`).
///
/// Source: "VE.Direct Protocol" rev 3.34, "Detailed field description", table for `MPPT`.
public struct TrackerMode: RawRepresentable, Hashable, Sendable {
  /// The value on the wire.
  public let rawValue: UInt8

  /// Creates a mode from its wire value; unknown values are kept as they are.
  public init(rawValue: UInt8) { self.rawValue = rawValue }

  /// Off.
  public static let off = TrackerMode(rawValue: 0)
  /// Voltage or current limited.
  public static let limited = TrackerMode(rawValue: 1)
  /// Maximum power point tracker active.
  public static let tracking = TrackerMode(rawValue: 2)
}

/// What a battery monitor is set to measure (text label `MON`, HEX register `0xEEB8`).
///
/// Negative values are sources and positive values are loads.
///
/// Source: "VE.Direct Protocol" rev 3.34, "Detailed field description", table for `MON`.
public struct MonitorMode: RawRepresentable, Hashable, Sendable {
  /// The value on the wire.
  public let rawValue: Int16

  /// Creates a mode from its wire value; unknown values are kept as they are.
  public init(rawValue: Int16) { self.rawValue = rawValue }

  /// Solar charger.
  public static let solarCharger = MonitorMode(rawValue: -9)
  /// Wind turbine.
  public static let windTurbine = MonitorMode(rawValue: -8)
  /// Shaft generator.
  public static let shaftGenerator = MonitorMode(rawValue: -7)
  /// Alternator.
  public static let alternator = MonitorMode(rawValue: -6)
  /// Fuel cell.
  public static let fuelCell = MonitorMode(rawValue: -5)
  /// Water generator.
  public static let waterGenerator = MonitorMode(rawValue: -4)
  /// DC/DC charger.
  public static let dcDCCharger = MonitorMode(rawValue: -3)
  /// AC charger.
  public static let acCharger = MonitorMode(rawValue: -2)
  /// Generic source.
  public static let genericSource = MonitorMode(rawValue: -1)
  /// Battery monitor.
  public static let batteryMonitor = MonitorMode(rawValue: 0)
  /// Generic load.
  public static let genericLoad = MonitorMode(rawValue: 1)
  /// Electric drive.
  public static let electricDrive = MonitorMode(rawValue: 2)
  /// Fridge.
  public static let fridge = MonitorMode(rawValue: 3)
  /// Water pump.
  public static let waterPump = MonitorMode(rawValue: 4)
  /// Bilge pump.
  public static let bilgePump = MonitorMode(rawValue: 5)
  /// DC system.
  public static let dcSystem = MonitorMode(rawValue: 6)
  /// Inverter.
  public static let inverter = MonitorMode(rawValue: 7)
  /// Water heater.
  public static let waterHeater = MonitorMode(rawValue: 8)
}

/// What a device's Bluetooth interface supports (text label `CAP_BLE`, HEX register `0x0150`).
///
/// Source: "VE.Direct Protocol" rev 3.34, "Detailed field description", table for `CAP_BLE`.
public struct BluetoothCapabilities: OptionSet, Hashable, Sendable {
  /// The bits on the wire.
  public let rawValue: UInt32

  /// Creates a set of capabilities from its wire bits; unknown bits are kept.
  public init(rawValue: UInt32) { self.rawValue = rawValue }

  /// Bluetooth can be switched off.
  public static let supportsSwitchingOff = BluetoothCapabilities(rawValue: 0x0000_0001)
  /// Switching Bluetooth off is permanent.
  public static let switchingOffIsPermanent = BluetoothCapabilities(rawValue: 0x0000_0002)
}
