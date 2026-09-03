# Pairing a Joy-Con over the rail

How the wire exchange works, what the controller stores, and what a console
actually sends. Implemented in `drivers/input/joystick/joycon.c`; the framing
underneath is in `ref/hekate/bdk/input/joycon.c`.

## The pairing record

At SPI `0x2000`, `struct jc_hid_in_pair_data_t` (hekate
`bdk/input/joycon.c:358`, `ref/Nintendo_Switch_Reverse_Engineering/spi_flash_notes.md`):

| off | field |
| --- | --- |
| `0x00` | magic - `0x95` live, `0x00` not live |
| `0x01` | size, always `0x22` |
| `0x02`-`0x03` | checksum |
| `0x04`-`0x09` | host address, big-endian |
| `0x0A`-`0x19` | link key, **little-endian - reverse it** |
| `0x1A`-`0x23` | zero |
| `0x24` | `bt_caps`: `0x68` Switch, `0x08` PC |
| `0x25` | zero |

- Slots are `0x26` apart and appended; the live one is the first with the magic.
  The section is `0x2000`-`0x2FFF`, so **107** slots - walk until one matches.
- The layout is confirmed on the SPI bus: at power-on the controller reads
  `0x2000` for 4 bytes, then `0x2004` for `0x22`, then steps to `0x2026` - the
  same slot walk, stride and head/body split the driver uses.
- Checksum byte 2 is `((sum(host) + sum(ltk) + bt_caps) & 0xff) ^ 0x55`, checked
  against six real records including one read straight off the SPI bus. **Byte 3
  is unknown**; no CRC16 variant over any plausible range fits, and the RE notes
  mark it `Checksum?` too. It does not matter - the controller writes the record.
- The flash key, reversed, **is** the BR/EDR link key.
- Holding SYNC **erases the whole section**; it does not just add an entry.
- `magic 0x00` with the next slot still `0xFF` is not a superseded record. It is
  a live record that a host unplugged - see `bluez-integration.md`.

## The sequence

The reply byte to a pairing request is **the step the controller has reached**,
not a status:

- `0x03` - saved, nothing to do. What a host it already holds gets, and all a
  console ever sees, because a console only re-states a pairing it has. No flash
  write happens, so "acked and wrote nothing" is not a refusal.
- `0x01` - it has taken the address and is at step 1, waiting to be walked
  through the rest.

A new host has to finish what type `0x04` starts:

| out | in |
| --- | --- |
| `01 04 <host, LE> 00 04 3c <name, 20B> 68 00 85 af a4 69 2a 00` | `01 01 <joy-con addr, LE> <class 00 25 08> "Joy-Con (L)" .. 68` |
| `01 02` | `01 02 <LTK, LE, each byte ^0xAA>` |
| `01 03` | `01 03` - record written |

Preceded by `08 00` (clear shipment), the way a console does. The record lands
in the next free slot, `pairing_key` reads back exactly the LTK from the `01 02`
reply, and it is a working BR/EDR link key.

**Type `0x04` must start the sequence.** The documented three-step sequence
(`01 01` / `01 02` / `01 03`) works mechanically - key back, well-formed record,
reads back from flash - and is useless: it writes `bt_caps = 0x08`, and the
controller then refuses to authenticate against its own record, with
`Link Key Request Reply` followed by `Disconnect 0x13` and no `Auth Complete` at
all. Every record that reconnects has `bt_caps = 0x68`, and `0x04` is the only
request that carries a caps byte.

**A pairing takes effect the moment it is written.** No restart is needed:
pairing a docked controller to an address it did not boot with, sending no
`0x06`, and pulling it off the rail gives 40 s of silence on the host it booted
with - it pages the address it was just given.

**The controller stalls the first time it is sent `08 00`** if its shipment flag
is still set: it writes flash and answers nothing for seconds, so the first
`pair_host` on a fresh controller times out. Run it again.

**The controller rate-limits after a failed authentication**
(`Repeated Attempts 0x17`) and stays that way for minutes. Leave it alone
between experiments or every result is noise.

## Subcommand 0x06 (set HCI state)

Arg `0x01` = reboot and reconnect. Useful as the only hands-free way to get a
docked controller onto Bluetooth, but a poor one: it reboots, leaves the rail,
pages the host, and the rail handshake pulls it straight back. It also rewrites
the pairing section from the top - a record written to slot 2 is in slot 0 after
a restart.

No console sends it: all four docking captures send the same twelve subcommands
and `06` is not among them. Undocking is an electrical event - the console holds
`Jdet` low to keep the controller on the wire - so nothing has to be said to
make it go to Bluetooth. `Jdet` is not in our DT (only `charge-gpios`), which is
why a docked controller always comes back to the rail.

## What a console sends, measured

Decoded from the logic captures (exports in `../captures/`). Three independent
docking sessions, two different Joy-Cons. These are the *only* subcommands sent
in a whole docking capture, in this order, one per 15 ms poll slot, each
answered before the next goes out:

```
2.6336  02                    device info      -> c0 82 02  03 48 01 02 <mac>
2.6636  08 00                 clear shipment   -> c0 80 08  00
2.6786  01 04 ...             pair to host     -> c0 81 01  03
2.7086  03 30                 input report mode
2.7236  04                    trigger elapsed
2.7536  10 80 60 00 00 18     SPI read 0x6080  \
2.7836  10 98 60 00 00 12     SPI read 0x6098   |  colour and calibration,
2.8136  10 10 80 00 00 18     SPI read 0x8010   |  no read of 0x2000
2.8286  10 3d 60 00 00 19     SPI read 0x603d   |
2.8436  10 20 60 00 00 18     SPI read 0x6020  /
2.8887  48 01                 enable vibration
2.9186  40 01                 enable IMU
```

The pairing request:

```
01 04 4b b1 f0 8a bb 7c 00 04 3c "Nintendo Switch"+5 nul 68 00 85 af a4 69 2a 00
^^ ^^ ^^^^^^^^^^^^^^^^^ ^^^^^^^^ ^^^^^^^^^^^^^^^^^^^^^^ ^^ ^^ ^^^^^^^^^^^^^^^^^
|  |  host addr, LE     unknown  host name, 20 bytes    |  |  unknown
|  pair request type 0x04                               |  bt_caps
subcommand                                              zero
```

All 38 argument bytes are **identical in every capture**, differing only in the
frame counter and CRC around them. So `00 04 3c` and the trailing
`85 af a4 69 2a 00` are part of the request, not leftovers in the console's
buffer, and the name really is `"Nintendo Switch"`. The driver sends all 38
bytes verbatim, with the shipment clear ahead of them.

Two things the captures do **not** show, both because that controller was
already paired to that console:

- the console learning the link key - the reply is `81 01 03`, "saved", and it
  never reads `0x2000`. A console adopting a controller it does not hold would
  get `01` and would have to go on to `01 02`, which is where the key comes from;
- any flash write. In `left_grey_joycon_spi_poweron_then_dock` the flash is put
  into deep power-down (`0xB9`) at 0.15 s and is still asleep when the pairing
  request arrives at 2.68 s, waking at 2.75 s only for the five SPI reads. There
  is no `WREN`, page program or erase in the capture at all. So "the controller
  acked and wrote nothing" is not by itself evidence that a request was refused.

## Reading the logic captures

`ref/Nintendo_Switch_Reverse_Engineering/logic_captures/*.logicdata` is Saleae
Logic 1.x format, which nothing open source reads (`packet_parse/parse.py` takes
an already-exported CSV). Logic 1.2.18 does, and runs headless:

```sh
curl -O "https://downloads.saleae.com/logic/1.2.18/Logic+1.2.18+(64-bit).zip"
unzip ... && cd "Logic 1.2.18 (64-bit)"
mkdir bundled_libs && mv libQt5*.so.5 libicu*.so.56 bundled_libs/   # Qt 5.7 -> system 5.15
QT_QPA_PLATFORM=offscreen QT_PLUGIN_PATH=/usr/lib/qt/plugins ./Logic -socket
```

There is no X server here and the bundled Qt ships only the xcb plugin, hence
borrowing the system Qt; an app built against 5.7 is fine on 5.15. Then drive
port 10429 with `LOAD_FROM_FILE, <path>`, `GET_ANALYZERS`,
`IS_ANALYZER_COMPLETE, <n>`, `EXPORT_ANALYZER, <n>, <path>, 0`. Commands are
NUL-terminated; **replies end in `ACK` with no NUL**, and a client that follows
the published API and waits for `ACK\0` hangs forever.

The analyzers are saved inside the captures, so exports come out already
decoded, including SPI on the flash bus in
`left_grey_joycon_spi_poweron_then_dock` (analyzer 4 is the flash, 3 the
LSM6DS3). `right_grey_joycon_docking...` is the one file with no analyzer saved.
The async serial analyzer is set for 3.125 Mbps, so the first ~30 ms of every
docking capture - the 1 Mbps handshake - comes out as framing errors.

Exports kept gzipped in `../captures/`: `spi_dock_flash` (the flash bus),
`spi_dock_c2j` / `spi_dock_j2c` (its rail, both directions), and
`leftgrey_dock_c2j` / `leftgrey_dock_j2c`.

## Open questions

- **Tell userspace when a pairing happens.** The pairing is only half done until
  `install-pairing-key.sh` has run, and nothing signals when to run it; a uevent
  on a new record would be enough.
- **`bt_caps` is not published.** The caps theory rests on records read with a
  since-removed SPI dump hook - `pairing_key` stops at offset `0x19` and never
  sees it. A second read of the slot tail would make it checkable.
- Checksum byte 3 is unexplained.
