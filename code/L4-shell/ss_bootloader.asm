org 7e00h

; ========================================

section .text
    global  _start

_start:
    mov     ah, 00h
    int     13h

    ; read HTS

    call    read_hts_address

    ; print "How many sect-s to load? - "

    mov     si, prompt_txt2
    mov     cx, prompt_txt2_len
    call    print_ln

    ; read N

    mov     si, in_start_str
    mov     cx, in_start_str_len
    call    print_ln
    call    read_input

    ; convert ascii read to an integer

    mov     di, nhts
    call    atoi_in_conv
    mov     bx, 2
    call    conv_check

    ; read RAM

    ; call    read_ram_address
    ; call    reset_registers

    ; read the data from floppy

    mov     ah, 00h
    int     13h

    mov     ax, 0000h
    mov     es, ax
    mov     dword [addr_offset], 33280
    mov     bx, [addr_offset]

    mov     dl, 0
    mov     al, [nhts + 0]
    mov     dh, [nhts + 2]
    mov     ch, [nhts + 4]
    mov     cl, [nhts + 6]
    
    mov     ah, 02h
    int     13h

    ; check the first 2 bytes for the sequence (0xE8E8)

    mov     ax, [es:bx]
    cmp     ax, 0xE8E8
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
 
    mov     si, succ_msg
    mov     cx, succ_msg_len
    call    print_ln

    mov     ah, 00h
    int     16h

    call    clear_screen

    mov     bx, [addr_offset]
    push    bx
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

; ========================================

read_hts_address:
    
    ; print "Booting the sect. at HTS (one val. per line)"

    mov     si, prompt_txt1
    mov     cx, prompt_txt1_len
    call    print_ln

    ; read user input (h)

    mov     si, in_start_str
    mov     cx, in_start_str_len
    call    print_ln
    call    read_input

    ; convert ascii read to an integer

    mov     di, nhts + 2
    call    atoi_in_conv
    mov     bx, 0
    call    conv_check

    ; read user input (t)

    mov     si, in_start_str
    mov     cx, in_start_str_len
    call    print_ln
    call    read_input

    ; convert ascii read to an integer

    mov     di, nhts + 4
    call    atoi_in_conv
    mov     bx, 0
    call    conv_check

    ; read user input (s)

    mov     si, in_start_str
    mov     cx, in_start_str_len
    call    print_ln
    call    read_input

    ; convert ascii read to an integer

    mov     di, nhts + 6
    call    atoi_in_conv
    mov     bx, 4
    call    conv_check

    ret

read_ram_address:

    ; print "At which RAM address..."

    mov     si, prompt_txt3
    mov     cx, prompt_txt3_len
    call    print_ln

    ; read user input (offset)

    mov     si, in_start_str
    mov     cx, in_start_str_len
    call    print_ln
    call    read_input

    ; convert ascii read to a hex

    mov     di, addr_offset
    call    atoh_in_conv
    mov     bx, 33280
    call    conv_check

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

wrong_in_error:

    ; print the error msg.

    mov     si, in_err_txt
    mov     cx, in_err_txt_len
    call    print_ln

    jmp     _terminate

; ----------------------------------------

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

    xor     ax, bx
    jnz     incorrect

    correct:
        mov     ah, 0eh
        mov     al, 31h
        int     10h

        jmp     check_end

    incorrect:
        mov     ah, 0eh
        mov     al, 30h
        int     10h

    check_end:
        ret

; ----------------------------------------

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

_terminate:
    mov     word [nhts + 0], 0
    mov     word [nhts + 2], 0
    mov     word [nhts + 4], 0
    mov     word [nhts + 6], 0

    mov     dword [addr_offset], 0

    ; wait for any key to be pressed

    mov     ah, 00h
    int     16h

    call    clear_screen

    jmp     _start

; ========================================

section .data

addr_offset         dd 0

prompt_txt1         dd "Executable to boot is at HTS:"
prompt_txt1_len     equ 29

prompt_txt2         dd "How many sectors does it occupy:"
prompt_txt2_len     equ 32

prompt_txt3         dd "At which RAM address (0000:OFFSET, a part of adress per input line):"
prompt_txt3_len     equ 68

in_start_str        dd ">>> "
in_start_str_len    equ 4

in_err_txt          dd "Incorr. NHTS val-s!"
in_err_txt_len      equ 20

succ_msg            dd "Press any key..."
succ_msg_len        equ 16

section .bss
    
input_buffer    resb 4
nhts            resb 8