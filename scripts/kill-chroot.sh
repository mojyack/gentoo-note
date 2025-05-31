#!/bin/zsh
# $1 root

if [[ -z $1 ]]; then
    echo "invalid argument"
    exit 1
fi

cd /proc
for proc in */; do
    pid=${proc[1,-2]}
    if [[ $pid != [[:digit:]]* || $pid == $$ ]]; then
        continue
    fi
    root=$(readlink $pid/root)
    if [[ $root == $1 ]]; then
        read cmdline < $pid/cmdline
        echo "$cmdline kill $pid?"
        read res
        if [[ $res == y ]]; then
            kill -KILL $pid
        fi
    fi

done
