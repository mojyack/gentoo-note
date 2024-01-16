#!/bin/zsh

function sha1sumd() {
    if [[ -d "$1" ]]; then
        cd "$1"
        find . -type f \( -exec sha1sum {} \; \) | sort | sha1sum
    else
        sha1sum "$1"
    fi
}

root=$1
backup=$2

if [[ ! -n $root || ! -n $backup ]]; then
    echo "not enough arguments"
    exit 1
fi
if [[ ! -e $backup ]]; then
    echo "backup record not exits"
    exit 1
fi

while read line; do
    line=(${=line})
    sha1=$line[1]
    file=$line[2]

    src=$root$file
    if [[ ! -e $src ]]; then
        echo "file $src not exits, skipping"
        continue
    fi
    if [[ ! -e $src.bak ]]; then
        echo "file $src.bak not exits, skipping"
        continue
    fi

    new_sha1=($(sha1sumd "$src"))
    new_sha1=$new_sha1[1]
    # echo $sha1 $new_sha1
    if [[ $sha1 != $new_sha1 ]]; then
        echo "$file updated, removing backup"
        rm -rf "$src.bak"
        continue
    fi

    echo "restoring $file"
    rm -rf "$src" && mv "$src.bak" "$src"
done < "$backup"
