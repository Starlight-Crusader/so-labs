org     7c00h

section .text

_start:

    ; print "Booting the sect. at HTS (one val. per line)"

    mov     si, prompt_txt
    mov     cx, prompt_txt_len1
    call    print_str

    ; read HTS

    call    read_hts_address

    ; print "How many sect-s to load? - "

    mov     si, prompt_txt
    add     si, prompt_txt_len1
    mov     cx, prompt_txt_len2
    call    print_str

    ; read N

    call    break_line_for_input
    call    read_input

    ; convert ascii read to an integer

    mov     di, nhts
    mov     si, input_buffer
    call    atoi

    ; read the data from floppy

    mov     ah, 00h
    int     13h

    xor     ax, ax
    mov     es, ax
    mov     bx, 7e00h

    mov     dl, 0
    mov     al, [nhts + 0]
    mov     dh, [nhts + 2]
    mov     ch, [nhts + 4]
    mov     cl, [nhts + 6]
    
    mov     ah, 02h
    int     13h

    ; check the first 2 bytes for the signature (0xABCD)

    mov     ax, [es:bx]
    cmp     ax, 0xABCD
    jne     wrong_in_error

    ; check the last 2 bytes for the signature (0xCDEF)

    mov     ax, [nhts]
    imul    ax, 512

    push    bx
    add     bx, ax
    sub     bx, 2
    mov     ax, [es:bx]
    pop     bx

    cmp     ax, 0xCDEF
    jne     wrong_in_error

    jmp     0000h:7e00h

read_input:
    mov     si, input_buffer

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
        
        mov     byte [si], 0

        ret

atoi:
    atoi_conv_loop:

        ; check if all the digits were converted

        cmp     byte [si], 0
        je      atoi_conv_done

        ; convert the character's bytes to the number equivalent

        xor     ax, ax
        mov     al, [si]
        sub     al, '0'

        ; shift all the digits one place left and put a new digit at the first place

        mov     bx, [di]
        imul    bx, 10
        add     bx, ax
        mov     [di], bx

        ; advance to pint at the next charactr representing some digit

        inc     si

        jmp     atoi_conv_loop

    atoi_conv_done:
        ret

get_cursor_pos:
    mov     ah, 03h
    mov     bh, [page_num]
    int     10h

    ret

break_line:
    call    get_cursor_pos

    inc     dh
    mov     dl, 0

    mov     ax, 0
    mov     es, ax
    mov     bp, in_start_str

    mov     bl, 07h
    mov     cx, 0

    mov     ax, 1301h
    int     10h

    ret

break_line_for_input:
    call    get_cursor_pos

    inc     dh
    mov     dl, 0

    mov     ax, 0
    mov     es, ax
    mov     bp, in_start_str

    mov     bl, 07h
    mov     cx, in_start_str_len

    mov     ax, 1301h
    int     10h

    ret

read_hts_address:

    ; read user input (h)

    call    break_line_for_input
    call    read_input

    ; convert ascii read to an integer

    mov     di, nhts + 2
    mov     si, input_buffer
    call    atoi

    ; read user input (t)

    call    break_line_for_input
    call    read_input

    ; convert ascii read to an integer

    mov     di, nhts + 4
    mov     si, input_buffer
    call    atoi

    ; read user input (s)

    call    break_line_for_input
    call    read_input

    ; convert ascii read to an integer

    mov     di, nhts + 6
    mov     si, input_buffer
    call    atoi

    ret

print_str:
    call    get_cursor_pos
    inc     dh
    mov     dl, 0

    xor     ax, ax
    mov     es, ax
    mov     bp, si

    mov     bl, 07h

    mov     ax, 1301h
    int     10h

    ret

wrong_in_error:

    ; print the error msg.

    mov     si, in_err_txt
    mov     cx, in_err_txt
    call    print_str

    jmp     _terminate

_terminate:

    ; wait for any key to be pressed

    mov     ah, 00h
    int     16h

    ; advance the video page

    inc     word [page_num]

    mov     ah, 05h
    mov     al, [page_num]
    int     10h

    jmp     _start

section .data

page_num            dw 0

prompt_txt          dd "Booting the sect. at HTS", 3ah, "How many sect-s to load? - ", 0
prompt_txt_len1     equ 45
prompt_txt_len2     equ 27

in_start_str        dd ">>> ", 0
in_start_str_len    equ 4

in_err_txt          dd "It seems like you've inserted incorr. NHTS val-s!", 0
in_err_txt_len      equ 49

; times 510 - ($ - $$) db 0
; dw 0xAA55

section .bss
    
input_buffer    resb 2
nhts            resb 8