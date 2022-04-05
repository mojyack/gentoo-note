#!/bin/zsh

if (( $# < 1 )) {
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

client="$1"
mount_root="/tmp/mnt"
mount="$mount_root/$client"

boot=0
showmount -e "$client" --no-headers | while read e; do
    export=$(echo $e head -n1 | awk '{print "$1";}')
    if [[ $export == "/boot" ]]; then
        boot=1
        break
    fi
done

try mkdir -p "$mount"
try mount -t nfs4 "$client":/ "$mount"
if [[ $boot == 1 ]] {
    try mount -t nfs4 "$client":/boot "$mount/boot"
}

"${0:a:h}/chroot.sh" "$mount" root

if [[ $boot == 1 ]]; then
    try umount -R "$mount/boot"
fi
try umount -R "$mount"
try rmdir "$mount"
if [[ -z "$(ls -A "$mount_root")" ]] {
    try rmdir "$mount_root"
}
