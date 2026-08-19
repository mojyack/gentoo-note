#!/bin/bash
# $1 builddir: /tmp/rust/build
# $2 prefix: /tmp/rust/prefix

set -euo pipefail

repo=$HOME/build/thirdparty/rust
files="${BASH_SOURCE[0]%/*}"
build=${1:-/tmp/rust/build}
prefix=${2:-/tmp/rust/prefix}
sysroot=$(rustc --print sysroot)

if [[ $sysroot == /usr ]]; then
    "$files/make-stage0.sh" "$build/stage0"
    sysroot=$build/stage0
fi

sed -e "s|%sysroot%|$sysroot|" \
    -e "s|%prefix%|$prefix|" \
    -e "s|%build%|$build|" \
    "$files/bootstrap.toml" > "$repo/bootstrap.toml"

echo "run \"$repo/x install\""
