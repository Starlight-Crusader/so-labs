org 7c00h

section .text
global _start

_start:
    mov     AX, 0x0
    mov     ES, AX
    mov     BL, 07h
    mov     CX, len         ; len characters to display
    mov     DH, 0Dh         ; On the 13th row
    mov     DL, 19h         ; In the 22th column
    mov     BP, string
    mov     AX, 1301h
    int     0x10


section .data
    string dd "FAF-211 Arteom Kalamaghin"
    len equ $ - string
