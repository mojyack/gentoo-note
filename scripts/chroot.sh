#!/bin/zsh

if (( $# < 2 )) {
    echo "too few arguments"
    exit 1
}

if (( $UID != 0 )) {
    echo "please run as root"
    exit 1
}

try() {
    $@ || { echo "panic at command \"$@\""; exit 1; }
}

root="$1"
user="$2"

try mount --types proc /proc "$root/proc"
try mount --rbind /sys "$root/sys"
try mount --make-rslave "$root/sys"
try mount --rbind /dev "$root/dev"
try mount --make-rslave "$root/dev"
try mount --rbind /run "$root/run"
try mount --make-rslave "$root/run"
try mount -t tmpfs tmpfs "$root/tmp"

# optional
try rsync -a -P --remove-source-files "$root/var/cache/distfiles/" /var/cache/distfiles/ && rm -r "$root/var/cache/distfiles/"*
try mount -o bind /var/cache/distfiles "$root/var/cache/distfiles"
try mount -o bind /usr/src "$root/usr/src"

chroot "$root" $(awk -F: -v user="$user" '$1 == user {print $NF}' "$root/etc/passwd")
