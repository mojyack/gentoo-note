#!/bin/zsh

source config

# for virtiofs
virtiofs_sock=/tmp/qemu-virtiofs.sock


doas chown mojyack:mojyack $own_files
/usr/libexec/virtiofsd --socket-path=$virtiofs_sock --shared-dir=$HOME/working &

base=(
    -cpu host,kvm=off
    -enable-kvm
    -smp 8
    -m ${mem}
    -machine vmport=off
    -machine q35
    -nodefaults
    -no-reboot
)

efi=(
    -drive if=pflash,format=raw,readonly=on,file=ovmf/OVMF_CODE.fd
    -drive if=pflash,format=raw,file=OVMF_VARS.fd
)

net=(
    -net nic,model=virtio-net-pci
    -net user,hostfwd=tcp::5555-:5555
)

evdev=(
    -object input-linux,id=kbd1,evdev=/dev/input/by-id/$input_keyboard,grab_all=on,repeat=on,grab-toggle=ctrl-ctrl
    -object input-linux,id=mouse1,evdev=/dev/input/by-id/$input_mouse
)

drive=(
    -drive file=drive.qcow2,format=qcow2,if=virtio,cache=none
    #-drive file=data,format=raw,if=virtio,cache=none
    #-drive file=current.iso,media=cdrom
    #-drive file=virtio-win.iso,media=cdrom
)

gtk=(
    -display gtk,gl=on,show-cursor=on
    -device virtio-vga-gl,xres=1920,yres=1080
)

gpu=(
    -vga none
    -nographic
)

if [[ -n $gpu_audio_pci_id ]]; then
    gpu=(
        $gpu
        -device pcie-root-port,id=gpu_root_port,chassis=0,slot=0,bus=pcie.0 \
        -device vfio-pci,bus=gpu_root_port,addr=00.0,host=$gpu_pci_id,x-vga=on,multifunction=on,romfile=$gpu_rom
        -device vfio-pci,bus=gpu_root_port,addr=00.1,host=$gpu_audio_pci_id
    )
else
    gpu=(
        $gpu
        -device vfio-pci,host=$gpu_pci_id,x-vga=on,romfile=$gpu_rom
    )
fi

audio=(
    -audiodev pa,id=snd0
    -device ich9-intel-hda
    -device hda-output,audiodev=snd0
)

virtiofs=(
    -object memory-backend-memfd,id=mem,size=$mem,share=on
    -numa node,memdev=mem
    -chardev socket,id=char0,path=$virtiofs_sock
    -device vhost-user-fs-pci,chardev=char0,tag=share
)

stdio=(
    -serial mon:stdio
)
 
qemu-system-x86_64 $base $efi $evdev $gpu $audio $net $drive $virtiofs
