#!/bin/zsh

export SDL_VIDEODRIVER=wayland

if [[ -e /tmp/vgpu ]] {
    UUID=$(cat /tmp/vgpu)
} else {
    doas modprobe kvmgt
    UUID=$(uuidgen)
    echo $UUID > /tmp/vgpu
    echo $UUID | doas tee "/sys/devices/pci0000:00/0000:00:02.0/mdev_supported_types/i915-GVTg_V5_4/create" > /dev/null
    doas chmod 666 /dev/vfio/*
}

# create samba sharing.
(sleep 10 && ./samba) &

# launch qemu.
SPICE_SOCK="/tmp/spice-${UUID}.socket"
qemu-system-x86_64 \
-cpu host,kvm=off \
-smp cores=2,threads=2,sockets=1,maxcpus=4 \
-m 4G \
-M graphics=off -vga none \
-enable-kvm \
-spice unix=on,gl=on,addr="${SPICE_SOCK}",disable-ticketing=on \
-device virtio-serial-pci -device virtserialport,chardev=spicechannel0,name=com.redhat.spice.0 -chardev spicevmc,id=spicechannel0,name=vdagent \
-device vfio-pci-nohotplug,sysfsdev="/sys/bus/mdev/devices/${UUID}",display=on,x-igd-opregion=on,ramfb=on \
-usb -device usb-tablet \
-machine type=q35,accel=kvm,kernel_irqchip=on \
-device ich9-intel-hda,bus=pcie.0,addr=0x1b \
-device hda-micro,audiodev=hda \
-audiodev pa,id=hda,server=unix:/run/user/$(id -u)/pulse/native \
-drive file=image,index=0,media=disk,if=virtio \
-serial none \
-parallel none \
-boot order=c \
-net user,smb="/home/mojyack" \
-net nic,model=virtio &

remote-viewer "spice+unix://${SPICE_SOCK}"

# delete gpu.
echo 1 | doas tee "/sys/bus/pci/devices/0000:00:02.0/${UUID}/remove" > /dev/null

#-display gtk,gl=on,zoom-to-fit=off,grab-on-hover=on,show-cursor=on \
#-usb -device usb-tablet \
#-device ich9-intel-hda \
#-device hda-output,audiodev=card0 \
#-device hda-micro,audiodev=hda \
#-device ich9-intel-hda,bus=pcie.0,addr=0x1b \
#-audiodev pa,id=snd0,out.buffer-length=10000 \
#-device intel-hda -device hda-output,audiodev=snd0 \
#-drive file="/run/media/mojyack/WINDOWSME/try1.iso",index=1,media=cdrom \
#-drive file="virtio.iso",index=2,media=cdrom \
#-device usb-ehci,id=ehci -device usb-host,bus=ehci.0,vendorid=0x0781,productid=0x5583 \
#-net user,smb="/run/media/mojyack/98CD-99C0" \
#-net nic,model=virtio \
#-drive if=pflash,format=raw,unit=0,file=OVMF_CODE.fd,readonly=on \
#-drive if=pflash,format=raw,unit=1,file=OVMF_VARS.fd \
#-machine type=q35,accel=kvm,kernel_irqchip=on \
