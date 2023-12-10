org 7e00h

; ========================================

section .text
    global  start

start:
    call    reset_memory
    xor     sp, sp

    ; read HTS

    call    read_hts_address

    cmp     byte [operation_flag], 0
    je      error

    ; print "How many sect-s to load? - "

    mov     si, prompt_str2
    mov     cx, prompt_str2_len
    call    print_ln

    ; read N

    mov     si, in_start_str
    mov     cx, in_start_str_len
    call    print_ln
    call    read_input

    mov     ax, 0
    call    check_num_input

    cmp     byte [operation_flag], 0
    je      error

    ; convert ascii read to an integer

    mov     di, nhts
    call    atoi_in_conv

    ; read RAM

    call    read_ram_address

    cmp     byte [operation_flag], 0
    je      error

    ; read the data from floppy

    mov     es, [address + 0]
    mov     bx, [address + 2]

    mov     al, [nhts + 0]
    mov     dl, 0
    mov     dh, [nhts + 2]
    mov     ch, [nhts + 4]
    mov     cl, [nhts + 6]

    mov     ah, 02h
    int     13h

    ; check the first 2 bytes for the sequence (0xE8E8)

    mov     ax, [es:bx]
    cmp     ax, 0x0FE8
    jne     wrong_in_error

    ; check the last 2 bytes for the signature (0x5355)

    mov     ax, [nhts]
    imul    ax, 512

    push    bx
    add     bx, ax
    sub     bx, 2
    mov     ax, [es:bx]
    pop     bx

    cmp     ax, 0x5355
    jne     wrong_in_error
    
    call    wait_for_keypress
    call    clear_screen

    mov     si, [address + 2]
    push    si
    ret

; ========================================

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

        cmp     si, input_buffer + 4
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

; ========================================

atoi_in_conv:
    mov     si, input_buffer

    atoi_conv_loop:

        ; check if all the digits were converted

        cmp     byte [si], 0
        je      atoi_conv_done

        ; convert the digit-character's bytes to the number equivalent

        xor     ax, ax
        mov     al, [si]
        sub     al, '0'

        ; shift all the digits one place left and put a new digit at the first place

        mov     bx, [di]
        imul    bx, 10
        add     bx, ax
        mov     [di], bx

        ; advance to pint at the next digit-char

        inc     si

        jmp     atoi_conv_loop

    atoi_conv_done:
        ret

; ----------------------------------------

atoh_in_conv:
    mov     si, input_buffer

    atoh_conv_loop:

        ; check if all the digits were converted

        cmp     byte [si], 0
        je      atoh_conv_done

        ; convert the digit-/letters-characters accordingly: there are 7 symbols between '9' and 'A' ('A' -> 10 --- 65 - 55 = 10)

        xor     ax, ax
        mov     al, [si]
        cmp     al, 65
        jl      conv_digit  

        conv_letter:
            sub     al, 55
            jmp     atoh_finish_iteration

        conv_digit:
            sub     al, 48

        ; shift all the digits one place left and put a new digit at the first place, keeping in mind that
        ; we need to get a hex value at the end

        atoh_finish_iteration:
            mov     bx, [di]
            imul    bx, 16
            add     bx, ax
            mov     [di], bx

            ; advance to point at the next digit-char

            inc     si

        jmp     atoh_conv_loop

    atoh_conv_done:
        ret

; ----------------------------------------

check_num_input:
    mov     si, input_buffer
    mov     byte [operation_flag], 1

    check_char_loop:
        cmp     byte [si], 00h
        je      check_input_approved

        check_char_block:

            check_digits:
                cmp     byte [si], 30h
                jl      check_input_denied

                cmp     byte [si], 39h
                jle     char_approved

                cmp     ax, 1
                je      check_letters

                jmp     check_input_denied

            check_letters:
                cmp     byte [si], 41h
                jl      check_input_denied

                cmp     byte [si], 46h
                jg      check_input_denied

            char_approved:
                inc     si
                jmp     check_char_loop

    check_input_denied:
        mov     byte [operation_flag], 0

    check_input_approved:
        ret

; ========================================

read_hts_address:
    
    ; print "Booting the sect. at HTS ..."

    mov     si, prompt_str1
    mov     cx, prompt_str1_len
    call    print_ln

    mov     word [mp_16bit_counter], 1

    read_hts_address_loop:

        ; read user input (h)

        mov     si, in_start_str
        mov     cx, in_start_str_len
        call    print_ln
        call    read_input

        ; check the input

        mov     ax, 0
        call    check_num_input

        cmp     byte [operation_flag], 0
        je      read_hts_address_end

        ; convert 

        mov     di, nhts
        mov     cx, [mp_16bit_counter]
        imul    cx, 2
        add     di, cx
        call    atoi_in_conv

        ; ----------

        inc     word [mp_16bit_counter]

        cmp     word [mp_16bit_counter], 3
        jle     read_hts_address_loop

    read_hts_address_end:
        ret

read_ram_address:

    ; print "At which RAM address..."

    mov     si, prompt_str3
    mov     cx, prompt_str3_len
    call    print_ln

    ; read user input (offset)

    mov     si, in_start_str
    mov     cx, in_start_str_len
    call    print_ln
    call    read_input

    ; check the input

    mov     ax, 1
    call    check_num_input

    cmp     byte [operation_flag], 0
    je      read_ram_address_end

    ; convert ascii read to a hex

    mov     di, address + 2
    call    atoh_in_conv

    read_ram_address_end:
        ret

; ========================================

print_ln:
    push    cx

    call    get_cursor_pos
    inc     dh
    mov     dl, 0

    xor     ax, ax
    mov     es, ax
    mov     bp, si

    mov     bl, 07h
    pop     cx

    mov     ax, 1301h
    int     10h

    ret

; ----------------------------------------

clear_screen:
    call    ret_cursor
    mov     dx, 12

    clear_screen_loop:
        mov     ah, 09h
        mov     al, 20h
        mov     bh, 0
        mov     cx, 80
        int     10h

        push    dx
        mov     si, in_start_str
        mov     cx, 0
        call    print_ln
        pop     dx

        dec     dx
        jnz     clear_screen_loop

    call    ret_cursor

    ret

; ----------------------------------------

get_cursor_pos:
    mov     ah, 03h
    mov     bh, 0
    int     10h

    ret

; ----------------------------------------

ret_cursor:
    mov     ah, 02h
    mov     bh, 0
    mov     dh, 0
    mov     dl, 0
    int     10h

    ret

; ----------------------------------------

wait_for_keypress:
    mov     si, pak_msg
    mov     cx, pak_msg_len
    call    print_ln

    mov     ah, 00h
    int     16h

    ret

; ========================================

wrong_in_error:

    ; print the error msg.

    mov     si, in_err_msg
    mov     cx, in_err_msg_len
    call    print_ln

    jmp     terminate

error:
    call    get_cursor_pos

    xor     ax, ax
    mov     es, ax
    mov     bp, err_msg

    mov     cx, err_msg_len
    mov     bl, 07h

    mov     ax, 1301h
    int     10h

    jmp     terminate

; ========================================

reset_memory:
    mov     ah, 00h
    int     13h

    mov     word [nhts + 0], 0000h
    mov     word [nhts + 2], 0000h
    mov     word [nhts + 4], 0000h
    mov     word [nhts + 6], 0000h

    mov     word [address + 0], 0000h
    mov     word [address + 2], 0000h

    mov     word [input_buffer + 0], 0000h
    mov     word [input_buffer + 2], 0000h

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

; ========================================

terminate:
    call    wait_for_keypress

    call    clear_screen

    jmp     start

; ========================================

section .data

prompt_str1         db "Executable to boot is at HTS:"
prompt_str1_len     equ 29

prompt_str2         db "How many sectors does it occupy:"
prompt_str2_len     equ 32

prompt_str3         db "At which RAM address (0000:OFFSET) to load the kernel:"
prompt_str3_len     equ 54

in_start_str        db ">>> "
in_start_str_len    equ 4

in_err_msg          db "Incorr. NHTS / RAM val-s inserted!"
in_err_msg_len      equ 34

pak_msg             db "Press any key to continue..."
pak_msg_len         equ 28

err_msg             db " >> ERR", 00h
err_msg_len         equ 7

operation_flag      db 0
mp_16bit_counter    dw 0

section .bss
    
input_buffer    resb 4
address         resb 4
nhts            resb 8