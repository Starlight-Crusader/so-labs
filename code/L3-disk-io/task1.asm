org 7c00h

section .data
    to_write_str    dd "@@@FAF-211 Arteom KALAMAGHIN###"
    to_write_len    equ $ - to_write_str - 1

    first_track     equ 28  ; 511 = 18 (sectors per track) * 28 + 7
    first_sector    equ 8   ; 7 -> 8

    last_track      equ 30  ; 540 = 18 (sectors per track) * 30 + 0
    last_sector     equ 1   ; 0 -> 1

section .bss
    in_buffer       resb 512
    out_buffer      resb 512

section .text
    global          _start

_start:
    write:
        mov     di, in_buffer

        mov     cx, 11
        push    cx
        fill_buffer:
            pop     cx
            dec     cx
            jz      zeros

            push    cx

            mov     si, to_write_str
            mov     cx, to_write_len

            jmp     copy_string_to_buffer

            zeros:
                push    di
                sub     di, in_buffer

                cmp     di, 512
                je      write_to_disk

                pop     di
                mov     byte [di], 30h
                inc     di

                jmp     zeros

copy_string_to_buffer:
    mov     al, [si]
    mov     [di], al

    inc     si
    inc     di

    dec     cx
    jnz     copy_string_to_buffer

    jmp     fill_buffer

write_to_disk:
    mov     ax, 0
	mov     es, ax
    mov     bx, in_buffer

    mov     ah, 03h
    mov     al, 1
    mov     ch, first_track
    mov     cl, first_sector
    mov     dh, 0
    mov     dl, 0

    int     13h
    jc      io_error

    mov     ax, 0
	mov     es, ax
    mov     bx, in_buffer

    mov     ah, 03h
    mov     al, 1
    mov     ch, last_track
    mov     cl, last_sector
    mov     dh, 0
    mov     dl, 0

    int     13h
    jc      io_error

    jmp     read_from_disk

read_from_disk:
    mov     ax, 0
	mov     es, ax
    mov     bx, out_buffer

    mov     ah, 02h
    mov     al, 1
    mov     ch, first_track
    mov     cl, first_sector
    mov     dh, 0
    mov     dl, 0

    int     13h
    jc      io_error

    jmp     print_buffer

io_error:
    push    52h
    push    4fh
    push    52h
    push    52h
    push    45h

    mov     cx, 5
    print_error:
        mov     ah, 0eh
        pop     bx
        mov     al, bl
        int     10h

        dec     cx
        jnz     print_error

    jmp     _end

print_buffer:
    mov     bh, 0
    mov     dh, 0
    mov     dl, 0

    mov     ax, 0
    mov     es, ax
    mov     bp, out_buffer
    mov     bl, 07h
    mov     cx, 512

    mov     ax, 1301h
    int     10h

_end: