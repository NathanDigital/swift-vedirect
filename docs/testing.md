# Testing

Tests use Swift Testing and run in the build container:

```sh
docker run --rm -v "$PWD":/src -w /src swift-vedirect-build:swift-6.4.2 swift test
```

## Verification status

Nothing is verified against the first three target devices yet: there is no capture from a
BMV-712 Smart, a SmartSolar MPPT 100/50 or an Orion XS. The register tables are transcribed from
Victron's documents and tested only against the documents' own examples.

| Area | Tested against |
|---|---|
| Text framing and typed fields | The FAQ example block and the three captures below |
| HEX framing, commands and responses | Every example frame in the four HEX documents and the FAQ |
| Register tables | The documents' example values; ids and names checked for uniqueness |
| Arbitrary input | Seeded random bytes, every truncation, every single-bit corruption of a block |

No capture holds a HEX frame inside a text block, so that case is tested with constructed input.

## Fixtures

The captures in `Tests/VEDirectTests/Fixtures/` are from `karioja/vedirect` (MIT), commit
`a576848c4015ea6be92df26240c316e6886ed731`, directory `test/`. Its licence notice is
`Fixtures/LICENSE-karioja-vedirect.txt`. That project's README describes them as live recordings
of the serial data from its author's own devices. They are embedded in the test bundle with
`.embedInCode`, so the tests need no Foundation.

| File | Device | Product id | Firmware | Bytes | Contents |
|---|---|---|---|---|---|
| `bluesolar_1.23.dump` | BlueSolar MPPT 75/15 | `0xA042` | 1.23 | 41226 | 248 blocks, 7 asynchronous HEX frames; starts with one stray byte |
| `bvm702.dump` | BMV-700 (the origin calls it a "BVM 702") | `0x203` | 3.08 | 119074 | 906 blocks in two alternating sets, 7 with a `0x3A` checksum byte; ends mid-block |
| `smartsolar_1.39.dump` | SmartSolar MPPT 100/20 | `0xA05F` | 1.39 | 79195 | 493 blocks, 2 asynchronous HEX frames; starts mid-block |

The two MPPT captures contain their devices' serial numbers, as published by the origin project.

Fetch a binary file from GitHub through the blob endpoint. The `contents` endpoint returned these
files re-encoded as UTF-8, which corrupts every byte above `0x7F`:

```sh
sha=$(gh api repos/<owner>/<repo>/contents/<path> --jq .sha)
gh api repos/<owner>/<repo>/git/blobs/$sha --jq .content | base64 -d > <file>
```

`.gitattributes` marks `*.dump` as binary so that git never converts line endings in a capture.
