# Joy-Cons over Bluetooth

The rails and Bluetooth carry the same controller. Docked it is a serdev device
driven by `drivers/input/joystick/joycon.c`; off the rail it is an ordinary
Bluetooth HID gamepad driven by `hid-nintendo`, appearing as `Joy-Con (L)` /
`Joy-Con (R)` plus an `(IMU)` node each.

- `bluez-integration.md` - what BlueZ needs from us and why, and how to
  regenerate `joycon-hid-sdp-record.hex`.
- `rail-protocol.md` - the pairing record, the wire sequence, and what a console
  does, for anyone touching the driver.

Both pairing paths and the record regeneration are verified on hardware.

## Prerequisites

- `brcm/BCM4356A3.hcd` in `/lib/firmware`, from `firmware/brcm/`; a normal image
  build installs it. Check with `dmesg | grep BCM4356A3`: it must say
  `'brcm/BCM4356A3.hcd' Patch` and report build `0064`, not `0000`. Unpatched,
  small packets get through and larger ones do not, so an SDP request is
  acknowledged and its fragmented answer never arrives.
- `CONFIG_HID_NINTENDO=m` (`kconfig/nintendo-switch`), `hid-nintendo` loaded.
- Stock BlueZ, no patch.
- `/etc/bluetooth/main.conf`:

  ```
  [General]
  FastConnectable = true
  ```

  BlueZ page-scans 11.25 ms every 1.28 s by default, about 1%, and a
  controller's page burst usually falls in the gap. **A missed page leaves no
  trace at all** - no HCI events, nothing in `btmon` - so it looks exactly like
  a dead or sleeping controller. It costs a little idle power and weakens
  nothing.
- Everything else in `/etc/bluetooth/*.conf` stock. In particular **do not** set
  `ClassicBondedOnly=false`: it forces the HID channel to an unencrypted
  security level and the connection fails with `Invalid exchange (52)`.

## Pairing over the rail

What a console does: no button, and it will adopt a controller that belongs to
another console. Dock the Joy-Con, then as root:

```sh
ADAPTER=$(bluetoothctl show | awk '/^Controller/ { print $2 }')
echo $ADAPTER > /sys/bus/serial/devices/serial1-0/pair_host   # left
echo $ADAPTER > /sys/bus/serial/devices/serial0-0/pair_host   # right
bluetooth/install-pairing-key.sh
```

Then slide it off. It pages the host by itself within a few seconds.

- **A controller holds one host.** This replaces whatever it was paired to, so a
  Joy-Con adopted this way stops working with the console it came from until it
  is synced back.
- **The first `pair_host` on a fresh controller can time out.** The sequence
  starts by clearing the shipment flag, and a controller that still has it set
  writes flash and answers nothing for several seconds. Run it again; the second
  attempt is instant.
- `install-pairing-key.sh` needs the controller docked, and must be re-run after
  any re-pairing - the key changes every time.

## Pairing with the SYNC button

A Joy-Con only accepts a new host while in SYNC mode and leaves that mode after
a short while, so discovery and pairing have to happen in one go.

1. Detach the Joy-Con and hold SYNC until the LEDs run back and forth.
2. Promptly:

```sh
bluetoothctl --timeout 30 scan on   # until it appears, then stop scanning
MAC=60:6B:FF:0C:E2:81
bluetoothctl pair    $MAC
bluetoothctl trust   $MAC
bluetoothctl connect $MAC
```

Stop scanning before pairing - an active scan starves the link enough to break
the connection. `Connected: yes` plus `UUID: Human Interface Device` means it
worked.

This path bonds normally, so BlueZ browses SDP and caches the service records -
which is also how `joycon-hid-sdp-record.hex` is produced. It still does not
leave a usable link key (see below), so run `install-pairing-key.sh` with the
controller docked to make the pairing survive a disconnect.

## Reconnecting after detach

A paired Joy-Con pages the host by itself when detached or when a button is
pressed. Three things must be true for that to be caught and accepted.

**1. The host must hold the link key.** Neither pairing path leaves BlueZ with
one. Over the rail the key is never sent - the controller invents it and keeps
it in flash. Over the air the controller asks for *no bonding*, so the key is a
session key, `hci_persistent_key()` discards it and BlueZ writes no `[LinkKey]`.
Either way the next connection asks for a key the host does not have and the
link drops; `bluetoothctl info` shows `Bonded: no` even while connected. Horizon
never relies on bonding either - it keeps its own copy of the key, and hekate
exports the same thing to `switchroot/joycon_mac.ini`. `install-pairing-key.sh`
takes it from where it actually lives, the controller.

**2. The host must be listening often enough** - `FastConnectable`, above.

**3. The host must know the HID service** - see `bluez-integration.md`. This is
the one that bites: without it the connection is refused *and* the refusal
destroys the pairing.

## Driver interface

```
/sys/bus/serial/devices/<rail>/pairing_host   0444   the host it is paired to
/sys/bus/serial/devices/<rail>/pairing_key    0400   16-byte link key, hex
/sys/bus/serial/devices/<rail>/pair_host      0200   pair to this host address
/sys/bus/serial/devices/<rail>/reconnect      0200   restart and page the host
```

`serial0-0` is the right rail, `serial1-0` the left. Both reads give `-ENODATA`
for a second or two after docking and for a controller that has never been
paired. The key is already byte-reversed for use - flash stores it back to
front. `pair_host` blocks until the controller answers, and `pairing_key` then
reads the new key.

`reconnect` sends subcommand `0x06 0x01`; a *docked* controller usually reboots,
pages the host and is then pulled straight back onto the wire by the rail
handshake, so it is no substitute for physically detaching when testing.

## Desktop input

Sway never sees a Joy-Con directly - libinput ignores `ID_INPUT_JOYSTICK`. They
reach the desktop through `keyremap2`'s `joycon-desktop`, which grabs the evdev
nodes and feeds a `Joy-Con Desktop` uinput device.

It matches on device name, and the Bluetooth names differ from the rail ones, so
all four are listed in `apps/joycon-desktop.cpp`:

```
"Nintendo Switch Left Joy-Con (Serial)"   rail
"Joy-Con (L)"                             bluetooth
```

Matching is exact, not substring, because each half also exposes a
`Joy-Con (L) (IMU)` node that must not be grabbed.

```sh
doas ls -l /proc/$(pgrep -x joycon-desktop)/fd | grep event   # what it holds
pkill -x joycon-desktop                                       # restart it
```

Not `pkill -f`: over ssh that pattern matches the command line of the shell
running it and kills the session.

## Troubleshooting

| Symptom | Cause |
| --- | --- |
| `br-connection-create-socket` | SDP never answered - firmware patch not loaded |
| `Bonded: no` after pairing | expected; install the key |
| Nothing at all in `btmon`, controller seems dead | missed pages - `FastConnectable` |
| `Refusing input device connect: No such file or directory (2)` | no HID service on the host - `Services=` or the cached record missing; this also unplugs the pairing |
| `pairing_host` reads `-ENODATA` on a docked, initialised controller | its record was destroyed by that unplug - re-pair it |
| `Auth Complete: PIN or Key Missing (0x06)` | host key does not match; re-run the script |
| Link dropped right after `Link Key Request Reply` | bluetoothd answered with the *previous* key - check in `btmon` which key it sent, and restart bluetoothd |
| `pairing timed out` on the first `pair_host` | the shipment clear is writing flash; run it again |
| `Repeated Attempts (0x17)` | the controller rate-limits after failed authentication, for minutes - leave it alone between experiments or every result is noise |
| `Invalid exchange (52)` on the HID channel | `ClassicBondedOnly=false` - remove it |
| Paired and connected, but nothing on the desktop | name not matched in `joycon-desktop.cpp` |

A detached Joy-Con sleeps deeply and answers pages only in a narrow window, so
an outgoing `bluetoothctl connect` is unreliable by nature. Let the controller
come to you: press one of its buttons.
