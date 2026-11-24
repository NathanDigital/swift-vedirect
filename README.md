# swift-vedirect

[![CI](https://github.com/NathanDigital/swift-vedirect/actions/workflows/ci.yml/badge.svg)](https://github.com/NathanDigital/swift-vedirect/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A pure-Swift library for **[Victron Energy's VE.Direct serial protocol](https://www.victronenergy.com/live/vedirect_protocol:faq)**, in both text mode and HEX mode.

The library is a codec and a protocol state machine: bytes in, typed values out; typed commands in, bytes out. It opens no serial port and keeps no clock, so it works with whatever I/O you already have. All of the protocol knowledge comes from Victron's published documents, which are listed with their revisions in [docs/sources.md](docs/sources.md).

> **Status: in development.** The register tables are transcribed from Victron's documents and tested against the documents' own examples, and the text parser is tested against captures from three real devices. Nothing has been verified against a BMV-712, a SmartSolar MPPT 100/50 or an Orion XS yet: see [docs/testing.md](docs/testing.md). No release is tagged, and the API is not stable.

## What's included

- **One parser for the whole stream:** `FrameParser` takes the bytes from the port and returns text blocks, HEX responses and asynchronous HEX frames as they complete, however they are interleaved. A HEX frame in the middle of a text block leaves both intact.
- **Text mode:** `TextBlock` has a typed reading for every label in Victron's text protocol document (`mainVoltage`, `stateOfCharge`, `panelPower`, `operationState` and so on) and keeps the raw label and value of every field, including labels the library does not know.
- **HEX mode:** `HexCommand` builds ping, version, product ID, restart, get and set frames, checksum included. `HexResponse` interprets every response and reports the device's error flags as typed errors.
- **Register tables:** definitions for the registers of the MPPT solar chargers, the BMV-700 series, the Orion XS and the Phoenix inverters, each with its type, scale and unit, plus a table of 174 product ids.

Serial drivers aren't part of this package: open the port yourself at 19200 baud, 8 data bits, no parity, 1 stop bit and no flow control.

## Goals

- **Victron's documents are the only source of protocol fact.** Every register and field names its document and table in its doc comment, and [docs/sources.md](docs/sources.md) records where the documents are unclear and what the library does about it.
- **No input can crash it.** Buffers have fixed maximums, arithmetic on received data is checked, and the package builds with Swift's strict memory safety and warnings as errors. The tests feed it random, truncated and corrupted input.
- **Nothing unknown is lost.** An unknown label, register, product ID or enumeration value decodes to its raw value and never fails.
- **Hard to misuse for writes.** A setting stored in the device's non-volatile memory is written with `setPersistent`, and the run-time `set` refuses it. There is no way to build the command that puts a device in its bootloader.
- **Idiomatic Swift.** Follows the [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/): value types, optionals for "not available", typed throws and no dependencies, not even Foundation.
- **Linux only.** The supported platform is Ubuntu 26.04 LTS on arm64 with the swift.org toolchain. macOS and other Apple platforms aren't supported.

## Installation

Add the package to your `Package.swift`. No release is tagged yet, so pin a commit:

```swift
dependencies: [
    .package(url: "https://github.com/NathanDigital/swift-vedirect.git", revision: "<commit>"),
],
targets: [
    .target(name: "MyApp", dependencies: [
        .product(name: "VEDirect", package: "swift-vedirect"),
    ]),
]
```

```swift
import VEDirect
```

The package needs Swift 6.4 and has no dependencies of its own.

## Usage

Feed every byte you read from the port to a parser, and handle what comes out:

```swift
import VEDirect

var parser = FrameParser()

for byte in received {  // bytes you read from the serial port
    switch parser.consume(byte) {
    case .textBlock(let block)?:
        // A device spreads its fields over several blocks, so each reading is optional.
        if let voltage = try block.mainVoltage, let current = try block.current {
            print("\(voltage) V, \(current) A")
        }
    case .hexFrame(let frame)?:
        // Responses are matched to requests by register id.
        if case .get(let reply) = try HexResponse(frame),
            reply.id == OrionXS.batteryMaximumCurrent.id
        {
            let value = try reply.decoded(as: OrionXS.batteryMaximumCurrent)  // .number(50.0)
            print(value as Any)
        }
    case .discarded(let reason)?:
        print("discarded:", reason)  // a bad checksum, an oversized field and so on
    case nil:
        break  // more bytes needed
    }
}
```

To send a command, build its bytes and write them to the port yourself:

```swift
// Read a register: ":7F0ED0071\n"
let request = HexCommand.get(OrionXS.batteryMaximumCurrent).encoded()

// Write a run-time register: limit the charge current to 30 A.
let limit = try HexCommand.set(OrionXS.chargeCurrentLimit, to: .number(30)).encoded()

// Write a setting the device stores in non-volatile memory. Don't do this in a loop.
let setting = try HexCommand.setPersistent(OrionXS.batteryMaximumCurrent, to: .number(40))
    .encoded()
```

The library builds and decodes frames; you decide when to send and how often to repeat.

## Documentation

- **API reference** is in the `///` comments on every public declaration.
- **[docs/architecture.md](docs/architecture.md)** describes the layers and the design decisions.
- **[docs/sources.md](docs/sources.md)** lists Victron's documents, their revisions, and the places where they are ambiguous.
- **[docs/testing.md](docs/testing.md)** records what has been tested against what, and where the capture fixtures come from.

## Building

The reference build environment is a pinned Docker image: Ubuntu 26.04 LTS with the Swift 6.4.2 toolchain from swift.org. Everyone builds against the same OS and compiler.

**Docker is required to build and test this repository.** A Swift toolchain installed on the host isn't used and isn't supported, so Docker is the only thing to install:

```sh
docker build -t swift-vedirect-build:swift-6.4.2 docker
docker run --rm -v "$PWD":/src -w /src swift-vedirect-build:swift-6.4.2 swift build
docker run --rm -v "$PWD":/src -w /src swift-vedirect-build:swift-6.4.2 swift test
docker run --rm -v "$PWD":/src -w /src swift-vedirect-build:swift-6.4.2 \
    swift format lint -s -r Sources Tests Package.swift
```

## Acknowledgements

The test captures of real devices are from [karioja/vedirect](https://github.com/karioja/vedirect) by **Janne Kario**, used under its MIT licence.

Three other open-source projects informed the design, though no code was taken from them: [krahabb/esphome-victron-vedirect](https://github.com/krahabb/esphome-victron-vedirect), [koestler/go-victron](https://github.com/koestler/go-victron) and [jordens/vedirect](https://github.com/jordens/vedirect).

## License

MIT, © NathanDigital: see [LICENSE](LICENSE). The capture fixtures keep their own MIT notice in [`Tests/VEDirectTests/Fixtures`](Tests/VEDirectTests/Fixtures).

## Disclaimer

This is an independent project. It is not affiliated with, endorsed by or supported by Victron Energy. Victron Energy and VE.Direct are trademarks of Victron Energy B.V. Writing to a device's registers can change how it charges a battery or stop it charging altogether. Use this software at your own risk.
