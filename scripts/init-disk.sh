#!/bin/bash

if [[ $1 == "--legacy" ]]; then
    legacy=1
    shift
else
    legacy=0
fi

if [[ ! -b $1 ]]; then
    echo "$1 is not exists or not a block device."
    exit 1
fi

partdev() {
    lsblk -nlp -o name $1 | sed -n ${2}p
}

if [[ $legacy == 1 ]]; then
    dd if=/dev/zero of=$1 bs=512 count=1
    echo "type=83" | sfdisk $1

    part=$(partdev $1 2)
    mkfs.ext4 -m 0 $part
else
    sgdisk -Z $1
    sgdisk -n 1:0:+256M -t 1:ef00 -c 1:"EFI System" $1
    sgdisk -n 2:0: -t 2:8300 -c 2:"Linux filesystem" $1

    part_boot = $(partdev $1 2)
    part_root = $(partdev $1 3)
    mkfs.vfat -F32 $part_boot 
    mkfs.ext4 -m 0 $part_root 
fi
