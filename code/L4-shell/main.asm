org 7e00h

; ==============================

section .text
    global _start

_start:
    call    break_line_for_input
    call    read_input

    ; check 'about'

    mov     si, input_buffer
    mov     di, about_command_name
    mov     dx, about_name_len
    mov     byte [command], 1
    call    check_command

    cmp     byte [command], 0
    jne     command_identified

    ; check 'time'

    mov     si, input_buffer
    mov     di, time_command_name
    mov     dx, time_name_len
    mov     byte [command], 2
    call    check_command

    cmp     byte [command], 0
    jne     command_identified

    ; check 'clear'
    
    mov     si, input_buffer
    mov     di, clear_command_name
    mov     dx, clear_name_len
    mov     byte [command], 3
    call    check_command

    cmp     byte [command], 0
    jne     command_identified

    ; if went through the entire list of known-s ...

    jmp     unknown_err_display

    command_identified:
        call    interpret_command

    jmp     _terminate

; ------------------------------

break_line:
    call    get_cursor_pos
    inc     dh
    mov     dl, 0

    xor     ax, ax
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

    xor     ax, ax
    mov     es, ax
    mov     bp, in_start_str

    mov     bl, 07h
    mov     cx, in_start_str_len

    mov     ax, 1301h
    int     10h

    ret

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
        cmp     si, input_buffer
        je      typing

        ; ensure that the buffer ends with an empty byte

        mov     byte [si], 0

        call    break_line

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

    jmp     interpretation_end

    interpret_about:
        mov     si, about_string
        mov     cx, about_string_len
        call    print_str

        jmp     interpretation_end

    interpret_time:
        call    get_time
        call    time_bytes_to_ascii

        call    get_date
        call    date_bytes_to_ascii

        mov     si, time_string
        mov     cx, time_string_len
        call    print_str

        mov     si, dt_ascii_buffer
        mov     cx, 16
        call    print_str

        jmp     interpretation_end

    interpret_clear:
        call    clear_screen

        jmp     interpretation_end

    interpretation_end:
        ret

; ------------------------------

clear_screen:
    mov     ah, 02h
    mov     bh, 0
    mov     dh, 0
    mov     dl, 0
    int     10h

    mov     cx, 20

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

time_bytes_to_ascii:

    ; convert and save hour

    xor     ax, ax
    mov     al, ch
    mov     bl, 16
    div     bl

    add     al, 30h
    add     ah, 30h

    mov     [dt_ascii_buffer + 11], al
    mov     [dt_ascii_buffer + 12], ah
    mov     byte [dt_ascii_buffer + 13], 3ah

    ; convert and save minute

    xor     ax, ax
    mov     al, cl
    mov     bl, 16
    div     bl

    add     al, 30h
    add     ah, 30h

    mov     [dt_ascii_buffer + 14], al
    mov     [dt_ascii_buffer + 15], ah

    ret

date_bytes_to_ascii:

    ; convert and save day

    xor     ax, ax
    mov     al, dl
    mov     bl, 16
    div     bl

    add     al, 30h
    add     ah, 30h

    mov     [dt_ascii_buffer + 0], al
    mov     [dt_ascii_buffer + 1], ah
    mov     byte [dt_ascii_buffer + 2], 2fh

    ; convert and save month

    xor     ax, ax
    mov     al, dh
    mov     bl, 16
    div     bl

    add     al, 30h
    add     ah, 30h

    mov     [dt_ascii_buffer + 3], al
    mov     [dt_ascii_buffer + 4], ah
    mov     byte [dt_ascii_buffer + 5], 2fh

    ; convert and save century

    xor     ax, ax
    mov     al, ch
    mov     bl, 16
    div     bl

    add     al, 30h
    add     ah, 30h

    mov     [dt_ascii_buffer + 6], al
    mov     [dt_ascii_buffer + 7], ah

    ; convert and save year

    xor     ax, ax
    mov     al, cl
    mov     bl, 16
    div     bl

    add     al, 30h
    add     ah, 30h

    mov     [dt_ascii_buffer + 8], al
    mov     [dt_ascii_buffer + 9], ah
    mov     byte [dt_ascii_buffer + 10], 20h

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
    mov     cx, error_string_len
    call    print_str

    jmp     _terminate

; ------------------------------

get_cursor_pos:
    mov     ah, 03h
    mov     bh, 0
    int     10h

    ret

; ------------------------------

_terminate:
    jmp     _start

; ==============================

section .data

in_start_str            dd ">>> "
in_start_str_len        equ 4

; ------------------------------
    
about_command_name      dd "about"
about_name_len          equ 5
    
about_string            dd "Developed by Kalamaghin Arteom FAF-211"
about_string_len        equ 38

; ------------------------------

time_command_name       dd "datetime"
time_name_len           equ 8

time_string             dd "CMOS RTC - "
time_string_len         equ 11

; ------------------------------

clear_command_name      dd "clear"
clear_name_len          equ 5

; ------------------------------

error_string            dd "Unknown command!"
error_string_len        equ 16

; ------------------------------

command                 db 0

hours                   db 0
minutes                 db 0
seconds                 db 0

; ==============================

section .bss

input_buffer        resb 256
dt_ascii_buffer     resb 16