section .text
    global  _start

_start:
    xor     ax, ax
    mov     es, ax
    mov     bp, test_string
    add     bp, 7c00h

    mov     bh, 0
    mov     dh, 0
    mov     dl, 0

    mov     bl, 07h
    lea     si, test_string_len
    add     si, 7c00h
    mov     cx, [si]

    mov     ax, 1301h
    int     10h

    jmp     $

section .data
    test_string         dd "TEST"
    test_string_len     dd 4