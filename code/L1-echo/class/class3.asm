org 7c00h

section .text
    global _start

_start:
    mov     AX, 0
    mov     ES, AX
    mov     BP, msg
    mov     CX, 17
    mov     DH, 17
    mov     DL, 30
    mov     AX, 1302h
    int     0x10

section .data
    msg db 'A', 01h, 'R', 02h, 'T', 03h, 'E', 04h, 'O', 05h, 'M', 06h, ' ', 00h, 'K', 01h, 'A', 02h, 'L', 03h, 'A', 04h, 'M', 05h, 'A', 06h, 'G', 07h, 'H', 01h, 'I', 02h, 'N', 03h