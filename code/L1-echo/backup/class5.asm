org 7c00h

section .text
    global _start

_start:
    mov     AX, 0xB830      ; Pointer to Video memory
    mov     ES, AX          ; Equal es to ax to video memory
    xor     DI, DI          ; Offset (B800:0000) - offset to write characters to video memory pointer
    
    mov     AX, 'A'         ; Character to print
    stosb                   ; Write the character to the memory 
    mov     AX, 01h         ; Text color (cyan) on black
    stosb                   ; Write the attribute to the memory

    mov     AX, 'R'
    stosb
    mov     AX, 02h
    stosb

    mov     AX, 'T'
    stosb
    mov     AX, 03h
    stosb

    mov     AX, 'E'
    stosb
    mov     AX, 04h
    stosb

    mov     AX, 'O'
    stosb
    mov     AX, 05h
    stosb

    mov     AX, 'M'
    stosb
    mov     AX, 06h
    stosb