# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

- `swift-vedirect`: a pure-Swift library for Victron's VE.Direct serial protocol, text mode and HEX mode.
- Package name `swift-vedirect`; library product and module `VEDirect`.
- Its first user is a downstream service that pins it by release tag with `exact:`.
- Devices it must support first: BMV-712 Smart (PID `0xA381`, Rev2 `0xA383`), SmartSolar MPPT 100/50 (`0xA057`), Orion XS 12V/12V-50A (`0xA3F0`).
- The library is a codec and a protocol state machine only: bytes in, typed values out, typed commands in, bytes out.
- Never open a serial port, read a file, sleep, log or start a task in the library; the caller owns all I/O and time.
- No package dependencies and no Foundation import in the library target.
- Never use an Apple-only API; the target is Linux arm64.
- The project is MIT-licensed, © NathanDigital (`LICENSE`); the capture fixtures keep their own MIT notice beside them.

## Structure

- `Sources/VEDirect/Framing/`: `FrameParser`, the one state machine for text blocks and HEX frames, and `HexFrame`.
- `Sources/VEDirect/Text/`: `TextBlock`, its typed fields and the text enumerations.
- `Sources/VEDirect/Hex/`: `HexCommand`, `HexResponse`, `Register`, `RegisterValue` and `FirmwareVersion`.
- `Sources/VEDirect/Tables/`: the product table and one register table per family (`MPPT`, `BMV`, `OrionXS`, `PhoenixInverter`).
- `docs/architecture.md` records the design decisions, `docs/sources.md` the documents and their ambiguities, `docs/testing.md` the fixtures and verification status.
- `VEDirectError` is the one error type; framing faults are reported as `FrameEvent.discarded`, everything else is thrown.

## Commands

- Build image: `docker build -t swift-vedirect-build:swift-6.4.2 docker`
- Build: `docker run --rm -v "$PWD":/src -w /src swift-vedirect-build:swift-6.4.2 swift build`
- Test: `docker run --rm -v "$PWD":/src -w /src swift-vedirect-build:swift-6.4.2 swift test`
- One test: append `--filter <SuiteOrTestName>` to the test command.
- Lint: `docker run --rm -v "$PWD":/src -w /src swift-vedirect-build:swift-6.4.2 swift format lint -s -r Sources Tests Package.swift`
- Every build, test and lint runs in the container; never use the host's `swift` or Xcode.

## Toolchain

- Swift 6.4.2 from `docker/Dockerfile`; `docker/` is a copy of the downstream service's build image and must stay identical to it apart from the opening comment.
- Never change the base image digest, Swift version or signing key here; change them in the downstream service's repository and copy the directory again.
- `Package.swift` starts with `// swift-tools-version: 6.4` and sets `swiftLanguageModes: [.v6]`.
- Commit `Package.resolved` if a test-only dependency is ever added.

## Safety settings

- Every target, tests included, has these `swiftSettings`; never remove or weaken one.
- `.strictMemorySafety()`
- `.treatAllWarnings(as: .error)`
- `.enableUpcomingFeature("ExistentialAny")`
- `.enableUpcomingFeature("InternalImportsByDefault")`
- `.enableUpcomingFeature("MemberImportVisibility")`
- `.enableUpcomingFeature("NonisolatedNonsendingByDefault")`
- `.enableUpcomingFeature("InferIsolatedConformances")`
- `.enableUpcomingFeature("ImmutableWeakCaptures")`
- Never use `unsafeFlags`, an experimental feature, or a `-suppress-warnings` style flag.

## Safety rules

- Never write `unsafe`, `@unsafe`, `@unchecked Sendable`, `nonisolated(unsafe)`, `@preconcurrency` or any `Unsafe*Pointer` type.
- Never write `!` force unwrap, `try!`, `as!`, an implicitly unwrapped optional or `unowned`.
- Never call `fatalError`, `precondition`, `assert` or an unchecked subscript on a value derived from received bytes.
- No sequence of input bytes may trap, allocate without bound or leave the parser unable to recover.
- Every buffer has a fixed maximum; input past it discards the current frame and resynchronises.
- Use `Span` and `RawSpan` for borrowed bytes, never pointers.
- Use checked arithmetic everywhere except checksums, which use `&+` and `&-` explicitly.
- Convert integers with `init(exactly:)` or `init(truncatingIfNeeded:)`, never a bare `init(_:)` on received data.
- Every public type is `Sendable`; prefer structs and enums, and use no class and no global mutable state.
- Decoding errors are typed throws of the library's own error enums; never return `nil` or `false` for a malformed frame.
- An unknown enumeration value, register, label or product ID decodes to its raw value and never fails.
- Mark every public enum that may grow as non-exhaustive by wrapping its raw value in a struct.

## Protocol sources

- Victron's documents are the only source of protocol fact; never take a register, scale or field from another project without checking it there.
- Text mode: <https://www.victronenergy.com/upload/documents/VE.Direct-Protocol-3.34.pdf>
- MPPT HEX: <https://www.victronenergy.com/upload/documents/BlueSolar-HEX-protocol.pdf>
- Orion XS HEX: <https://www.victronenergy.com/upload/documents/Orion-XS-HEX-protocol.pdf>
- BMV HEX: <https://www.victronenergy.com/upload/documents/BMV-7xx-HEX-Protocol.pdf>
- FAQ and reference frame handler: <https://www.victronenergy.com/live/vedirect_protocol:faq>
- Record each document's revision and retrieval date in `docs/sources.md` and name the document and table in the doc comment of every register and field.

## Reference projects

- Design guidance only; this is not a port of any of them.
- `krahabb/esphome-victron-vedirect` (MIT): one state machine for text and HEX on the same stream.
- `koestler/go-victron` (MIT): typed register tables, product table, retry on stale responses.
- `jordens/vedirect` (MIT or Apache-2.0): how small the core can be.
- `karioja/vedirect` (MIT): real captures in `test/*.dump`; copy them as fixtures with its licence notice.
- Never read code into this repository from `hoylabs/OpenDTU-OnBattery` (GPL-2.0), `davidcliddell/vehex` or `bencevans/ve.direct` (no licence).
- Read a text file with `gh api repos/<owner>/<repo>/contents/<path> --jq .content | base64 -d`.
- Fetch a binary file through `git/blobs/<sha>`; the `contents` endpoint re-encodes it and corrupts bytes above `0x7F` (see `docs/testing.md`).

## Text mode

- Serial settings are 19200 baud 8N1 with no flow control; document them, since the caller opens the port.
- A field is `<CR><LF><label><TAB><value>`; a block ends with the `Checksum` field.
- The sum modulo 256 of every byte in a block, from the first `<CR>` through the checksum byte, is 0.
- Buffer limits: label 9 bytes, value 33 bytes, 22 fields per block.
- Deliver a block only when its checksum is valid; otherwise discard it whole.
- A device may send several blocks with different fields; never assume one block holds every field.
- A `:` starts a HEX frame anywhere in the stream, except when it is the checksum byte.
- Keep the raw label and value of every field, including labels the library does not know.
- `---` means not available and decodes to `nil`.
- `TTG` of `-1` means infinite.
- Compare `ON` and `OFF` values case-insensitively.
- `FW` is a 16-bit version and `FWE` a 24-bit version.
- Typed values are in SI units as `Double`, with the unit in each property's doc comment; the wire units are mostly milli-units.
- Positive `I` means charging the battery.

## HEX mode

- A frame is `:<command nibble><bytes as two uppercase hex digits each><check>\n`, ended by LF and never CR.
- Command plus all data bytes plus the check byte sum to `0x55` modulo 256.
- Multi-byte numbers are little-endian.
- Commands: `1` ping, `3` app version, `4` product ID, `6` restart, `7` get, `8` set.
- Never provide an API that can send command `0`; it puts the device in its bootloader.
- Responses: `1` done, `2` checksum error (Orion XS), `3` unknown, `4` error, `5` ping, `7` get, `8` set, `A` asynchronous.
- Get and set responses carry flags: `0x01` unknown id, `0x02` not supported, `0x04` parameter error; surface them as typed errors.
- Asynchronous `:A` frames have the get-response layout and are never answered.
- Text blocks, HEX responses and `:A` frames arrive interleaved on one stream; one parser must emit all three.
- On older firmware text stops for a few seconds after a HEX frame; never treat missing text as a fault in the library.
- Match a response to its request by register id, and expose stale or unmatched responses to the caller instead of dropping them.

## Registers

- A register definition holds its id, name, value type, scale, unit, not-available value and whether it is stored in non-volatile memory.
- Never record register access; Victron's documents have no access column and the device answers a refused write with flag `0x02`.
- Register definitions are per product family in `Sources/VEDirect/Tables/`; the same id can differ in type, scale and meaning between families.
- Remote-control registers for the MPPT and Orion XS: `0x200E` network mode (un8), `0x2015` charge current limit (un16, 0.1 A), `0x2001` charge voltage set-point (un16, 0.01 V), `0x2002` voltage sense (un16, 0.01 V), `0x2003` temperature sense (sn16, 0.01 °C).
- External control mode is `0x200E` = `0x05`; the charger reverts to stand-alone after 60 seconds without a rewrite.
- Never offer a helper for BMS mode (`0x200E` = `0x09`); it permanently sets `0xEDE8` and the charger then stops with error 67 when data stops.
- Mark `0xEDxx` battery settings and every other user setting as persistent; `HexCommand.setPersistent` writes one and `HexCommand.set` refuses it.
- Orion XS registers come from the Orion XS document only; no reference project covers them.
- The library builds and decodes frames; the caller decides when to send and how often to repeat.

## Testing

- Use Swift Testing, never XCTest.
- Every example frame in Victron's documents is a test vector, named after its document.
- Test the `0x3A` checksum byte case, a HEX frame inside a text block, a block split at every byte boundary, and a corrupted checksum.
- Test that arbitrary and truncated byte sequences never trap and that the parser recovers on the next valid frame.
- Test fixtures are real captures in `Tests/VEDirectTests/Fixtures/`, each with its device, firmware version and origin recorded in `docs/testing.md`.
- Add each fixture to the test target's `resources` with `.embedInCode`; never import Foundation to load one.
- Encoding tests compare whole frames byte for byte, checksum included.
- Never mark a behaviour verified until it has run against a capture from the real device.

## Conventions

- Follow the Swift API Design Guidelines; name by meaning, not by wire label.
- Every public declaration has a `///` comment starting with a one-sentence summary.
- Documentation for people working on the library goes in `/docs`; `README.md` is for people using it. Never add other top-level Markdown files.
- Keep the code in `README.md` compiling; check it against the current API when a public name changes.
- Update this file when the structure or a rule changes.
