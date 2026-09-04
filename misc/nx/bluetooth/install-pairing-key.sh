#!/bin/bash
# Hand BlueZ what a rail pairing never gives it: the link key the controller
# made, and the HID SDP record it would have browsed for. Joy-Cons docked.
set -euo pipefail

RAILS=/sys/bus/serial/devices
STORE=/var/lib/bluetooth
RECORD=$(dirname "$(readlink -f "$0")")/joycon-hid-sdp-record.hex

die() { echo "${0##*/}: $*" >&2; exit 1; }

if [[ -e /run/daemons/bluetoothd ]]; then
	daemon() { case $1 in start) echo up;; stop) echo down;; esac > /run/daemons/bluetoothd/state; }
else
	# restart, not start: anything that dbus-activates bluetoothd while it is
	# meant to be down leaves it holding the key from before the edit.
	daemon() { systemctl "${1/start/restart}" bluetooth; }
fi

adapter=$(bluetoothctl show 2>/dev/null | awk '/^Controller/ { print $2; exit }')
[[ -n $adapter ]] || die "no bluetooth adapter"

# Read the rails first, so bluetoothd is down for as little as possible.
declare -A keys=() names=() products=()
for dir in "$RAILS"/*/; do
	rail=${dir%/}; rail=${rail##*/}
	[[ -e $dir/pairing_key ]] || continue

	# -ENODATA until the controller answers, and for one never paired.
	host=$(cat "$dir/pairing_host" 2>/dev/null) && key=$(cat "$dir/pairing_key") || {
		echo "$rail: no pairing record (not docked long enough, or never paired)"
		continue
	}
	[[ ${host^^} == "${adapter^^}" ]] || {
		echo "$rail: paired to $host, not to this adapter - skipping"
		continue
	}

	inputs=("$dir"/input/input*)
	read -r mac < "${inputs[0]}/uniq"; mac=${mac^^}
	read -r product < "${inputs[0]}/id/product"
	case $product in
	2006) name="Joy-Con (L)";;
	2007) name="Joy-Con (R)";;
	# The stored record is a Joy-Con's; a Pro Controller needs its own.
	*) echo "$rail: no SDP record for product $product - skipping"; continue;;
	esac

	keys[$mac]=${key^^} names[$mac]=$name products[$mac]=$product
	echo "$rail: $mac $name"
done
(( ${#keys[@]} )) || die "nothing to install - dock the Joy-Cons and try again"

daemon stop
sleep 1

for mac in "${!keys[@]}"; do
	mkdir -p "$STORE/$adapter/$mac" "$STORE/$adapter/cache"

	# Services and DeviceID stand in for the SDP browse that never happened.
	# Without them bluetoothd refuses the HID channel and answers with a
	# virtual cable unplug, which makes the controller drop the pairing.
	# Key type 4 is what the pairing produced; source 2 is USB-IF.
	cat > "$STORE/$adapter/$mac/info" <<-EOF
		[General]
		Name=${names[$mac]}
		Class=0x000508
		SupportedTechnologies=BR/EDR;
		Trusted=true
		Services=00001124-0000-1000-8000-00805f9b34fb;00001200-0000-1000-8000-00805f9b34fb;

		[LinkKey]
		Key=${keys[$mac]}
		Type=4
		PINLength=0

		[DeviceID]
		Source=2
		Vendor=$((16#057e))
		Product=$((16#${products[$mac]}))
		Version=1
	EOF

	# What extract_hid_record() reads. Same bytes for either half.
	cat > "$STORE/$adapter/cache/$mac" <<-EOF
		[General]
		Name=${names[$mac]}

		[ServiceRecords]
		0x00010000=$(< "$RECORD")
	EOF

	echo "installed key and HID record for $mac"
done

daemon start
sleep 3

for mac in "${!keys[@]}"; do
	echo "$mac: $(bluetoothctl info "$mac" | sed 's/\x1b\[[0-9;]*m//g' |
		grep -oE '(Paired|Bonded|Trusted): [a-z]+' | tr '\n' ' ')"
done
