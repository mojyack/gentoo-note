#!/bin/zsh

set -e

cp rtc-read-offset /sbin
cp rtc-save-offset /sbin
cp 90-read-rtc-offset.sh /etc/runit/1.d
cp 00-save-rtc-offset.sh /etc/runit/3.d
