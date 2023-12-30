#!/bin/zsh

source config

doas chown mojyack:mojyack $rootfs_image /dev/vfio/18 /dev/input/by-id/usb-Topre_Corporation_Realforce_87-event-kbd /sys/bus/pci/devices/0000:0b:00.0/config

sock="/tmp/spice.socket"

args=(
    -enable-kvm
    -cpu host
    -smp 8
    -m 4096
    -machine vmport=off
    -machine q35
    -nodefaults
    #-bios ovmf/OVMF.fd
    -net nic,model=virtio-net-pci
    -net user,hostfwd=tcp::5555-:5555
    -device virtio-tablet-pci
    -device virtio-keyboard-pci
    -object input-linux,id=kbd1,evdev=/dev/input/by-id/usb-Topre_Corporation_Realforce_87-event-kbd,grab_all=on,repeat=on
    -audiodev pa,id=snd0
    -device ich9-intel-hda
    -serial mon:stdio
    -no-reboot
    -kernel "$object_dir/kernel"
    -append 'root=/dev/ram0 SRC=/ console=ttyS0 loglevel=3 mitigations=off loglevel=7 androidboot.selinux=permissive audit=0 HWC=drmfb GRALLOC=minigbm_gbm_mesa DEBUG=2'
    -initrd "$object_dir/initrd.img"
    -drive file=$rootfs_image,format=raw,if=virtio #,cache=none
    #-cdrom archlinux-2023.12.01-x86_64.iso
)

gtk_args=(
    #-spice unix=on,gl=on,addr=$sock,disable-ticketing=on
    -display gtk,gl=on,show-cursor=on
    -device virtio-vga-gl,xres=1920,yres=1080
)

gpu_args=(
    -vga none
    -nographic
    -device vfio-pci,host=0b:00.0,multifunction=on,x-vga=on
)

qemu-system-x86_64 ${args[@]} ${gpu_args[@]} #&
exit 0
pid=$!
remote-viewer "spice+unix://$sock"
kill $pid
