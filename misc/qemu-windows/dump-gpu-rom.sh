#!/bin/sh

set -e

dev=$1

cd /sys/bus/pci/drivers/vfio-pci
echo $dev > unbind

pushd /sys/bus/pci/devices/$dev
echo 1 > enable
echo 1 > rom
cat rom > /tmp/vbios.rom
echo 0 > rom
echo 0 > enable
popd

echo $dev > bind
