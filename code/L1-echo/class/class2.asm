org 7c00h

section .text
global _start

_start:
    mov     AX, 0x0
    mov     ES, AX
    mov     BL, 07h
    mov     CX, len
    mov     DH, 0Dh
    mov     DL, 19h
    mov     BP, string
    mov     AX, 1301h
    int     0x10

section .data
    string dd "FAF-211 Arteom Kalamaghin"
    len equ $ - string                      ; Calculates a wrong number