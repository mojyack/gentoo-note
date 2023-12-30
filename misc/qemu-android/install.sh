#!/bin/zsh

# ref: https://github.com/Xtr126/androidx86-installer-qemu-linux

set -e

# config
source config

# conditional
initrd=""
system=""
kernel=""

# $1 path
exit_if_noent() {
    if [[ ! -e $1 ]]; then
        echo "no $1 found"
        exit 1
    fi
}

mount_iso() {
    mkdir -p $iso_mount
    mount -o loop,ro $iso $iso_mount
}

# -> initrd system kernel
analyze_iso() {
    pushd $iso_mount
    exit_if_noent "initrd.img"
    initrd="initrd.img"
    exit_if_noent "system.sfs"
    system="system.sfs"
    exit_if_noent "kernel"
    kernel="kernel"
    popd
}

extract_kernel() {
    mkdir -p $object_dir
    cp "$iso_mount/$kernel" "$object_dir/kernel"
    cp "$iso_mount/$initrd" "$object_dir/initrd.img"
}

init_rootfs_image() {
    fallocate -l $rootfs_image_size $rootfs_image
    mkfs.ext4 -m 0 $rootfs_image
}

mount_rootfs_image() {
    mkdir -p $rootfs_mount
    mount -o loop $rootfs_image $rootfs_mount
}

init_rootfs() {
    mkdir -p "$rootfs_mount/data"    
}

extract_system() {
    mkdir -p $system_mount
    mount -o loop,ro $iso_mount/$system $system_mount
    mount -o loop,ro $system_mount/system.img $system_mount
    cp -a -Z $system_mount $rootfs_mount/system
    umount $system_mount
}

# $1 mount path
attempt_unmount() {
    if [[ -d $1 ]]; then
        umount $1
        rmdir $1
    fi
}

cleanup() {
    attempt_unmount $system_mount
    attempt_unmount $rootfs_mount
    attempt_unmount $iso_mount
}

trap "cleanup" EXIT
trap "cleanup" ERR

mount_iso
analyze_iso
extract_kernel
init_rootfs_image
mount_rootfs_image
init_rootfs
extract_system

echo "done"
