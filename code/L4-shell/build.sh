#!/bin/bash

rm -f floppy.img

nasm -f bin -o fs_bootloader.com fs_bootloader.asm
truncate -s 1474560 fs_bootloader.com
mv fs_bootloader.com floppy.img

nasm -f bin -o ss_bootloader.com ss_bootloader.asm
dd if=ss_bootloader.com of=floppy.img bs=512 count=2 seek=1 conv=notrunc
echo -n -e '\x46\x46' | dd of=floppy.img bs=1 count=2 seek=1534 conv=notrunc
rm -f ss_bootloader.com

nasm -f bin -o main.com main.asm
dd if=main.com of=floppy.img bs=512 count=2 seek=36 conv=notrunc
echo -n -e '\x41\x4d\x4f\x47\x55\x53' | dd of=floppy.img bs=1 count=6 seek=19450 conv=notrunc
rm -f main.com

# seek=1015
# seek=520698