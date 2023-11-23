org 7c00h

mov     ah, 00
int     13h

mov     ax, 0000h
mov     es, ax
mov     bx, 1000h

mov     ah, 02h
mov     al, 4
mov     ch, 0
mov     cl, 2
mov     dh, 0
mov     dl, 0
int     0x13

jmp     0000h:1000h

times 510-($-$$) db 0
dw 0AA55h