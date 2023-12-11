section .text

mov     word [kernel_origin + 0], 0000h
mov     word [kernel_origin + 2], 0000h

mov     word [kernel_origin + 2], si

start:
    call    break_line_for_input
    call    read_input

    cmp     byte [input_buffer], 00h
    je      cli_cycle_end

    call    break_line

    ; check 'about'

    mov     si, input_buffer
    mov     di, about_command_name
    add     di, word [kernel_origin + 2]
    mov     dx, about_name_len
    mov     byte [command], 1
    call    check_command

    cmp     byte [command], 0
    jne     command_identified

    ; check 'time'

    mov     si, input_buffer
    mov     di, time_command_name
    add     di, word [kernel_origin + 2]
    mov     dx, time_name_len
    mov     byte [command], 2
    call    check_command

    cmp     byte [command], 0
    jne     command_identified

    ; check 'clear'
    
    mov     si, input_buffer
    mov     di, clear_command_name
    add     di, word [kernel_origin + 2]
    mov     dx, clear_name_len
    mov     byte [command], 3
    call    check_command

    cmp     byte [command], 0
    jne     command_identified

    ; check 'exit'

    mov     si, input_buffer
    mov     di, exit_command_name
    add     di, word [kernel_origin + 2]
    mov     dx, exit_name_len
    mov     byte [command], 4
    call    check_command

    cmp     byte [command], 0
    jne     command_identified

    ; if went through the entire list of known-s ...

    jmp     unknown_err_display

    command_identified:
        call    interpret_command

    cli_cycle_end:
        jmp     terminate

; ------------------------------

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

        ; prevent program form hading more than 256 characters

        cmp     si, input_buffer + 256
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

        ; if at the start of the second+ line return to the previous row and proceed in the same manner

	    cmp     dl, 0
        je      prev_line

        mov     ah, 02h
        dec     dl
        int     10h

        mov     ah, 0ah
        mov     al, 20h
        int     10h

	    jmp     typing

    prev_line:
        mov     ah, 02h
        dec     dh
        mov     dl, 79
        int     10h

        mov     ah, 0ah
        mov     al, 20h
        int     10h
    
        jmp     typing

    hdl_enter:

        ; ensure that the buffer ends with an empty byte

        mov     byte [si], 0

        ret

; ------------------------------

check_command:
    push    si
    dec     si
    mov     cx, -1

    find_len_loop:
        inc     si
        inc     cx

        cmp     byte [si], 00h
        je      check_command_len

        jmp     find_len_loop

    check_command_len:
        pop     si

        cmp     cx, dx
        jne     not_identified

    check_command_letters:
        dec     cx
        jz      identified

        mov     ax, [si]
        mov     bx, [di]

        cmp     ax, bx
        jne     not_identified

        inc     si
        inc     di

        jmp     check_command_letters

    identified:
        ret

    not_identified:
        mov     byte [command], 0
        ret

interpret_command:
    cmp     byte [command], 1
    je      interpret_about

    cmp     byte [command], 2
    je      interpret_time

    cmp     byte [command], 3
    je      interpret_clear

    cmp     byte [command], 4
    je      interpret_exit

    jmp     interpretation_end

    interpret_about:
        mov     si, about_string
        add     si, word [kernel_origin + 2]
        mov     cx, about_string_len
        call    print_str

        jmp     interpretation_end

    interpret_time:
        call    get_date

        mov     al, dl
        mov     si, dt_ascii_buffer + 0
        call    bcd_to_ascii
        mov     byte [dt_ascii_buffer + 2], 2fh

        mov     al, dh
        mov     si, dt_ascii_buffer + 3
        call    bcd_to_ascii
        mov     byte [dt_ascii_buffer + 5], 2fh

        mov     al, ch
        mov     si, dt_ascii_buffer + 6
        call    bcd_to_ascii
        
        mov     al, cl
        mov     si, dt_ascii_buffer + 8
        call    bcd_to_ascii
        mov     byte [dt_ascii_buffer + 10], 20h

        call    get_time

        mov     al, ch
        mov     si, dt_ascii_buffer + 11
        call    bcd_to_ascii
        mov     byte [dt_ascii_buffer + 13], 3ah

        mov     al, cl
        mov     si, dt_ascii_buffer + 14
        call    bcd_to_ascii

        mov     si, time_string
        add     si, word [kernel_origin + 2]
        mov     cx, time_string_len
        call    print_str

        mov     si, dt_ascii_buffer
        mov     cx, 16
        call    print_str

        jmp     interpretation_end

    interpret_clear:
        call    clear_screen

        jmp     interpretation_end

    interpret_exit:
        call    clear_screen

        pop     sp
        push    7e00h
        ret

    interpretation_end:
        ret

; ------------------------------

get_time:

    ; int 1ah ah=02h - read time from CMOS RTC

    mov     ah, 02h
    int     1ah

    ; ch - hours, cl - minutes, dh - seconds (all in BCD)

    ret

get_date:

    ; int 1ah ah=04h - read date from from CMOS RTC

    mov     ah, 04h
    int     1ah

    ; ch - century, cl - year, dh - month, dl - day (all in BCD)

    ret

bcd_to_ascii:
    xor     ah, ah
    mov     bl, 10h
    div     bl

    add     al, 30h
    add     ah, 30h

    mov     [si], al
    mov     [si + 1], ah

    ret 

; ------------------------------

print_str:
    push    cx

    call    get_cursor_pos

    xor     ax, ax
    mov     es, ax
    mov     bp, si

    mov     bl, 07h
    pop     cx

    mov     ax, 1301h
    int     10h

    ret

unknown_err_display:
    mov     si, error_string
    add     si, word [kernel_origin + 2]
    mov     cx, error_string_len
    call    print_str

    jmp     terminate

; ------------------------------

get_cursor_pos:
    mov     ah, 03h
    mov     bh, 0
    int     10h

    ret

clear_screen:
    mov     ah, 02h
    mov     bh, 0
    mov     dh, 0
    mov     dl, 0
    int     10h

    mov     cx, 25

    clear_screen_loop:
        push    cx

        mov     ah, 09h
        mov     al, 20h
        mov     bh, 0
        mov     bl, 07h
        mov     cx, 80
        int     10h

        call    break_line

        pop     cx
        dec     cx
        jnz     clear_screen_loop

    mov     ah, 02h
    mov     bh, 0
    mov     dh, 0
    mov     dl, 0
    int     10h

    ret

break_line:
    call    get_cursor_pos
    inc     dh
    mov     dl, 0

    xor     ax, ax
    mov     es, ax
    mov     bp, in_start_str
    add     bp, word [kernel_origin + 2]

    mov     bl, 07h
    mov     cx, 1

    mov     ax, 1301h
    int     10h

    ret

break_line_for_input:
    call    get_cursor_pos
    inc     dh
    mov     dl, 0

    xor     ax, ax
    mov     es, ax
    mov     bp, in_start_str
    add     bp, word [kernel_origin + 2]

    mov     bl, 07h
    mov     cx, in_start_str_len

    mov     ax, 1301h
    int     10h

    ret

; ------------------------------

terminate:
    call    get_cursor_pos

    cmp     dh, 22
    jl      clear_not_needed

    clear_needed:
        call    clear_screen

    clear_not_needed:
        jmp     start

; ==============================

section .data

in_start_str            db " >>> "
in_start_str_len        equ 5

; ------------------------------
    
about_command_name      db "about"
about_name_len          equ 5
    
about_string            db "Developed by Kalamaghin Arteom FAF-211"
about_string_len        equ 38

; ------------------------------

time_command_name       db "datetime"
time_name_len           equ 8

time_string             db "CMOS RTC - "
time_string_len         equ 11

; ------------------------------

clear_command_name      db "clear"
clear_name_len          equ 5

; ------------------------------

exit_command_name       db "exit"
exit_name_len           equ 4

; ------------------------------

error_string            db "Unknown command!"
error_string_len        equ 16

; ==============================

section .bss

command             resb 1

hours               resb 1
minutes             resb 1
seconds             resb 1

kernel_origin       resb 4
input_buffer        resb 256
dt_ascii_buffer     resb 16
