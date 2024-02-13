#!/bin/zsh

while read file; do
    if ! qfile "$file" | cut -d ':' -f 1; then
        echo "$file" orphaned >&2
    fi
done
