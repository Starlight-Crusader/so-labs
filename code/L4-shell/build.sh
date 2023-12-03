#!/bin/bash

rm -f floppy.img

nasm -f bin -o temp_bl.com temp_bl.asm
truncate -s 1474560 temp_bl.com
mv temp_bl.com floppy.img

nasm -f bin -o main.com main.asm
dd if=main.com of=floppy.img bs=512 seek=1 conv=notrunc
rm -f main.com