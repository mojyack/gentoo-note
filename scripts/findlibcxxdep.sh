#!/bin/bash

# list_packages $THREAD_ID $TOTAL_CORES $PACKAGES
list_packages() {
    packages=($3)
    for ((i = $1; i < ${#packages[@]}; i+=$2)) {
        package=${packages[i]}
        for file in $(qlist $package); do
            if [[ ! -f $file ]]; then
                continue
            fi
            if ldd "$file" 2>/dev/null | grep -q libc++; then
                echo $package $file
                break
            fi
        done
    }
}

cores=$(grep -c '^processor' /proc/cpuinfo)
packages=$(qlist -I)
for ((i = 0; i < $cores; i++)); do
    list_packages $i $cores "$packages" &
done
