#!/bin/zsh

scripts=/home/mojyack/build/gentoo-note/scripts

lid=$($scripts/find-input-device.sh "Lid Switch") || exit 1
kbd=$($scripts/find-input-device.sh "Apple SPI Keyboard") || exit 1
kbdled="/sys/class/leds/spi::kbd_backlight/brightness"

if [[ -n $SWAYSOCK ]]; then
    dpms_on() {
        swaymsg "output eDP-1 dpms on"
    }
    dpms_off() {
        swaymsg "output eDP-1 dpms off"
    }
else
    dpms_on() {
        echo 1 > /sys/class/graphics/fb0/blank
    }
    dpms_off() {
        echo 0 > /sys/class/graphics/fb0/blank
    }
fi

dpms_off

kbdbackup=$(<$kbdled)
echo 0 > $kbdled

$scripts/blizzard/blizzard.sh "/dev/input/$lid" "/dev/input/$kbd"

# fix touchpad
modprobe -r applespi
modprobe applespi

dpms_on
echo $kbdbackup > $kbdled

exit 1 # prevent hardware suspend
