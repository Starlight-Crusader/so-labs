org 7c00h

section .text
    global _start

_start:
    mov     AX, 0
    mov     ES, AX
    mov     BP, msg
    mov     CX, 17          ; 17 characters to display
    mov     DH, 17          ; On the 2th row
    mov     DL, 30         ; In the 22th column
    mov     AX, 1302h
    int     0x10

section .data
    msg db 'A', 01h, 'R', 02h, 'T', 03h, 'E', 04h, 'O', 05h, 'M', 06h, ' ', 00h, 'K', 01h, 'A', 02h, 'L', 03h, 'A', 04h, 'M', 05h, 'A', 06h, 'G', 07h, 'H', 01h, 'I', 02h, 'N', 03h