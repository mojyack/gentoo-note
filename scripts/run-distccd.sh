#!/bin/zsh

# setup compiler symlinks and run distccd
# $1 target architecture(arm,arm64|aarch64)

set -e

if [[ $1 == arm ]]; then
    tuple="armv6j-unknown-linux-musleabihf"
elif [[ $1 == arm64 || $1 == aarch64 ]]; then
    tuple="aarch64-unknown-linux-musl"
elif [[ $1 == ppc64 || $1 == powerpc64 ]]; then
    tuple="powerpc64-unknown-linux-musl"
else
    echo "unknown arch $1"
    exit 1
fi

clang_base="$(realpath $(clang -print-resource-dir))"
llvm_slot=$(llvm-config --version | cut -d . -f 1)

# setup cross tools
mkdir -p "cross"

## clang
echo "#!/bin/sh
exec \"$(which clang)\" --target=$tuple \"\$@\"" > cross/$tuple-clang
echo "#!/bin/sh
exec \"$(which clang++)\" --target=$tuple \"\$@\"" > cross/$tuple-clang++
for file in cross/*clang*; {
    chmod +x "$file"
    ln -s "${file:t}" "$file-$llvm_slot"
}

# distcc
doas ln -s /usr/bin/distccd /usr/lib/distcc/$tuple-clang
doas ln -s /usr/bin/distccd /usr/lib/distcc/$tuple-clang++
doas ln -s /usr/bin/distccd /usr/lib/distcc/$tuple-clang-$llvm_slot
doas ln -s /usr/bin/distccd /usr/lib/distcc/$tuple-clang++-$llvm_slot

args=(
    --daemon
    --log-file=/tmp/distccd
    --enable-tcp-insecure
    --jobs 80
    --allow 127.0.0.1
    --allow 192.168.1.0/24
)
PATH=$PWD/cross:$PATH exec distccd $args &
echo ok
read
killall distccd

doas unlink /usr/lib/distcc/$tuple-clang
doas unlink /usr/lib/distcc/$tuple-clang++
doas unlink /usr/lib/distcc/$tuple-clang-$llvm_slot
doas unlink /usr/lib/distcc/$tuple-clang++-$llvm_slot

rm -r cross

exit 0
