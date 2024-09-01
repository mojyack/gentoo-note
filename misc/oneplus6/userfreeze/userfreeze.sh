#!/bin/zsh

trigger="/dev/input/by-path/platform-c440000.spmi-platform-c440000.spmi:pmic@0:pon@800:pwrkey-event"
wait_bin=${0:a:h}/wait

stopped=()

cd /proc
for proc in */; do
    pid=${proc[1,-2]}
    if [[ $pid != [[:digit:]]* || $pid == $$ ]]; then
        continue
    fi

    if ! pushd $pid >/dev/null 2>/dev/null; then
        continue
    fi

    read stat < stat
    stat=( ${(z)stat} )
    state=${stat[3]}
    if [[ $state == "T" ]]; then
        popd
        continue
    fi

    stopped=( $stopped $pid )
    kill -STOP $pid

    popd
done

$wait_bin $trigger

for pid in $stopped; do
    kill -CONT $pid
done
