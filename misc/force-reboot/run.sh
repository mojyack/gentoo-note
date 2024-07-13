#!/bin/zsh

if [[ ! -x ./force-reboot ]]; then
    clang force-reboot.c -o force-reboot
fi

doas ./force-reboot
