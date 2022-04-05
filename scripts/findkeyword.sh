#!/bin/bash

# list_packages $THREAD_ID $TOTAL_CORES $PACKAGES
list_packages() {
    packages=($3)
    for ((i = $1; i < ${#packages[@]}; i+=$2)) {
        package=${packages[i]}
        keywords="$(equery m -k "${package}")"
        if [[ $keywords == *"~amd64"* && $keywords != *"~amd64-linux"* ]]; then
            echo "$package"
        fi
    }
}

cores=$(grep -c '^processor' /proc/cpuinfo)
packages=$(equery l '*/*')
for ((i = 0; i < $cores; i+=1)); do
    list_packages $i $cores "$packages" &
done
