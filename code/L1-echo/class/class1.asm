org 7c00h

section .text
global _start

_start:
    mov     AX, 0x0
    mov     ES, AX
    mov     BL, 07h
    mov     CX, len
    mov     DH, 0Bh
    mov     DL, 16h
    mov     BP, string
    mov     AX, 1300h
    int     0x10

section .data
    string dd "(20x11) FAF-211 Arteom Kalamaghin"
    len equ $ - string