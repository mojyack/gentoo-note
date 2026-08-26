#!/bin/bash

iself() {
    if [[ $1 == *.a || $1 == *.o || $1 == *.so || $(head -c 4 "$1" | tr -d '\0') == $'\x7f'ELF ]]; then
        return 0
    else
        return 1
    fi
}

for pkg in $(qlist -I); do
    echo ... $pkg >&2
    for file in $(qlist $pkg | sort); do
        if iself "$file"; then
            echo $pkg
            break
        fi
    done
done
