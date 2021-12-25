#!/bin/bash

try() {
    $@ || { echo "genkernel: panic at command \"$@\""; exit 1; }
}

try make CC=clang LLVM=1 -j24
try make modules_install
try depmod $(echo "${PWD##*/}" | cut -d - -f 2-)

if [[ $(cat .config | grep CONFIG_EFI=)  == "CONFIG_EFI=y" ]]; then
    try mkdir -p /boot/EFI/BOOT
    try mkdir -p /boot/EFI/Linux
    if [[ -e /boot/EFI/BOOT/BOOTX64.EFI ]]; then
        try mv /boot/EFI/BOOT/BOOTX64.EFI /boot/EFI/BOOT/BOOTX64.EFI.bak
    fi
    if [[ -e /boot/EFI/Linux/vmlinuz ]]; then
        try mv /boot/EFI/Linux/vmlinuz /boot/EFI/Linux/vmlinuz.bak
    fi
    vmlinuz="arch/x86_64/boot/bzImage"
    try cp $vmlinuz /boot/EFI/Linux/vmlinuz
    try cp $vmlinuz /boot/EFI/BOOT/BOOTX64.EFI
else
    try make install
fi
