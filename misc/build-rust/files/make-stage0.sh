#!/bin/bash
# $1 dir: /tmp/rust/build/stage0

# Generates dedicated rust sysroot for bootstrap.
#
# Arch installs rust into /usr, so `rustc --print sysroot` says /usr and
# bootstrap copies all of /usr/lib into build/<host>/stage0-sysroot.

set -euo pipefail
shopt -s nullglob

dir=${1:-/tmp/rust/build/stage0}
host=$(rustc -vV | sed -n 's/^host: //p')

rm -rf "$dir"
mkdir -p "$dir/bin" "$dir/lib/rustlib"

for tool in rustc rustdoc; do
    cat > "$dir/bin/$tool" <<EOF
#!/bin/sh
LD_LIBRARY_PATH=$dir/lib\${LD_LIBRARY_PATH:+:\$LD_LIBRARY_PATH} exec /usr/bin/$tool "\$@"
EOF
    chmod +x "$dir/bin/$tool"
done
ln -s /usr/bin/cargo /usr/bin/rustfmt /usr/bin/clippy-driver "$dir/bin/"

libs=(/usr/lib/librustc_driver-*.so /usr/lib/libstd-*.so)
cp -L "${libs[@]}" "$dir/lib/"
cp -rs "/usr/lib/rustlib/$host" /usr/lib/rustlib/etc "$dir/lib/rustlib/"

test "$("$dir/bin/rustc" --print sysroot)" = "$dir"
echo "stage0 sysroot: $dir ($("$dir/bin/rustc" --version))"
