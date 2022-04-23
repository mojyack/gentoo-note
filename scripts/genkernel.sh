#!/bin/zsh

try() {
    $@ || { echo "genkernel: panic at command \"$@\""; exit 1; }
}

if (( $# >= 1 )) {
    root="$1"
    if [[ ! -d $root ]] {
        echo "no such directory"
        exit 1
    }
} else {
    root=""
}

export INSTALL_PATH="$root/boot"
export INSTALL_MOD_PATH="$root/"
try make CC=clang LLVM=1 -j24
try make modules_install
try depmod -b "$root/" $(echo "${PWD##*/}" | cut -d - -f 2-)

if [[ $(cat .config | grep CONFIG_EFI=)  == "CONFIG_EFI=y" ]] {
    try mkdir -p /boot/EFI/BOOT
    try mkdir -p /boot/EFI/Linux
    if [[ -e $root/boot/EFI/BOOT/BOOTX64.EFI ]] {
        try mv "$root/boot/EFI/BOOT/BOOTX64.EFI" "$root/boot/EFI/BOOT/BOOTX64.EFI.bak"
    }
    if [[ -e $root/boot/EFI/Linux/vmlinuz ]] {
        try mv "$root/boot/EFI/Linux/vmlinuz" "$root/boot/EFI/Linux/vmlinuz.bak"
    }
    vmlinuz="arch/x86_64/boot/bzImage"
    try cp $vmlinuz "$root/boot/EFI/Linux/vmlinuz"
    try cp $vmlinuz "$root/boot/EFI/BOOT/BOOTX64.EFI"
} else {
    try make install
}
