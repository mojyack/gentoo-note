#!/bin/zsh

set -e

if [[ $UID != 0 ]]; then
    echo "please run as root"
    exit 1
fi

if [[ $1 == 1 ]]; then
    ip address add 192.168.10.2/24 dev $2
    echo $2 > /tmp/upd-if

    mkdir -p /tmp/rtmp
    mount direct-host://var/cache/distfiles /var/cache/distfiles
    mount direct-host://tmp /tmp/rtmp

    echo on
elif [[ $1 == 0 ]]; then
    umount /var/cache/distfiles
    umount /tmp/rtmp
    rmdir /tmp/rtmp

    ip address del 192.168.10.2/24 dev $(cat /tmp/upd-if)
    rm /tmp/upd-if

    echo off
else
    echo "unknown argument"
    exit 1
fi
