#!/bin/zsh

if (( $# < 2 )); then
    echo "too few arguments"
    exit 1
fi

if (( $UID != 0 )); then
    echo "please run as root"
    exit 1
fi

panic() {
    echo "panic!"
    exit 1
}

sync=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--sync)
            sync=1
            shift
            ;;
        *)
            if [[ -z ${client+x} ]]; then
                client="$1"
            elif [[ -z ${mount+x} ]]; then
                mount="$1"
            fi
            shift
            ;;
    esac
done

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

mount --types proc /proc "$mount/proc" || panic
mount --rbind /sys "$mount/sys" || panic
mount --make-rslave "$mount/sys" || panic
mount --rbind /dev "$mount/dev" || panic
mount --make-rslave "$mount/dev" || panic
mount --rbind /run "$mount/run" || panic
mount --make-rslave "$mount/run" || panic
mount -t tmpfs tmpfs "$mount/tmp" || panic

if [[ $sync == 1 ]]; then
    rsync -a /var/db/repos/gentoo "$mount/var/db/repos/" || panic
    emerge --sync
fi
chroot "$mount" $(awk -F: -v user="root" '$1 == user {print $NF}' "$mount/etc/passwd") || panic

umount -l "$mount/dev" || panic
if [[ $boot == 1 ]]; then
    umount -R "$mount/boot" || panic
fi
umount -R "$mount" || panic
