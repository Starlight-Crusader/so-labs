org 100h

section .data
row db 0 ; Variable to store the current row
col db 0 ; Variable to store the current column

section .text
go:
    call typing

typing:
    mov     AH, 0x0
    int     0x16

    ; Check for backspace (ASCII value 8)
    cmp     AL, 8
    je      handle_backspace

    ; Check for Enter (ASCII value 13)
    cmp     AL, 13
    je      new_line

    mov     AH, 0xE
    int     0x10

    ; Update the cursor position
    inc     byte [col]
    mov     AH, 0x02
    mov     BH, 0
    mov     DL, byte [col]
    mov     DH, byte [row]
    int     0x10

    jmp     typing

handle_backspace:
    ; Move the cursor back by one position if not at the beginning of the line
    cmp     byte [col], 0
    je      typing ; Do nothing if at the beginning
    dec     byte [col]
    mov     AH, 0x02
    mov     BH, 0
    mov     DL, byte [col]
    mov     DH, byte [row]
    int     0x10

    ; Print a space to erase the character
    mov     AH, 0x0E
    mov     AL, ' '  ; ASCII value for space
    int     0x10

    ; Move the cursor back to the original position
    mov     AH, 0x02
    mov     BH, 0
    mov     DL, byte [col]
    mov     DH, byte [row]
    int     0x10

    jmp     typing

new_line:
    ; Handle the Enter key by moving to the next line and resetting the column
    mov     byte [col], 0
    inc     byte [row]
    mov     AH, 0x02
    mov     BH, 0
    mov     DL, byte [col]
    mov     DH, byte [row]
    int     0x10

    jmp     typing