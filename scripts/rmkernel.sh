#!/bin/zsh

current=$(uname -r)
for v ($(ls /lib/modules/)) {
    if [[ $current != $v ]]; then
        rm -rf /lib/modules/$v
        rm -rf /usr/src/linux-$v
    fi
}
