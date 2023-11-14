org 7c00h

section .data
    opt_str             dd "PICK AN OPTION:1. KBD ---> FLP2. FLP ---> RAM3. RAM ---> FLP"
    opt_str_len         equ 15

    in_await_str        dd "STRING = "
    in_await_str_len    equ 9

    in_await_n          dd "N = "
    in_await_n_len      equ 4

    in_await_hts        dd "{H, T, S} = "
    in_await_hts_len    equ 12

    test_string         dd "abcdefghiklmnop"
    test_string_len     equ 15

section .bss
    string          resb 256
    address         resb 9
    num_in_buffer   resb 10
    n               resb 4
    head            resb 4
    track           resb 4
    sector          resb 4
    buffer_size     resb 1

section .text
    global _start

_start:
    mov     si, opt_str
    mov     cx, 5
    push    cx

    mov     ah, 03h
    mov     bh, 0
    int     10h

    mov     ah, 02h
    inc     dh
    mov     dl, 0
    int     10h

    print_opt_list:
        pop     cx
        dec     cx
        jz      read_option

        push    cx
        mov     cx, opt_str_len

        print_line:
            mov     ah, 0eh
            mov     al, [si]
            int     10h

            inc     si
            dec     cx

            cmp     cx, 0
            jnz     print_line

            mov     ah, 03h
            mov     bh, 0
            int     10h

            mov     ah, 02h
            inc     dh
            mov     dl, 0
            int     10h

            jmp     print_opt_list

    read_option:
        mov     ah, 03h
        mov     bh, 0
        int     10h

        mov     ah, 02h
        inc     dh
        mov     dl, 0
        int     10h

        mov     ah, 00h
        int     16h

        direct_exec_flow:
            cmp     al, '1'
            je      option1

            jmp     _error

option1:
    mov     ah, 0eh
    int     10h

    mov     al, 2eh
    int     10h

from_kbd_to_flp:
    
    ; print "STRING = "

    mov     ah, 03h
    mov     bh, 0
    int     10h

    inc     dh
    mov     dl, 0

    mov     ax, 0
    mov     es, ax
    mov     bp, in_await_str

    mov     bl, 07h
    mov     cx, in_await_str_len

    mov     ax, 1301h
    int     10h

    ; read the string

    mov     di, string
    mov     si, string
    mov     byte [buffer_size], 255
    call    read_input
    call    print_read_debug

    ; print "N ="

    mov     ah, 03h
    mov     bh, 0
    int     10h

    inc     dh
    mov     dl, 0
 
	mov     ax, 0
    mov     es, ax
    mov     bp, in_await_n

	mov     bl, 07h
    mov     cx, in_await_n_len

    mov     ax, 1301h
    int     10h

    ; read the n

    mov     di, num_in_buffer
    mov     si, num_in_buffer
    mov     byte [buffer_size], 9
    call    read_input
    call    print_read_debug

    mov     si, num_in_buffer
    mov     di, n
    call    atoi

    ; check the result

    mov     ah, 03h
    mov     bh, 0
    int     10h

    inc     dh
    mov     dl, 0
 
	mov     ax, 0
    mov     es, ax
    mov     bp, test_string

	mov     bl, 07h
    mov     cx, test_string_len
    mov     ax, [n]
    sub     cx, ax

    mov     ax, 1301h
    int     10h

    jmp     _terminate

read_input:
    typing:
        mov     ah, 00h
        int     16h

        cmp     al, 08h
	    je      handle_backspace

	    cmp     al, 0dh
	    je      handle_enter

        push    si
        sub     si, di
        mov     cx, si
        pop     si
        cmp     cx, [buffer_size]
        je      typing

        mov     [si], al
	    inc     si

        mov     ah, 0eh
	    int     10h

	    jmp     typing

    handle_backspace:
	    cmp     si, di
	    je      typing

	    dec     si
    	mov     byte [si], 0

        mov     ah, 03h
	    mov     bh, 0
	    int     10h

	    cmp     dl, 0
        je      previous_line

        mov     ah, 02h
        dec     dl
        int     10h

        mov     ah, 0eh
        mov     al, 20h
        int     10h

        mov     AH, 02h
	    int     10h

	    jmp     typing

    previous_line:
        mov     ah, 02h
        mov     dl, 79
        dec     dh
        int     10h

        mov     ah, 0eh
        mov     al, 20h
        int     10h
    
        mov     ah, 02h
        int     10h
    
        jmp     typing

    handle_enter:
        cmp     si, di
        je      typing
        
        ret

print_read_debug:
    mov     ah, 0eh
    mov     al, 20h
    int     10h

    mov     ah, 0eh
    mov     al, 65h
    int     10h

    mov     ah, 0eh
    mov     al, 20h
    int     10h

    mov     ah, 03h
    mov     bh, 0
    int     10h
 
	mov     ax, 0
    mov     es, ax
    mov     bp, di

	mov     bl, 07h
    sub     si, di
    mov     cx, si

    mov     ax, 1301h
    int     10h

    ret

_error:
;     mov     ah, 03h
;     mov     bh, 0
;     int     10h
; 
;     mov     ah, 02h
;     inc     dh
;     mov     dl, 0
;     int     10h
; 
;     push    52h
;     push    4fh
;     push    52h
;     push    52h
;     push    45h
;     mov     cx, 5
; 
;     print_error_loop:
;         mov     ah, 0eh
;         pop     bx
;         mov     al, bl
;         int     10h
; 
;         dec     cx
;         jnz     print_error_loop
; 
    jmp _terminate

atoi:
    convert_loop:
        mov     ax, [si]

        cmp     ax, 0
        je      convert_done

        sub     ax, '0'

        mov     bx, [di]
        imul    bx, 10
        add     bx, ax
        mov     [di], bx

        inc     si

        jmp     convert_loop

    convert_done:
        ret

_terminate:
    mov     ah, 00h
    int     21h