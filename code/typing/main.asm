go:
    call typing

typing:
    mov     AH, 0x0
    int     0x16

    cmp     AL, 0x8
    je      handle_backspace

    mov     AH, 0xE
    int     0x10

    mov     AX, [column]
    mov     BX, 1
    add     AX, BX
    mov     [column], AX

    jmp typing

handle_backspace:

section .bss
    row     resb 4
    column  resb 4