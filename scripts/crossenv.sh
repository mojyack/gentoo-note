#!/bin/zsh

set -e

if [[ $# < 1 ]] {
    echo "invalid usage"
    exit 1
}

mount -t tmpfs tmpfs "$1/tmp"

env \
    PORTAGE_CONFIGROOT="$1" \
    SYSROOT="/" \
    ROOT="$1" \
    CHOST=x86_64-pc-linux-gnu \
    CBUILD=x86_64-pc-linux-gnu \
    HOSTCC=clang \
    HOSTCXX=clang++ \
    PKGDIR="/var/cache/binpkgs$2" \
    zsh \
|| true

umount "$1/tmp"

exit 0
