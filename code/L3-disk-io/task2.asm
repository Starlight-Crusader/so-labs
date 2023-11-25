org 7e00h

section .text
    global _start

_start:
    call    reset_memory
    xor     sp, sp

    ; print options listing string

    call    get_cursor_pos

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

    cmp     al, '3'
    je      option3

    jmp     _error

; 2.1 BEGINNING

option1:
    ; display the key read

    mov     ah, 0eh
    int     10h

    mov     al, 2eh
    int     10h

    ; print "STRING = "

    call    get_cursor_pos

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

    call    read_input

    ; save the string to its own buffer

    mov     si, storage_buffer
    mov     di, string

    char_copy_loop:
        mov     al, [si]
        mov     [di], al
        inc     si
        inc     di

        cmp     byte [si], 0
        jne     char_copy_loop

    ; print "N = "

    call    get_cursor_pos

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

    call    read_input

    ; convert ascii read to an integer

    mov     di, nhts
    mov     si, storage_buffer
    call    atoi

    ; read HTS

    call    read_hts_address

    ; prepare writing buffer

    mov     si, string
    call    fill_storage_buffer

    ; calculate the number of sectors to write

    xor     dx, dx
    mov     ax, [storage_curr_size]
    mov     bx, 512
    div     bx

    ; write to the floppy

    push    ax

    mov     ax, 0
	mov     es, ax
    mov     bx, storage_buffer

    pop     ax

    mov     ah, 03h
    inc     al
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

    ; read RAM address XXXX:YYYY "

    call    read_ram_address

    ; read HTS

    call    read_hts_address

    ; print "N = "

    call    get_cursor_pos

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

    call    read_input

    ; convert ascii read to an integer

    mov     di, nhts
    mov     si, storage_buffer
    call    atoi

    ; read data from floppy

    mov     es, [address]
    mov     bx, [address + 2]

    mov     ah, 02h
    mov     al, [nhts]
    mov     ch, [nhts + 4]
    mov     cl, [nhts + 6]
    mov     dh, [nhts + 2]
    mov     dl, 0

    int     13h
    jc      _error

    ; print the data read

    call    get_cursor_pos

    inc     dh
    mov     dl, 0

    mov     es, [address]
    mov     bp, [address + 2]

    mov     bl, 07h
    mov     cx, 512

    mov     ax, 1301h
    int     10h

    jmp     _terminate

option3:
    ; display the key read

    mov     ah, 0eh
    int     10h

    mov     al, 2eh
    int     10h

    ; read RAM address XXXX:YYYY "

    call    read_ram_address

    ; read HTS

    call    read_hts_address

    ; write data to floppy

    mov     es, [address]
    mov     bx, [address + 2]

    mov     ah, 03h
    mov     al, 1
    mov     ch, [nhts + 4]
    mov     cl, [nhts + 6]
    mov     dh, [nhts + 2]
    mov     dl, 0

    int     13h
    jc      _error

    jmp     _terminate


; Keyboard reading subprocess

read_input:
    mov     si, storage_buffer
    call    get_cursor_pos

    typing:
        mov     ah, 00h
        int     16h

        cmp     al, 08h
	    je      hdl_backspace

	    cmp     al, 0dh
	    je      hdl_enter

        cmp     si, storage_buffer + 256
        je      typing

        mov     [si], al
	    inc     si

        mov     ah, 0eh
	    int     10h

	    jmp     typing

    hdl_backspace:
	    cmp     si, storage_buffer
	    je      typing

	    dec     si
    	mov     byte [si], 0

        call    get_cursor_pos

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
        cmp     si, storage_buffer
        je      typing

        mov     byte [si], 0

        ret

; In. number conversions

atoi:
    atoi_conv_loop:
        cmp     byte [si], 0
        je      atoi_conv_done

        xor     ax, ax
        mov     al, [si]
        sub     al, '0'

        mov     bx, [di]
        imul    bx, 10
        add     bx, ax
        mov     [di], bx

        inc     si

        jmp     atoi_conv_loop

    atoi_conv_done:
        ret

atoh:
    atoh_conv_loop:
        cmp     byte [si], 0
        je      atoh_conv_done

        xor     ax, ax
        mov     al, [si]
        cmp     al, 65
        jl      conv_digit  

        conv_letter:
            sub     al, 55
            jmp     atoh_finish_iteration

        conv_digit:
            sub     al, 48

        atoh_finish_iteration:
            mov     bx, [di]
            imul    bx, 16
            add     bx, ax
            mov     [di], bx

            inc     si

        jmp     atoh_conv_loop

    atoh_conv_done:
        ret

; With this subprocess, copy the string n times in a separate buffer to write on floppy

fill_storage_buffer:
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
        mov     di, storage_buffer

    copy_string_to_buffer_loop:
        push    cx
        push    si
        rep     movsb

        pop     si
        pop     cx

        dec     word [nhts]
        add     word [storage_curr_size], cx

        cmp     word [nhts], 0
        jg      copy_string_to_buffer_loop

    push    di
    sub     di, storage_buffer
    mov     ax, di
    pop     di

    xor     dx, dx
    mov     bx, 512
    div     bx
    
    mov     cx, 0

    nulls:
        mov     byte [edi], 0
        
        inc     di
        inc     cx

        cmp     cx, dx
        jl      nulls

    return:
        ret

; Useful stuff

break_line:
    call    get_cursor_pos

    inc     dh
    mov     dl, 0

    mov     ax, 0
    mov     es, ax
    mov     bp, prompt_start

    mov     bl, 07h
    mov     cx, 0

    mov     ax, 1301h
    int     10h

    ret

break_line_with_prompt:
    call    get_cursor_pos

    inc     dh
    mov     dl, 0

    mov     ax, 0
    mov     es, ax
    mov     bp, prompt_start

    mov     bl, 07h
    mov     cx, prompt_start_len

    mov     ax, 1301h
    int     10h

    ret

get_cursor_pos:
    mov     ah, 03h
    mov     bh, [page_num]
    int     10h

    ret

; Addresses reading subprocesses

read_ram_address:
    ; print "SEGMENT (XXXX) = "

    call    get_cursor_pos

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

    call    read_input

    ; convert ascii read to a hex

    mov     di, address
    mov     si, storage_buffer
    call    atoh

    ; print "OFFSET (YYYY) = "

    call    get_cursor_pos

    inc     dh
    mov     dl, 0

    mov     ax, 0
    mov     es, ax
    mov     si, in_awaits_str2
    add     si, str2_awaits_len1
    mov     bp, si

    mov     bl, 07h
    mov     cx, str2_awaits_len2

    mov     ax, 1301h
    int     10h

    ; read user input (offset)

    call    read_input

    ; convert ascii read to a hex

    mov     di, address + 2
    mov     si, storage_buffer
    call    atoh

    ret

read_hts_address:
    ; print "{H, T, S} (one value per line):"

    call    get_cursor_pos

    inc     dh
    mov     dl, 0

    mov     ax, 0
    mov     es, ax
    mov     si, in_awaits_str1
    add     si, str1_awaits_len1
    add     si, str1_awaits_len2
    mov     bp, si

    mov     bl, 07h
    mov     cx, str1_awaits_len3 + 1

    mov     ax, 1301h
    int     10h

    ; read user input (h)

    call    break_line_with_prompt
    call    read_input

    ; convert ascii read to an integer

    mov     di, nhts + 2
    mov     si, storage_buffer
    call    atoi

    ; read user input (t)

    call    break_line_with_prompt
    call    read_input

    ; convert ascii read to an integer

    mov     di, nhts + 4
    mov     si, storage_buffer
    call    atoi

    ; read user input (s)

    call    break_line_with_prompt
    call    read_input

    ; convert ascii read to an integer

    mov     di, nhts + 6
    mov     si, storage_buffer
    call    atoi

    ret

; Trailer subprocesses

_error:
    call    get_cursor_pos
    call    break_line

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
    wait_for_confirm:
        mov     ah, 00h
        int     16h

        cmp     al, 0dh
        jne     wait_for_confirm

    mov     ax, [page_num]
    inc     ax
    mov     [page_num], ax

    mov     ah, 05h
    mov     al, [page_num]
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

    mov     ax, [di]
    mov     bx, [test_result]

    xor     ax, bx
    jnz     incorrect

    correct:
        mov     ah, 0eh
        mov     al, 53h
        int     10h

        jmp     check_end

    incorrect:
        mov     ah, 0eh
        mov     al, 45h
        int     10h

    check_end:
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

    call    get_cursor_pos
 
	mov     ax, 0
    mov     es, ax
    mov     bp, storage_buffer

    mov     bl, 07h
    sub     si, storage_buffer
    mov     cx, si

    mov     ax, 1301h
    int     10h

    ret

; Data declaration and initialization

reset_memory:
    mov     ah, 00h
    int     13h

    mov     si, storage_buffer
    mov     di, storage_buffer + 512
    call    reset_buffer

    mov     si, string
    mov     di, string + 256
    call    reset_buffer

    mov     si, nhts
    mov     di, nhts + 8
    call    reset_buffer

    mov     si, address
    mov     di, address + 4
    call    reset_buffer

    mov     si, storage_curr_size
    mov     di, storage_curr_size + 4
    call    reset_buffer

    mov     si, storage_buffer
    mov     di, storage_buffer + 1
    call    reset_buffer

    call    reset_registers

    ret

reset_registers:
    xor     ax, ax
    xor     bx, bx
    xor     cx, cx
    xor     dx, dx
    xor     si, si
    xor     di, di
    xor     bp, bp

    ret

reset_buffer:
    reset_buffer_loop:
        mov     byte [si], 0
        inc     si

        cmp     si, di
        jl      reset_buffer_loop

    ret

section .data
    opt_str             dd "1. KBD-->FLP | 2. FLP-->RAM | 3. RAM-->FLP"
    opt_len             equ 42

    in_awaits_str1       dd "STRING = N = {H, T, S} (one value per line)", 3ah
    str1_awaits_len1     equ 9
    str1_awaits_len2     equ 4
    str1_awaits_len3     equ 30

    in_awaits_str2       dd "SEGMENT (XXXX) = OFFSET (YYYY) = "
    str2_awaits_len1     equ 17
    str2_awaits_len2     equ 16

    prompt_start         dd ">>> "
    prompt_start_len     equ 4

    page_num             dw  0
    test_result          dw  10000
    
section .bss
    string              resb 256
    nhts                resb 8
    address             resb 4
    storage_curr_size   resb 4
    storage_buffer      resb 1