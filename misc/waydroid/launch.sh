#!/bin/zsh

modprobe loop fuse
doas sed -i 's/lxc.apparmor.profile/#/' /var/lib/waydroid/lxc/waydroid/config
doas sed -i 's/ro.hardware.vulkan/#/' /var/lib/waydroid/waydroid_base.prop

doas systemctl restart waydroid-container.service
waydroid session start &
pid=$!
waydroid show-full-ui &
echo "android launched..."
read
kill $pid
doas systemctl stop waydroid-container.service
