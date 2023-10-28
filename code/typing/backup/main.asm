go:
    call typing

typing:
    mov     AH, 0x0
    int     0x16

    ; Check for backspace (ASCII value 8)
    cmp     AL, 0x8
    je      handle_backspace

    mov     AH, 0xE
    int     0x10

    jmp typing

handle_backspace:
; Move the cursor back by one position
    mov     AH, 0x0
    mov     AL, 0x8
    int     0x10

    ; Print a space to erase the character
    mov     AH, 0x0E
    mov     AL, ' '  ; ASCII value for space
    int     0x10

    ; Move the cursor back again
    mov     AH, 0x0
    mov     AL, 0x8
    int     0x10

    jmp     typing