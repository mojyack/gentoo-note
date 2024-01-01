#!/bin/zsh

set -e

usage="genkernel.sh init BUILDDIR CONFIG
genkernel.sh make BUILDDIR
genkernel.sh install BUILDDIR TARGETDIR
genkernel.sh help
genkernel.sh MAKE_TARGET BUILDDIR"

# action_init BUILDDIR CONFIG
action_init() {
    if [[ $1 == "" || $2 == "" ]] {
        return 1
    }

    mkdir -p "$1"
    cp "$2" "$1/.config"
    echo "done"
}

# action_make BUILDDIR
action_make() {
    if [[ $1 == "" ]] {
        return 1
    }

    kmake=(make CC=clang LLVM=1 O=$1 -j$(nproc))
    pushd "$1"
    $kmake
    $kmake modules
    popd
}

# install_efi VMLINUZ TARGETDIR
install_efi() {
    if [[ $1 == "" || $2 == "" ]] {
        return 1
    }

    mkdir -p "$2/boot/EFI/BOOT"
    mkdir -p "$2/boot/EFI/Linux"
    if [[ -e $2/boot/EFI/BOOT/BOOTX64.EFI ]] {
        mv "$2/boot/EFI/BOOT/BOOTX64.EFI" "$2/boot/EFI/BOOT/BOOTX64.EFI.bak"
    }
    if [[ -e $2/boot/EFI/Linux/vmlinuz ]] {
        mv "$2/boot/EFI/Linux/vmlinuz" "$2/boot/EFI/Linux/vmlinuz.bak"
    }
    cp "$1" "$2/boot/EFI/Linux/vmlinuz"
    cp "$1" "$2/boot/EFI/BOOT/BOOTX64.EFI"
}

# install_pc VMLINUZ VERSION TARGETDIR
install_pc() {
    if [[ $1 == "" || $2 == "" || $3 == "" ]] {
        return 1
    }

    cp "$1" "$3/boot/vmlinuz-$2"
    ln -s -f "vmlinuz-$2" "$3/boot/vmlinuz-current"
}

# action_install BUILDDIR TARGETDIR
action_install() {
    if [[ $1 == "" || $2 == "" ]] {
        return 1
    }

    export INSTALL_MOD_PATH="$2"

    kmake=(make CC=clang LLVM=1 O=$1 -j$(nproc))

    $kmake modules_install

    VERSION=$($kmake --no-print-directory kernelversion)
    depmod -b "$2" "$VERSION"

    vmlinuz="$1/arch/x86_64/boot/bzImage"

    if [[ $(grep "CONFIG_EFI=" "$1/.config")  == "CONFIG_EFI=y" ]] {
        install_efi "$vmlinuz" "$2"
    } else {
        install_pc "$vmlinuz" "$VERSION" "$2"
    }
    echo "done"
}

# action_any MAKE_TARGET BUILDDIR
action_any() {
    make CC=clang LLVM=1 O="$2" -j$(nproc) "$1"
    echo "done"
}

if [[ $1 == "init" ]] {
    action_init $2 $3
} elif [[ $1 == "make" ]] {
    action_make $2
} elif [[ $1 == "install" ]] {
    action_install $2 $3
} elif [[ $1 == "help" ]] {
    echo "$usage"
} else {
    action_any "$1" "$2"
}
