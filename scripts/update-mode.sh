#!/bin/zsh

set -e

if [[ $UID != 0 ]]; then
    echo "please run as root"
    exit 1
fi

if [[ $1 == 1 ]]; then
    mkdir -p /tmp/rtmp
    mount solomon://var/cache/distfiles /var/cache/distfiles
    mount solomon://tmp /tmp/rtmp

    if [[ -n $2 ]]; then
        ip address add 192.168.10.2/24 dev $2
        echo $2 > /tmp/upd-if
    fi
    echo on
elif [[ $1 == 0 ]]; then
    umount /var/cache/distfiles
    umount /tmp/rtmp
    rmdir /tmp/rtmp

    if [[ -e /tmp/upd-if ]]; then
        ip address del 192.168.10.2/24 dev $(cat /tmp/upd-if)
        rm /tmp/upd-if
    fi
    echo off
else
    echo "unknown argument"
    exit 1
fi
