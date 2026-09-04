# paring
## over rail
```sh
ADAPTER=$(bluetoothctl show | awk '/^Controller/ { print $2 }')
echo $ADAPTER > /sys/bus/serial/devices/serial0-0/pairing_host  # right
echo $ADAPTER > /sys/bus/serial/devices/serial1-0/pairing_host  # left
./install-pairing-key.sh  # tell bluetoothd
```
## with sync button
1. hold sync button on joy-con
2. run
```sh
bluetoothctl --timeout 30 scan on   # until it appears
MAC=60:6B:FF:0C:E2:81               # from scan above
bluetoothctl pair    $MAC
bluetoothctl trust   $MAC
bluetoothctl connect $MAC
```
3. optionally make pairing persists by `./install-pairing-key.sh`

# reproduce joycon-hid-sdp-record.hex
1. pair joycon with sync button
2. run
```sh
sed -n 's/^0x00010000=//p' /var/lib/bluetooth/$ADAPTER/cache/$MAC > joycon-hid-sdp-record.hex
```
