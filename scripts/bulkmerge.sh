#!/bin/bash

while read package; do
    if [[ ${package:0:1} == "#" ]]; then
        continue
    fi
    echo -n $package >&2
    if { emerge -1 $package 2>&1 >/dev/null; }; then
        echo " SUCCESS" >&2
        echo "#$package"
    else
        echo " ERROR" >&2
        echo "$package"
    fi
done
