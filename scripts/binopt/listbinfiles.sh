#!/bin/zsh

# $1 file
iself() {
    if [[ $1 == *.a || $1 == *.o || $1 == *.so || $(head -c 4 "$1") == $'\x7f'ELF ]]; then
        return 0
    else
        return 1
    fi
}

for file in /lib/**/*(.); do
    if [[ ! -r $file || $file == /lib/modules/* || $file == /lib/firmware/* ]]; then
        continue
    fi
    if iself "$file"; then
        echo "$file"
    fi
done

for file in /bin/**/*(.); do
    if [[ ! -r $file ]]; then
        continue
    fi
    if iself "$file"; then
        echo "$file"
    fi
done
