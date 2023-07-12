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
    if [[ $export == "/boot" ]] {
        boot=1
        break
    }
done

try mkdir -p "$mount"
try mount -t nfs4 "$client":/ "$mount"
if [[ $boot == 1 ]] {
    try mount -t nfs4 "$client":/boot "$mount/boot"
}

echo "open"
read
echo "close"

while true; do
    if umount -R "$mount"; then
        try rmdir "$mount"
        if [[ -z "$(ls -A "$mount_root")" ]] {
            try rmdir "$mount_root"
        }
        exit 0
    fi
    echo "unmount failed. press any key to retry"
    read
done
