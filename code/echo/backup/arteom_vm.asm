org 0x7c00
;;; clear screen by setting video mode
    mov ah, 00h
    mov al, 3h
    int 10h

    mov     AX, 0xB800      ; Pointer to Video memory
    mov     ES, AX          ; Equal es to ax to video memory
    mov     di, 0

    mov     al, 'a'         ; Character to print
    mov     ah, 0x1F         ; Text color (cyan)
    mov     es:[0], ax