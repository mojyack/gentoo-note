#!/bin/bash

mkdir -p brcm
cp -L $1/brcm/brcmfmac4356-pcie.{bin,clm_blob} brcm

mkdir -p nvidia/tegra210
cp -rL $1/nvidia/gm20b nvidia
cp -L $1/nvidia/tegra210/xusb.bin nvidia/tegra210

mkdir -p rtl_nic
cp -L $1/rtl_nic/rtl8153b-2.fw rtl_nic
