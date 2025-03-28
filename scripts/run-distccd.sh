#!/bin/zsh

# setup compiler symlinks and run distccd
# $1 target architecture(arm,arm64|aarch64)

set -e

if [[ $1 == arm ]]; then
    tuple="armv6j-unknown-linux-musleabihf"
elif [[ $1 == arm64 || $1 == aarch64 ]]; then
    tuple="aarch64-unknown-linux-musl"
elif [[ $1 == amd64 ]]; then
    tuple="x86_64-pc-linux-musl"
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

# $1 clang/clang++
create_file() {
    cc=$1
    echo "#!/bin/sh\nexec \"$(which $cc)\" --target=$tuple \"\$@\"" > cross/$tuple-$cc
    chmod +x "cross/$tuple-$cc"
    ln -s "$tuple-$cc" "cross/$tuple-$cc-$llvm_slot"
    ln -s "$tuple-$cc" "cross/$cc-$llvm_slot"
}
create_file clang
create_file clang++

# run distccd
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

rm -r cross

exit 0
