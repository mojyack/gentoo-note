#!/bin/zsh
# $1 device name

set -e

cd /sys/class/input
for dev in *; do
    if [[ ! -e $dev/device/name ]]; then
        continue
    fi
    name=$(<$dev/device/name)
    if [[ $name == $1 ]]; then
        echo $dev
        return 0
    fi
done
return 1
