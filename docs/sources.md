# Protocol sources

Victron's documents are the only source of protocol fact. All were retrieved on 2026-11-25.

| Document | Revision | Covers | URL |
|---|---|---|---|
| VE.Direct Protocol (text mode) | 3.34, 14 April 2025 | Text framing, 65 labels, product ids, enumerations | <https://www.victronenergy.com/upload/documents/VE.Direct-Protocol-3.34.pdf> |
| VE.Direct Protocol – BlueSolar and SmartSolar MPPT chargers | Rev 18, 15-11-2021 | MPPT HEX registers, including MPPT RS and VE.Can models | <https://www.victronenergy.com/upload/documents/BlueSolar-HEX-protocol.pdf> |
| VE.Direct Protocol – Orion XS DC-DC battery charger | No revision stated; changelog 16-06-2025 | Orion XS HEX registers | <https://www.victronenergy.com/upload/documents/Orion-XS-HEX-protocol.pdf> |
| BMV700 Series Hex Protocol | Rev 7, 01-07-2021 | BMV-700, 700H, 702 and 712 HEX registers | <https://www.victronenergy.com/upload/documents/BMV-7xx-HEX-Protocol.pdf> |
| VE.Direct Protocol – Phoenix Inverters | Rev 5, 2021-09-06 | Phoenix Inverter HEX registers | <https://www.victronenergy.com/upload/documents/VE.Direct-HEX-Protocol-Phoenix-Inverter.pdf> |
| VE.Direct protocol FAQ | Page last modified 2023-03-31 | Reference frame handler, checksum examples | <https://www.victronenergy.com/live/vedirect_protocol:faq> |

Victron publishes no HEX document for the SmartShunt, the Phoenix Smart IP43 chargers, the BMV-600
series or the RS inverters. Those products have text-mode support only, plus raw HEX access by
register id.

## Where the documents are unclear, and what the library does

| Topic | What the documents say | What the library does |
|---|---|---|
| Text limits | "A buffer of 9 bytes" for the label, "33 bytes" for the value and "22 fields"; not whether these include a terminator or `Checksum` | Keeps 9 label bytes, 33 value bytes and 22 fields plus `Checksum` |
| HEX frame length | No maximum is stated; the longest frame defined carries 55 bytes | Keeps 64 bytes after the command nibble |
| HEX frame inside a text block | The reference frame handler loses the interrupted block | Keeps the HEX bytes out of the text checksum and resumes the block |
| HEX checksum | "The sum of all data bytes and the check must equal 0x55"; the examples also need the command nibble and modulo 256 | Sums command, data and check modulo 256 |
| Orion XS example `:30300F4` | Printed with a check byte that does not sum to `0x55`; `4F` would | Rejects the frame as printed; a test records it |
| Non-volatile storage | Only the battery settings table carries a warning; there is no per-register column | Marks every user setting as persistent; outside the battery settings this is the library's inference |
| Register access | No access column in the MPPT, Orion XS or BMV documents | Does not record access; the device answers a refused write with flag `0x02` |
| BMV setting scales | The settings tables give a step but no scale; only battery capacity is confirmed by an example | Uses the step as the scale |
| Not-available values | Defined per register, with no general rule | Decodes a value to `nil` only where the register's document defines one |
| Product names | `0xA06D` and `0xA078` are "rev3" in the text document and "rev2" in the MPPT HEX document | Uses the text document's name |
| BMS mode | The MPPT document says `0xEDE8` is set and stored to flash, and also that it can be cleared to return to stand-alone operation | Offers no helper for BMS mode |
