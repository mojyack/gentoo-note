#!/bin/zsh

if (( $# < 2 )); then
    echo "too few arguments"
    exit 1
fi

if (( $UID != 0 )); then
    echo "please run as root"
    exit 1
fi

try() {
    $@ || { echo "panic at command \"$@\""; exit 1; }
}

client="$1"
mount="$2"

boot=0
showmount -e "$client" --no-headers | while read e; do
    export=$(echo $e head -n1 | awk '{print "$1";}')
    if [[ $export == "/boot" ]]; then
        boot=1
        break
    fi
done

mount -t nfs4 "$client":/ "$mount" || panic
if [[ $boot == 1 ]]; then
    mount -t nfs4 "$client":/boot "$mount/boot" || panic
fi

try mount --types proc /proc "$mount/proc"
try mount --rbind /sys "$mount/sys"
try mount --make-rslave "$mount/sys"
try mount --rbind /dev "$mount/dev"
try mount --make-rslave "$mount/dev"
try mount --rbind /run "$mount/run"
try mount --make-rslave "$mount/run"
try mount -t tmpfs tmpfs "$mount/tmp"

chroot "$mount" $(awk -F: -v user="root" '$1 == user {print $NF}' "$mount/etc/passwd")

if [[ $boot == 1 ]]; then
    try umount -R "$mount/boot"
fi
try umount -R "$mount"
