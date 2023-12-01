org     7c00h

section .text
    global      _start

_start:


; The typing subroutine

read_input:
    mov     si, input_buffer
    call    get_cursor_pos

    typing:
        ; read the key pressed

        mov     ah, 00h
        int     16h

        ; handle special keys

        cmp     al, 08h
	    je      hdl_backspace

	    cmp     al, 0dh
	    je      hdl_enter

        ; prevent program form reading more than 256 characters

        cmp     si, input_buffer + 2
        je      typing

        ; save the character read to the buffer

        mov     [si], al
	    inc     si

        ; display the character read

        mov     ah, 0eh
	    int     10h

	    jmp     typing

    hdl_backspace:

        ; if the buffer is empty, ignore backspace

	    cmp     si, input_buffer    
	    je      typing

        ; else erase the previous character from the buffer

	    dec     si
    	mov     byte [si], 0

        ; and print a blank space over it on the screen

        call    get_cursor_pos

        mov     ah, 02h
        dec     dl
        int     10h

        mov     ah, 0ah
        mov     al, 20h
        int     10h

	    jmp     typing

    hdl_enter:
        cmp     si, input_buffer    
        je      typing

        ret

section .data
    page_num    dw 0

    in_awaits_str       dd "STRING = N = {H, T, S} (one value per line)", 3ah
    str_awaits_len1     equ 9
    str_awaits_len2     equ 4
    str_awaits_len3     equ 31

section .bss
    input_buffer    resb 2
    nhts            resb 8