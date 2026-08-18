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
llvm_slot=${llvm_slot:-$(llvm-config --version | cut -d . -f 1)}
workdir=$(realpath "distccd-$1-$llvm_slot")

# setup cross tools
mkdir "$workdir"

# $1 clang/clang++
create_file() {
    cc=$1
    echo "#!/bin/sh\nexec \"$(command -v $cc-$llvm_slot || command -v $cc)\" --target=$tuple -Wno-gnu-line-marker \"\$@\"" > $workdir/$tuple-$cc
    chmod +x "$workdir/$tuple-$cc"
    ln -s "$tuple-$cc" "$workdir/$cc"
    ln -s "$tuple-$cc" "$workdir/$cc-$llvm_slot"
    ln -s "$tuple-$cc" "$workdir/$tuple-$cc-$llvm_slot"
}
create_file clang
create_file clang++

# run distccd
args=(
    --daemon
    --log-file=$workdir/log
    --enable-tcp-insecure
    --jobs 80
    --allow 127.0.0.1
    --allow 192.168.1.0/24
    --allow 192.168.128.0/22
)
PATH=$workdir:$PATH exec distccd $args &
touch "$workdir/log"
tail -f "$workdir/log" &

echo ready
read

pkill -f "$workdir"
rm -r "$workdir"
