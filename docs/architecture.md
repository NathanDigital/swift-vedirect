# Architecture

`VEDirect` is one module with no dependencies and no Foundation import. It is a codec and a state
machine: the caller owns the serial port, time and retries.

## Layers

| Layer | Folder | Types | Job |
|---|---|---|---|
| Framing | `Framing/` | `FrameParser`, `FrameEvent`, `HexFrame` | Bytes in; validated text blocks, HEX frames and discard reasons out |
| Text | `Text/` | `TextBlock`, `TextField`, the enumeration types | Raw label and value kept; typed readings in documented units |
| HEX | `Hex/` | `HexCommand`, `HexResponse`, `RegisterReply`, `Register`, `RegisterValue`, `FirmwareVersion` | Builds commands; interprets responses; decodes and encodes register values |
| Tables | `Tables/` | `ProductID`, `Product`, `ProductFamily`, `MPPT`, `BMV`, `OrionXS`, `PhoenixInverter` | Product table and one register table per family |

Framing knows nothing about devices. A new product family is a new table file.

## Use

```swift
var parser = FrameParser()
for byte in received {
  switch parser.consume(byte) {
  case .textBlock(let block)?:
    let volts = try block.mainVoltage            // Double?, volts
  case .hexFrame(let frame)?:
    if case .get(let reply) = try HexResponse(frame), reply.id == OrionXS.batteryMaximumCurrent.id {
      let value = try reply.decoded(as: OrionXS.batteryMaximumCurrent)
    }
  case .discarded(let reason)?:
    break                                        // a VEDirectError
  case nil:
    break
  }
}
let bytes = HexCommand.get(OrionXS.batteryMaximumCurrent).encoded()
```

## Decisions

- **One byte in, at most one event out.** `consume(_:)` returns the block or frame a byte
  completed. A dropped block or frame is reported once, at its end.
- **Bounded buffers.** Label, value, field count and HEX length each have a fixed maximum; input
  past a maximum marks the block or frame as discarded and is not stored.
- **A HEX frame may interrupt a text block.** The parser keeps the text state, leaves the HEX bytes
  out of the text checksum and resumes the block afterwards.
- **A colon is the checksum byte only in the checksum position;** anywhere else it starts a HEX
  frame.
- **Wire values are raw-value structs.** Product ids, register ids, states, error codes and bit
  fields keep unknown values. `VEDirectError` is the one error type and is `@nonexhaustive`.
- **Register definitions are per family.** Ids are one Victron-wide namespace, but type,
  signedness, scale and meaning differ between families.
- **Integers decode at the width received.** Some registers changed width between firmware
  versions; the definition's width is used only for writing.
- **Two kinds of write.** `HexCommand.set` refuses a persistent setting and
  `HexCommand.setPersistent` refuses a run-time register. `setRaw` writes bytes to any id.
- **No command `0`.** `HexFrame` and `HexCommand` have no public way to build it.
- **Responses are matched by register id.** Every get, set and asynchronous response carries its
  id; the caller compares it with the request and decides what a mismatch means.
- **Multi-field records decode to bytes.** History records and similar structures are returned as
  `.bytes`, with their layout in the register's doc comment.
