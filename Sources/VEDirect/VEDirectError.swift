/// Every way the library can reject received bytes or refuse to build a frame.
///
/// Framing faults are reported through ``FrameEvent/discarded(_:)``; the other cases are thrown.
@nonexhaustive
public enum VEDirectError: Error, Sendable, Equatable {
  /// A text block's bytes did not sum to zero modulo 256.
  case textChecksumMismatch
  /// A text label was longer than ``FrameParser/maximumLabelLength``.
  case labelTooLong
  /// A text value was longer than ``FrameParser/maximumValueLength``.
  case valueTooLong
  /// A text block held more fields than ``FrameParser/maximumFieldCount``.
  case tooManyFields
  /// A text line ended before its tab separator.
  case malformedField

  /// A HEX frame's command and bytes did not sum to `0x55` modulo 256.
  case hexChecksumMismatch
  /// A HEX frame held a byte that is not an uppercase hexadecimal digit.
  case hexInvalidDigit
  /// A HEX frame held more bytes than ``FrameParser/maximumHexLength``.
  case hexTooLong
  /// A HEX frame ended without a command, without a check byte or on half a byte.
  case hexIncomplete

  /// A text field's value could not be read as the type its label requires.
  case malformedValue(label: String)

  /// A HEX response was shorter than its layout requires.
  case truncatedPayload
  /// The device answered that the register does not exist (flag `0x01`).
  case unknownRegister(RegisterID)
  /// The device answered that the register cannot be written (flag `0x02`).
  case notSupported(RegisterID)
  /// The device answered that the value was out of range or inconsistent (flag `0x04`).
  case parameterError(RegisterID)
  /// A register's value had a length its type cannot have.
  case unexpectedLength(RegisterID)

  /// The value's kind does not suit the register's type.
  case valueTypeMismatch(RegisterID)
  /// The value does not fit the register's width or is not finite.
  case valueOutOfRange(RegisterID)
  /// A persistent setting was passed to the run-time write call.
  case persistentRegister(RegisterID)
  /// A run-time register was passed to the persistent write call.
  case notPersistentRegister(RegisterID)
  /// The frame to send would be longer than ``FrameParser/maximumHexLength``.
  case payloadTooLong
}
