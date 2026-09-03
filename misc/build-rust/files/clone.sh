#!/bin/bash

set -euo pipefail

repo=$HOME/build/thirdparty/rust
commit=31fca3adb283cc9dfd56b49cdee9a96eb9c96ffd  # 1.96.1
commit=8bab26f4f68e0e26f0bb7960be334d5b520ea452  # 1.97.1

if [[ ! -e $repo/.git ]]; then
    git clone --depth=10000 https://github.com/rust-lang/rust.git "$repo"
fi
cd "$repo"
git fetch origin $commit
git checkout FETCH_HEAD
