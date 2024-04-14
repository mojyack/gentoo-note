#!/bin/zsh

flush () {
    dd if=/dev/loop0p$1 of=/dev/nbd0p$1
}

flush_rom () {
    dd if=update/$1.img of=/dev/nbd0p$(($2+0))
}

#flush_rom xbl 1
#flush_rom xbl_config 2
#exit 0

flush_rom aop 1
flush_rom tz 2
flush_rom hyp 3
flush_rom abl 8
flush_rom keymaster 10
flush_rom cmnlib 12
flush_rom cmnlib64 13
flush_rom devcfg 14
flush_rom qupfw 15
flush_rom vbmeta 17
flush_rom storsec 19
flush_rom LOGO 20
flush_rom fw_4j1ed 21
flush_rom fw_4u1ea 22

exit 0

flush 1
flush 2
flush 3
flush 8
flush 10
flush 12
flush 13
flush 14
flush 15
flush 17
flush 19
flush 20
flush 21
flush 22
flush 23
flush 24
flush 25
flush 26
flush 27
flush 28
