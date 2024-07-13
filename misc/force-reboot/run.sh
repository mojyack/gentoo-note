#!/bin/zsh

if [[ ! -x ./force-reboot ]]; then
    clang force-reboot.c -o force-reboot
fi

echo doas ./force-reboot
