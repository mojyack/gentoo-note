#!/bin/zsh

source config

# build -cpu option
cpu_opts=host,hv_passthrough
if [[ $(grep -m 1 'vendor_id' /proc/cpuinfo | awk '{print $3}') == "AuthenticAMD" ]]; then
    cpu_opts="$cpu_opts,topoext"
fi

# build -smp option
sockets=$(lscpu | grep "^Socket(s):" | awk '{print $2}')
cores_per_socket=$(lscpu | grep "Core(s) per socket:" | awk '{print $4}')
threads_per_core=$(lscpu | grep "Thread(s) per core:" | awk '{print $4}')
total_cpus=$(( sockets * cores_per_socket * threads_per_core ))
smp_opts="${total_cpus},sockets=${sockets},cores=${cores_per_socket},threads=${threads_per_core}"

# setup hugepages
hugepages_sysfs="/sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages"
orig_hugepages=$(<$hugepages_sysfs)
echo $(( orig_hugepages + (mem * 1024 + 256) / 2 )) | doas tee $hugepages_sysfs

# setup virtiofs
virtiofs_sock=/tmp/qemu-virtiofs.sock
doas chown mojyack:mojyack $own_files
/usr/libexec/virtiofsd --socket-path=$virtiofs_sock --shared-dir=$HOME/working &


base=(
    -cpu $cpu_opts
    -enable-kvm
    -smp $smp_opts
    -m ${mem}G
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
    -net user,hostfwd=tcp::5555-:5555,hostfwd=udp::5555-:5555
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
    -object memory-backend-memfd,id=mem,size=${mem}G,share=on,hugetlb=on,hugetlbsize=2M,prealloc=on
    -numa node,memdev=mem
    -chardev socket,id=char0,path=$virtiofs_sock
    -device vhost-user-fs-pci,chardev=char0,tag=share
)

stdio=(
    -serial mon:stdio
)
 
qemu-system-x86_64 $base $efi $evdev $gpu $audio $net $drive $virtiofs $qemu_args

# restore hugepages setting
echo $orig_hugepages | doas tee $hugepages_sysfs
