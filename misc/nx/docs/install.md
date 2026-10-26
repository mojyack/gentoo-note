# format disk
- init sd card with init-disk.sh
- mark rootfs as bootable by `sgdisk -A 2:set:2 /dev/X`

# firmware blobs
## upstreamed
run firmware/install.sh
## gpu
from L4T R32.7.6:
copy `/lib/firmware/tegra21x/nvhost_nvdec020_ns.fw` as `nvidia/tegra210/nvdec.bin`
copy `/lib/firmware/tegra21x/vic04_ucode.bin` as `nvidia/tegra210/vic04_ucode.bin`
## bluetooth
run bluetooth/download-firmware.sh
copy `BCM.hcd` as `brcm/BCM4356A3.hcd`
copy `brcmfmac4356a3-pcie.txt` as `brcm/brcmfmac4356-pcie.nintendo,switch.txt`

# apps
## evmap
- clone `https://github.com/mojyack/evmaps.git`
- build
- `ln -s $PWD/release/joycon-desktop /usr/local/bin/joycon-desktop`
## wvkbd
- follow misc/wvkbd
- `ln -s $PWD/wvkbd-custom ~/bin/wvkbd-custom`
## misc
- link bin/*

# configurations
## BlueZ
General.FastConnectable = true
