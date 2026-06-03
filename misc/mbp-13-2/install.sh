#!/bin/bash
files=$(realpath files)

ln -s $files/sway /home/mojyack/bin/
ln -s $files/suspend-hook /usr/local/bin

mkdir -p /etc/modprobe.d
ln -s $files/modprobe.conf /etc/modprobe.d
