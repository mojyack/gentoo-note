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
files_script=$2
backup=$3

if [[ ! -n $root || ! -n $backup ]]; then
    echo "not enough arguments"
    exit 1
fi
if [[ -e $backup ]]; then
    echo "backup record exits"
    exit 1
fi

source $files_script

for file in $files; do
    if [[ ! -e $file ]]; then
        echo "file $file is missing in host, skipping"
        continue
    fi

    src=$root$file
    if [[ ! -e $src ]]; then
        echo "file $src not exits, skipping"
        continue
    fi

    if [[ -e $src.bak ]]; then
        echo "file $src.bak exits, unable to create backup"
        continue
    fi

    sha1=($(sha1sumd "$file"))
    sha1=$sha1[1]
    echo $sha1 "$file" >> "$backup"

    echo "masking $file"
    
    mv "$src" "$src.bak" && cp -r "$file" "$src"
done

