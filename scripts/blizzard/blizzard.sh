#!/bin/zsh
# $@ wakeup source device files

panic() {
    echo "fail: $@"
    exit 1
}

# compile wait-events
wait_bin=/var/cache/wait-events
if [[ ! -e $wait_bin ]]; then
    c++ -std=c++20 -O2 -o "$wait_bin" ${0:a:h}/wait.cpp || panic "c++"
fi

# setup cgroup
cgroup=/sys/fs/cgroup
blizzard=$cgroup/blizzard
mountpoint -q $cgroup || mount -t cgroup2 none $cgroup || panic "cgroup"
if [[ ! -e $blizzard ]]; then
    mkdir $blizzard || panic
fi

# list targets
local -A original_cgroups
for proc in /proc/*; do
    pid=${proc:t}
    if [[ $pid != [[:digit:]]* || $pid == $$ || ! -e /proc/$pid/exe ]]; then
        continue
    fi
    tmp=$(</proc/$pid/cgroup)
    tmp=${tmp[4,-1]}
    if [[ $tmp != "/" ]]; then
        original_cgroups[$pid]=$tmp
    fi
    { echo $pid > $blizzard/cgroup.procs } 2>/dev/null
done

# freeze
echo 1 > $blizzard/cgroup.freeze
"$wait_bin" "$@"
echo 0 > $blizzard/cgroup.freeze

# restore original cgroup
for pid in $(cat $blizzard/cgroup.procs); do
    orig=${original_cgroups[$pid]}
    { echo $pid > $cgroup$orig/cgroup.procs } 2>/dev/null
done
