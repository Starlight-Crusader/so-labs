org 7c00h

section .text
    global _start

_start:
    mov     AX, 0xB800      ; Pointer to Video memory
    mov     ES, AX          ; Equal es to ax to video memory
    xor     DI, DI          ; Offset (B800:0000) - offset to write characters to video memory pointer
    
    mov     AX, 'O'         ; Character to print
    stosb                   ; Write the character to the memory 
    mov     AX, 0x3         ; Text color (cyan) on black
    stosb                   ; Write the attribute to the memory

    mov     AX, 'O'         ; ...
    stosb                   ; ...
    mov     AX, 0x3         ; ...
    stosb                   ; ...