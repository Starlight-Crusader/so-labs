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


; 2.1

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

    ; save the string read to its own buffer

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

    ; print error code
    
    call    display_error_code

    ; print the string read

    call    get_cursor_pos

    mov     ah, 02h
    inc     dh
    int     10h

    mov     si, string
    call    display_buffer_contents

    jmp     _terminate


; 2.2

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

    ; print error code
    
    call    display_error_code

    ; print the data read

    call    paginated_output

    jmp     _terminate


; 2.3

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

    ; print the data to write

    call    get_cursor_pos

    inc     dh
    mov     dl, 0

    mov     es, [address]
    mov     bp, [address + 2]

    mov     bl, 07h
    mov     cx, [nhts]

    mov     ax, 1301h
    int     10h

    ; transfer n bytes to the write buffer

    call    reset_registers
    call    copy_nbytes

    ; calculate the number of sectors to write

    xor     dx, dx
    mov     ax, [nhts]
    mov     bx, 512
    div     bx

    ; write data to floppy

    push    ax

    xor     ax, ax
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

    call    display_error_code

    jmp     _terminate


; The typing subroutine

read_input:
    mov     si, storage_buffer
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

        cmp     si, storage_buffer + 256
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

	    cmp     si, storage_buffer
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
        cmp     si, storage_buffer
        je      typing

        ; ensure that the buffer ends with an empty byte

        mov     byte [si], 0

        ret


; The paginated output for 2.2

paginated_output:

    ; calculate how many '#' include a segment of the progress bar

    xor     dx, dx
    mov     ax, 80
    mov     bx, [nhts]
    div     bx
    inc     ax
    mov     [pb_segment_len], ax

    ; setup the RAM pointer

    mov     es, [address]
    mov     bp, [address + 2]

    mov     cx, 1

    paginated_output_loop:
        wait_for_page_advance_signal:

            ; read a keypress

            mov     ah, 00h
            int     16h

            ; if SPACE - proceed to the next page

            cmp     al, 20h
            jne     wait_for_page_advance_signal

        push    bp
        push    es

        push    cx

        ; prepare a clean page

        call    clear_screen

        pop     cx
        push    cx

        ; draw progress bar

        mov     ah, 09h
        mov     al, 23h
        mov     bh, 0
        mov     bl, 07h
        imul    cx, [pb_segment_len]
        int     10h

        mov     ah, 02h
        mov     bh, 0
        mov     dh, 1
        mov     dl, 0
        int     10h

        mov     ah, 09h
        mov     al, 2dh
        mov     bh, 0
        mov     bl, 07h
        mov     cx, 80
        int     10h

        ; print 1 sector - 512 char-s

        mov     bh, 0
        mov     dh, 2
        mov     dl, 0

        pop     cx
        pop     es
        pop     bp
        push    cx

        mov     bl, 07h
        mov     cx, 512

        mov     ax, 1301h
        int     10h

        ; advance pointers and counters

        pop     cx
        inc     cx
        add     bp, 512

        cmp     cx, [nhts]
        jle     paginated_output_loop

    stop_paginated_output:
        ret


; In. number conversions

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

atoh:
    atoh_conv_loop:

        ; essentially works the same as the subroutine above, but also need to consider some letters that need to be converted ...
        ; into numerical values form 10 to 15

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

; Writing buffer filling suproutines

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
        cmp     word [nhts], 0
        jle     copying_finsihed

        ; when we call movsb; si (pointer at the buffer copied), dx (pointer at the target), ...
        ; cx (number of bytes to be copied) advance automatically so we need to preserve some values

        push    cx
        push    si
        rep     movsb

        pop     si
        pop     cx

        dec     word [nhts]
        add     word [storage_curr_size], cx

        jmp     copy_string_to_buffer_loop

    copying_finsihed:

        ; calculate how many bytes will be left empty in the last sector

        push    di
        sub     di, storage_buffer
        mov     ax, di
        pop     di

        xor     dx, dx
        mov     bx, 512
        div     bx

        mov     cx, 0

    ; fill this space with empty bytes (or any other value you would like to see there)

    nulls:

        mov     byte [edi], 0
        
        inc     di
        inc     cx

        cmp     cx, dx
        jl      nulls

    return:
        ret

; is used in 2.3 to prepare exactly Q bytes for writing to the floppy, is pretty straightforward ...

copy_nbytes:
    xor     dx, dx
    xor     bx, bx

    mov     ax, [nhts]
    mov     bx, 512
    div     bx

    mov     cx, 0
    
    mov     es, [address]
    mov     bp, [address + 2]

    mov     si, storage_buffer

    copy_bytes_loop:
        cmp     cx, [nhts]
        jge     inflate_with_zeros

        xor     ax, ax
        mov     al, [es:bp]
        mov     [si], al
        
        inc     bp
        inc     si
        inc     cx

        jmp     copy_bytes_loop

    inflate_with_zeros:
        mov     byte [si], 0
            
        inc     si
        inc     dx

        cmp     dx, 512
        jl      inflate_with_zeros
    
    ret

; Useful stuff
; using the int 10h 1301h to advance the row helps to scroll the screen automatically

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
    mov     bh, 0
    int     10h

    ret

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
    mov     cx, str1_awaits_len3

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

    ; print "ERR" using the stack

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

    call    clear_screen

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


; Small printing subprocesses for the requested by the task outputs
 
display_buffer_contents:
    push    si
    mov     cx, 0

    find_buffer_end:
        cmp     byte [si], 0
        je      buffer_end_found

        inc     si
        inc     cx

        jmp     find_buffer_end

    buffer_end_found:
        pop     si
        push    cx

    call    get_cursor_pos

    inc     dh
    mov     dl, 0
 
	mov     ax, 0
    mov     es, ax
    mov     bp, si

    mov     bl, 07h
    pop     cx

    mov     ax, 1301h
    int     10h

    ret

display_error_code:
    push    ax

    ; print "EC="

    call    get_cursor_pos

    inc     dh
    mov     dl, 0

    mov     ax, 0
    mov     es, ax
    mov     bp, err_code_msg

    mov     bl, 07h
    mov     cx, err_code_msg_len

    mov     ax, 1301h
    int     10h

    ; print the error code (an integer)

    pop     ax

    mov     al, '0'
    add     al, ah
    mov     ah, 0eh
    int     10h

    ret


; Data declaration and initialization

reset_memory:

    ; it seems that force recalibration fixes some errors occuring when we read
    ; freshly written sectors

    mov     ah, 00h
    int     13h

    ; just filling all the buffers with some empty bytes to prevent any possible confusions

    mov     si, string
    mov     di, string + 256
    call    clear_buffer

    mov     si, nhts
    mov     di, nhts + 8
    call    clear_buffer

    mov     si, address
    mov     di, address + 4
    call    clear_buffer

    mov     si, storage_curr_size
    mov     di, storage_curr_size + 4
    call    clear_buffer

    mov     si, storage_buffer
    mov     di, storage_buffer + 1
    call    clear_buffer

    mov     byte [pb_segment_len], 00h

    call    reset_registers

    ret

reset_registers:
    xor     ax, ax
    xor     bx, bx
    xor     cx, cx
    xor     dx, dx
    xor     si, si
    xor     di, di
    mov     es, ax
    xor     bp, bp

    ret

clear_buffer:
    clear_buffer_loop:
        mov     byte [si], 0
        inc     si

        cmp     si, di
        jl      clear_buffer_loop

    ret

section .data
    opt_str              dd "1. KBD-->FLP | 2. FLP-->RAM | 3. RAM-->FLP"
    opt_len              equ 42

    in_awaits_str1       dd "STRING = N = {H, T, S} (one value per line)", 3ah
    str1_awaits_len1     equ 9
    str1_awaits_len2     equ 4
    str1_awaits_len3     equ 31

    in_awaits_str2       dd "SEGMENT (XXXX) = OFFSET (YYYY) = "
    str2_awaits_len1     equ 17
    str2_awaits_len2     equ 16

    err_code_msg         dd "EC="
    err_code_msg_len     equ 3

    prompt_start         dd ">>> "
    prompt_start_len     equ 4

    test_result          dw 10000
    pb_segment_len       db 0
    
section .bss
    string              resb 256
    nhts                resb 8
    address             resb 4
    storage_curr_size   resb 4
    storage_buffer      resb 1