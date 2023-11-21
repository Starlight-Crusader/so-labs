org 1000h

section .text
    global _start

_start:
    ; print options listing string

    mov     ah, 03h
    mov     bh, 0
    int     10h

    mov     ax, 0
    mov     es, ax
    mov     bp, opt_str

    mov     bl, 07h
    mov     cx, opt_len

    mov     ax, 1301h
    int     10h

    mov     ah, 0eh
    mov     al, 3ah
    int     10h

    mov     al, 20h
    int     10h

    ; read user's choice

    mov     ah, 00h
    int     16h

    ; execute chosen operation

    cmp     al, '1'
    je      option1

    cmp     al, '2'
    je      option2

    jmp     _error

; 2.1 BEGINNING

option1:

    ; display the key read

    mov     ah, 0eh
    int     10h

    mov     al, 2eh
    int     10h

    ; print "STRING = "

    mov     ah, 03h
    mov     bh, 0
    int     10h

    inc     dh
    mov     dl, 0

    mov     ax, 0
    mov     es, ax
    mov     bp, in_awaits_str1

    mov     bl, 07h
    mov     cx, str1_awaits_len1

    mov     ax, 1301h
    int     10h

    ; read user input (str)

    call    read_in
    ; ; call    print_in_buff

    ; save the string to its own buffer

    mov     si, in_buffer
    mov     di, string

    char_copy_loop:
        mov     al, [si]
        mov     [di], al
        inc     si
        inc     di

        cmp     byte [si], 0
        jne     char_copy_loop

    ; print "N = "

    mov     ah, 03h
    mov     bh, 0
    int     10h

    inc     dh
    mov     dl, 0

    mov     ax, 0
    mov     es, ax
    mov     si, in_awaits_str1
    add     si, str1_awaits_len1
    mov     bp, si

    mov     bl, 07h
    mov     cx, str1_awaits_len2

    mov     ax, 1301h
    int     10h

    ; read user input (n)

    call    read_in
    ; call    print_in_buff

    ; convert ascii read to an integer

    mov     di, nhts
    mov     si, in_buffer
    call    atoi

    ; print "{H, T, S} (one value per line):"

    mov     ah, 03h
    mov     bh, 0
    int     10h

    inc     dh
    mov     dl, 0

    mov     ax, 0
    mov     es, ax
    mov     si, in_awaits_str1
    add     si, str1_awaits_len1
    add     si, str1_awaits_len2
    mov     bp, si

    mov     bl, 07h
    mov     cx, str1_awaits_len3

    mov     ax, 1301h
    int     10h

    mov     ah, 0eh
    mov     al, 3ah
    int     10h

    mov     ah, 

    mov     ah, 02h
    inc     dh
    mov     al, 0
    int     10h

    ; read user input (h)

    call    read_in
    ; call    print_in_buff

    mov     ah, 02h
    inc     dh
    mov     dl, 0
    int     10h

    ; convert ascii read to an integer

    mov     di, nhts + 2
    mov     si, in_buffer
    call    atoi

    ; read user input (t)

    call    read_in
    ; call    print_in_buff

    mov     ah, 02h
    inc     dh
    mov     dl, 0
    int     10h

    ; convert ascii read to an integer

    mov     di, nhts + 4
    mov     si, in_buffer
    call    atoi

    ; read user input (s)

    call    read_in
    ; call    print_in_buff

    mov     ah, 02h
    inc     dh
    mov     dl, 0
    int     10h

    ; convert ascii read to an integer

    mov     di, nhts + 6
    mov     si, in_buffer
    call    atoi

    ; prepare writing buffer

    mov     si, string
    call    fill_write_buffer

    ; write to the floppy

    mov     ax, 0
	mov     es, ax
    mov     bx, write_buffer

    mov     ah, 03h
    mov     al, 1
    mov     ch, [nhts + 4]
    mov     cl, [nhts + 6]
    mov     dh, [nhts + 2]
    mov     dl, 0

    int     13h
    jc      _error

    jmp     _terminate

; 2.2 BEGINNING

option2:
    ; display the key read

    mov     ah, 0eh
    int     10h

    mov     al, 2eh
    int     10h

    ; print "SEGMENT (XXXX) = "

    mov     ah, 03h
    mov     bh, 0
    int     10h

    inc     dh
    mov     dl, 0

    mov     ax, 0
    mov     es, ax
    mov     bp, in_awaits_str2

    mov     bl, 07h
    mov     cx, str2_awaits_len1

    mov     ax, 1301h
    int     10h

    ; read user input (segment)

    call    read_in
    ; ; call    print_in_buff

    ; convert ascii read to a hex

    mov     di, address
    mov     si, in_buffer
    call    atoh

    ; check conversion

    call    conv_check

    jmp     _terminate

read_in:
    mov     si, in_buffer

    typing:
        mov     ah, 00h
        int     16h

        cmp     al, 08h
	    je      hdl_backspace

	    cmp     al, 0dh
	    je      hdl_enter

        cmp     si, in_buffer + 256
        je      typing

        mov     [si], al
	    inc     si

        mov     ah, 0eh
	    int     10h

	    jmp     typing

    hdl_backspace:
	    cmp     si, in_buffer
	    je      typing

	    dec     si
    	mov     byte [si], 0

        mov     ah, 03h
        mov     bh, 0
	    int     10h

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
        cmp     si, in_buffer
        je      typing

        mov     byte [si], 0

        ret

; In. number conversions

atoi:
    atoi_conv_loop:
        cmp     byte [si], 0
        je      atoi_conv_done

        mov     al, [si]
        sub     al, '0'

        mov     bl, [di]
        imul    bx, 10
        add     bx, ax
        mov     [di], bl

        inc     si

        jmp     atoi_conv_loop

    atoi_conv_done:
        ret

atoh:
    atoh_conv_loop:
        cmp     byte [si], 0
        je      atoh_conv_done

        mov     al, [si]
        cmp     al, 65
        jl      conv_digit  

        conv_letter:
            sub     al, 55
            jmp     atoh_finish_iteration

        conv_digit:
            sub     al, 48

        atoh_finish_iteration:
            mov     bl, [di]
            imul    bx, 16
            add     bx, ax
            mov     [di], bl

            inc     si

        jmp     atoh_conv_loop

    atoh_conv_done:
        ret

; With this subprocess, copy the string n times in a separate buffer to write on floppy

fill_write_buffer:
    push    si
    mov     cx, 0

    find_end:
        cmp     byte [si], 0
        je      end_found

        inc     si
        inc     cx

        jmp     find_end

    end_found:
        pop     si
        mov     di, write_buffer
        movzx   bx, [nhts]

    copy_string_to_buffer_loop:
        push    cx
        push    si
        rep     movsb

        pop     si
        pop     cx
        dec     bx

        cmp     bx, 0
        jg      copy_string_to_buffer_loop

    zeros:
        push    di
        sub     di, write_buffer

        mov     cx, di
        pop     di

        cmp     cx, 512
        je      return

        mov     byte [di], 30h
        inc     di

        jmp     zeros

    return:
        ret

; Useful stuff

break_line:
    mov     ah, 03h
    mov     bh, 0
    int     10h

    mov     ah, 02h
    inc     dh
    mov     al, 0
    int     10h

    ret

; Trailer subprocesses

_error:
    push    52h
    push    52h
    push    45h
    mov     cx, 3

    print_err_loop:
        mov     ah, 0eh
        pop     bx
        mov     al, bl
        int     10h

        dec     cx
        jnz     print_err_loop

    jmp _terminate

_terminate:
    mov     ah, 03h
    mov     bh, 0
    int     10h

    mov     ah, 02h
    inc     dh
    mov     dl, 0
    int     10h

    jmp     _start

; Debug subprocesses

conv_check:
    mov     ah, 0eh
    mov     al, 20h
    int     10h

    mov     ah, 0eh
    mov     al, 3eh
    int     10h

    mov     ah, 0eh
    mov     al, 3eh
    int     10h

    mov     ah, 0eh
    mov     al, 20h
    int     10h

    mov     ah, 03h
    int     10h

    push    word [di]
    
    mov     ah, 0eh
    ; add     word [di], 38
    mov     al, [di]
    int     10h

    pop     word [di]

    ret

print_in_buff:
    mov     ah, 0eh
    mov     al, 20h
    int     10h

    mov     ah, 0eh
    mov     al, 3eh
    int     10h

    mov     ah, 0eh
    mov     al, 3eh
    int     10h

    mov     ah, 0eh
    mov     al, 20h
    int     10h

    mov     ah, 03h
    mov     bh, 0
    int     10h
 
	mov     ax, 0
    mov     es, ax
    mov     bp, in_buffer

    mov     bl, 07h
    sub     si, in_buffer
    mov     cx, si

    mov     ax, 1301h
    int     10h

    ret

; Data declaration and initialization

section .data
    opt_str             dd "1. KBD-->FLP | 2. FLP-->RAM | 3. RAM-->FLP"
    opt_len             equ 42

    in_awaits_str1       dd "STRING = N = {H, T, S} (one value per line)"
    str1_awaits_len1     equ 9
    str1_awaits_len2     equ 4
    str1_awaits_len3     equ 30

    in_awaits_str2       dd "SEGMENT (XXXX) = OFFSET (YYYY) = "
    str2_awaits_len1     equ 17
    str2_awaits_len2     equ 16
    
section .bss
    write_buffer    resb 512
    in_buffer       resb 256
    string          resb 256
    nhts            resb 8
    address         resb 4