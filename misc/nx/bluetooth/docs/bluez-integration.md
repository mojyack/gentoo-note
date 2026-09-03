# What BlueZ needs from a rail pairing

A rail pairing bypasses Bluetooth bonding entirely, so BlueZ ends up missing two
things it would normally have learned: the link key, and the device's service
records. `bluetooth/install-pairing-key.sh` supplies both, with the controllers
docked. Stock BlueZ; no patch.

## The refusal, and why it is destructive

With the key installed but nothing else, a reconnect gets all the way to the HID
channel and is then turned away:

```
Link Key Request Reply      -> Success
Encryption Change           -> Enabled with E0
L2CAP Connection Request      PSM 17 (HID control)
bluetoothd: profiles/input/server.c:connect_event_cb()
            Refusing input device connect: No such file or directory (2)
```

`find_device()` needs `btd_device_get_service(device, HID_UUID)`. A rail-paired
controller has no HID UUID, because `device_browse_sdp()` runs on bonding
completion or on an explicit `Connect()` and neither ever happened: `info` has
no `Services=` and `cache/<mac>` no `[ServiceRecords]`.

**The refusal destroys the pairing.** On `-ENOENT` bluetoothd writes a HIDP
**virtual cable unplug** (`0x15`) to the control channel - one byte, visible in
`btmon` immediately before the disconnect - and the controller throws its
pairing record away. The record's magic goes `0x95` -> `0x00`, or the whole
`0x2000` section is erased.

The resulting symptom chain reads exactly like a flaky pairing sequence, and is
not:

1. pair over the rail, install the key - all reported fine;
2. detach: the link comes up and is dropped a few hundred ms later;
3. from then on `pairing_host` reads `-ENODATA` on a docked, fully initialised
   controller, and it never pages again.

A record with magic `0x00` whose **next slot is still `0xFF`** is the giveaway:
a genuinely superseded record always has a successor.

## What the script writes

Per controller, into `/var/lib/bluetooth/<adapter>/`:

| where | what | why |
| --- | --- | --- |
| `<mac>/info` `[LinkKey]` | key from `pairing_key`, `Type=4` | the controller invented it and never sends it |
| `<mac>/info` `Services=` | HID `0x1124` + PnP `0x1200` | `find_device()` resolves, input profile probed |
| `<mac>/info` `[DeviceID]` | source 2, vendor `0x057e`, product from the rail's `input*/id/product` | `hidp_add_connection()` fills `req->vendor`/`product`, which `hid-nintendo` matches on |
| `cache/<mac>` `[ServiceRecords] 0x00010000=` | `joycon-hid-sdp-record.hex` | `extract_hid_record()` refuses to build the connection without it |

`Trusted=true` goes in too - auto-connect on an incoming connection is for
trusted devices only, and the whole point is that the controller comes back by
itself.

Verified on stock BlueZ: both halves connect with **zero SDP requests on the
wire**, and the seeded `cache/<mac>` is byte-identical to what BlueZ writes for
itself after a real browse.

## Regenerating joycon-hid-sdp-record.hex

The file is the controller's own HID SDP record, stored the way BlueZ stores it:
raw record, hex, one line, no `0x00010000=` prefix. It is **byte-identical for
both halves** - the L and R caches read off two real controllers differ only in
the name and in the product id inside the *PnP* record, which is not stored at
all because `[DeviceID]` covers it.

To regenerate it, let BlueZ browse the device once the normal way. An
over-the-air SYNC pairing does that, because bonding ends in
`device_bonding_complete()` -> `device_browse_sdp()`. Then:

```sh
doas sed -n 's/^0x00010000=//p' \
	/var/lib/bluetooth/$ADAPTER/cache/$MAC > joycon-hid-sdp-record.hex
```

`0x00000000` is the SDP server's own record and `0x00010001` the PnP one;
neither is stored.

Sanity check - 384 bytes, and the attributes should include `0x0001`
ServiceClassIDList `19 11 24` (HumanInterfaceDeviceService), `0x0100`
ServiceName "Wireless Gamepad", and `0x0206` HIDDescriptorList carrying the
176-byte report descriptor:

```sh
python3 -c 'import sys;b=bytes.fromhex(open(sys.argv[1]).read());print(len(b),"191124" in b.hex())' \
	joycon-hid-sdp-record.hex
```

A Pro Controller has a different report descriptor and would need its own file;
there is none in the tree, which is why the script skips any product id that is
not `2006` or `2007`.

## Why not patch BlueZ

Tried, works, rejected - do not re-derive it. BlueZ already has the right
recovery path for a device bonded over a cable: `sixaxis_browse_sdp()` holds the
incoming channel, runs `device_discover_services()` over the link that is
already up, then hands the channel over. It is gated on the Sixaxis/DS4
vendor-product table, which a Joy-Con can never match because it has no DeviceID
record either, and extending it to anything flagged `CablePairing` is a five-line
patch.

The problem is the deadline. The controller tears the link down about **400 ms**
after its interrupt channel goes `Connection pending`, and the records come back
38 bytes at a time over a 48-byte MTU. One Joy-Con made it first try; the other
lost the race more than twenty times in a row, with nothing else on the radio
except its own half streaming input reports. Seeding the record has no race and
needs no patched daemon.

Two traps from that route, if it ever comes back:

- BlueZ writes cached records as they arrive but writes `Services=` only when a
  browse ends **cleanly**, so a run that fetched everything and then errored
  leaves a complete cache, no `Services=`, and a connection refused for exactly
  the same reason as before - looking like no progress at all.
- Never write `Services=` before the records exist: it sets `svc_resolved`,
  BlueZ then never browses, and the failure just moves to
  `extract_hid_record()`.
