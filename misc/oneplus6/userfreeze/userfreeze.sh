#!/bin/zsh

trigger="/dev/input/by-path/platform-c440000.spmi-platform-c440000.spmi:pmic@0:pon@800:pwrkey-event"
wait_bin=${0:a:h}/wait

targets=()

cd /proc
for proc in */; do
    pid=${proc[1,-2]}
    if [[ $pid != [[:digit:]]* || $pid == $$ ]]; then
        continue
    fi
    read stat < $pid/stat
    stat=( ${(z)stat} )
    state=${stat[3]}
    if [[ $state == "T" ]]; then
        continue
    fi
    targets=( $targets $pid )
    kill -STOP $pid
done

$wait_bin $trigger

for pid in $targets; do
    kill -CONT $pid
done