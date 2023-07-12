#!/bin/zsh

set -e

if [[ $# != 2 ]] {
    echo "invalid usage"
    exit 1
}

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

exit 0
