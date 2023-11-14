org 7c00h

section .text
    global _start

_start:
    mov     AX, 0
    mov     ES, AX
    mov     BP, msg
    mov     CX, 17          ; 17 characters to display
    mov     DH, 02h         ; On the 2th row
    mov     DL, DH          ; In the 2th column
    mov     AX, 1302h
    int     0x10

section .data1
    msg db '+', 01h, 'R', 02h, 'T', 13h, 'E', 14h, 'O', 25h, 'M', 26h, ' ', 00h, 'K', 81h, 'A', 82h, 'L', 93h, 'A', 94h, 'M', 05h, 'A', 06h, 'G', 07h, 'H', 01h, 'I', 02h, 'N', 03h