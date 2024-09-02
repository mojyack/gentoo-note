#!/bin/zsh

set -e

cp rtc-read-offset /sbin
cp rtc-save-offset /sbin
cp 90-read-rtc-offset.sh /etc/init/1.d
cp 00-save-rtc-offset.sh /etc/init/3.d
