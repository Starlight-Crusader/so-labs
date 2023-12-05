#!/bin/bash

rm -f floppy.img

nasm -f bin -o bootloader.com bootloader.asm
truncate -s 1474560 bootloader.com
echo -n -e '\x55\xAA' | dd of=bootloader.com bs=1 count=510 seek=510 conv=notrunc
mv bootloader.com floppy.img

nasm -f bin -o main.com main.asm
dd if=main.com of=floppy.img bs=512 seek=1 conv=notrunc
echo -n -e '\x41\x4d\x4f\x47\x55\x53' | dd of=floppy.img bs=1 count=1530 seek=1530 conv=notrunc 
rm -f main.com
