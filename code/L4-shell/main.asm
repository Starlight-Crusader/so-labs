org 7c00h     ; Set the origin of the program to 7c00h

section .bss
    input resb 256     ; Define a 256-byte buffer for input

section .text
    global _start     ; Global label for program entry point

_start:
    mov     SI, input          ; Initialize SI register to point to the start of the buffer
    call    move_curs_down     ; Just need to print the '>>> ' the process called ends up with calling typing

typing:
    mov     AH, 00h              ; Set AH register to 00h - read keyboard input
    int     16h                  ; Call the interruption to get the key press

    cmp     AL, 08h              ; Compare the value in AL with Backspace (08h) ...
	je      handle_backspace     ; If equal handle Backspace

	cmp     AL, 0Dh              ; Compare the value in AL with Enter (0Dh) ...
	je      handle_enter         ; If equal handle Enter

	cmp     SI, input + 256      ; Compare SI with the end of the buffer ...
	je      typing               ; If 256 characters were inserted, leave only Enter and Backspace as options

    mov     [SI], AL             ; Store the character in AL in the buffer at [SI]
	add     SI, 1                ; Increment SI to point to the next buffer location

    mov     AH, 0eh              ; Set AH to 0eh - write character as TTY
	int     10h                  ; Call the interruption to print on the screen

	jmp     typing               ; Continue typing

handle_backspace:
	cmp     SI, input        ; Compare SI with the start of the buffer
	je      typing           ; If SI is at the start - line is empty, we skip

	dec     SI               ; Decrement SI to point to the previous buffer location
	mov     byte [SI], 0     ; Erase the character in the buffer at [SI]

    mov     AH, 03h          ; Set AH to 03h - query cursor pos. and size
	mov     BH, 0            ; From the first page ...
	int     10h              ; Call the interruption to get the cursor information

	cmp     DL, 0            ; Prev. interruption saved the cursor column to DL ...
	jz      previous_line    ; If cursor is at the start of the line - return to the previous line

    ; Otherwise, print a blank space to effectively erase the last typed character

    mov     AH, 02h          ; Set AH to 02h - set cursor position
	dec     DL               ; Decrement DL to return the cursor one column back
	int     10h              ; Call the interruption to move the cursor

    mov     AH, 0eh          ; Set AH to 0eh - write character as TTY
    mov     AL, 20h          ; 20h for the blank space character
    int     10h              ; Call the interruption to print on the screen

    ; TTY advanced the cursor automatically so we need the return it once more

    mov     AH, 02h          ; Set AH to 02h - set cursor position
	int     10h              ; Call the interruption to move the cursor

	jmp     typing           ; Continue typing

previous_line:
    mov     AH, 02h     ; Set AH to 02h - set cursor position
	mov     DL, 79      ; Set DL to 79 (last column)
	dec     DH          ; Decrement DH to return one row back (up)
	int     10h         ; Call the interruption to move the cursor

    ; There is a character on this position we need to erase

    mov     AH, 0eh     ; Set AH to 0eh - write character as TTY
    mov     AL, 20h     ; 20h for the blank space char.
    int     10h         ; Call the interruption to print on the screen

    ; TTY advanced the cursor automatically so, to end up an the last column of the prev. row, we need to move it one column back

    mov     AH, 02h     ; Set AH to 02h for the set cursor function
	int     10h         ; Call the interruption to move the cursor

    jmp     typing      ; Continue typing

handle_enter:
    mov     AH, 03h              ; Set AH to 03h - query cursor pos. and size
	mov     BH, 0                ; From the first page ...
	int     10h                  ; Call interrupt 10h to get cursor information

	sub     SI, input            ; Calculate the number of characters in the buffer
	je      move_curs_down       ; If SI == 0 (no characters were in the buffer), just advance one row down

    jmp     identify_command     ; Proceed to check what command was inserted

move_curs_down:
	mov     AH, 03h       ; Set AH to 03h - query cursor pos. and size
	mov     BH, 0         ; From the first page ...
	int     10h           ; Call interrupt 10h to get cursor information

	mov     AH, 02h       ; Set AH to 02h - set cursor position
	mov     BH, 0         ; On the first page ...
	inc     DH            ; Increment DH - advance one row down
	int     10h           ; Call the interruption to move the cursor

	mov     SI, input     ; Reset the buffer pointer to be ready to read a new line of characters and

    ; A short '>>> ' at the start of the new line to indicate type field

    mov     DL, 0         ; From the start of the line

    mov     AX, 0x0       ; Clear AX register
    mov     ES, AX        ; Set ES register to 0 for video memory
    mov     BP, start     ; The string to display
    mov     BL, 07h       ; Set BL to 07h - print in light-gray
    mov     CX, 4         ; Set CX to 4 - 4 characters ('>>> ') to display
    mov     AX, 1301h     ; Set AH to 1301h - display string and advance the cursor
    int     0x10          ; Call the interrupt to display the string

    jmp     typing        ; Continue typing

identify_command:
    mov     DX, SI     ; Save the num of characters in the buffer

    check_about:
        cmp     DX, [about_name_len]       ; Check the length of the input
        jne     check_help                 ; If it is for sure not 'about' proceed to check the next command on the list

        mov     CX, DX
        mov     SI, input                  ; Return the pointer to the start of the buffer
        mov     DI, about_command_name     ; Set another pointer at the start of the mem. space cointaining the name of the command to be checked

        check_about_loop:
            mov     AX, [SI]             ; Load the characters fromt he SI-th position in the words
            mov     BX, [DI]             ; ...

            cmp     AX, BX               ; Compare the characters at the SI-th position
            jne     check_help           ; These are different words - proceed to check the next command on the list

            inc     SI                   ; Advance both pointers to check the next character
            inc     DI                   ; ...

            dec     CX
            jnz     check_about_loop

        jmp execute_about     ; Execute the command

    check_help:
        cmp     DX, [help_name_len]       ; Check the length of the input
        jne     check_ascii               ; This was the last one - unknown command - print error

        mov     CX, DX
        mov     SI, input                 ; Return the pointer to the start of the buffer
        mov     DI, help_command_name     ; Set another pointer at the start of the mem. space cointaining the name of the command to be checked

        check_help_loop:
            mov     AX, [SI]            ; Load the characters fromt he SI-th position in the words
            mov     BX, [DI]            ; ...

            cmp     AX, BX              ; Comapre the characters at the SI-th position
            jne     check_ascii         ; This was the last one - unknown command - print error

            inc     SI                  ; Advance both pointers to check the next character
            inc     DI                  ; ...

            dec     CX
            jnz     check_help_loop

        jmp execute_help     ; Execute the command

    check_ascii:
        cmp     DX, [ascii_name_len]      ; Check the length of the input
        jne     print_error               ; This was the last one - unknown command - print error

        mov     CX, DX
        mov     SI, input                 ; Return the pointer to the start of the buffer
        mov     DI, ascii_command_name     ; Set another pointer at the start of the mem. space cointaining the name of the command to be checked

        check_ascii_loop:
            mov     AX, [SI]            ; Load the characters fromt he SI-th position in the words
            mov     BX, [DI]            ; ...

            cmp     AX, BX              ; Comapre the characters at the SI-th position
            jne     print_error         ; This was the last one - unknown command - print error

            inc     SI                  ; Advance both pointers to check the next character
            inc     DI                  ; ...

            dec     CX
            jnz     check_ascii_loop

        jmp execute_acsii     ; Execute the command

execute_about:
    mov     AH, 03h                     ; Set AH to 03h - query cursor pos. and size
	mov     BH, 0                       ; From the first page ...
	int     10h                         ; Call interrupt 10h to get cursor information

    inc     DH
    mov     DL, 0

    mov     AX, 0x0
    mov     ES, AX
    mov     BL, 07h
    mov     CX, about_string_len
    mov     BP, about_string
    mov     AX, 1301h
    int     0x10

    jmp move_curs_down

execute_help:
    mov     AH, 03h                     ; Set AH to 03h - query cursor pos. and size
	mov     BH, 0                       ; From the first page ...
	int     10h                         ; Call interrupt 10h to get cursor information

    inc     DH
    mov     DL, 0

    mov     AX, 0x0
    mov     ES, AX
    mov     BL, 07h
    mov     CX, help_line1_len
    mov     BP, help_line1
    mov     AX, 1301h
    int     0x10

    inc     DH
    mov     DL, 0

    mov     AX, 0x0
    mov     ES, AX
    mov     BL, 07h
    mov     CX, help_line2_len
    mov     BP, help_line2
    mov     AX, 1301h
    int     0x10

    inc     DH
    mov     DL, 0

    mov     AX, 0x0
    mov     ES, AX
    mov     BL, 07h
    mov     CX, help_line3_len
    mov     BP, help_line3
    mov     AX, 1301h
    int     0x10

    jmp move_curs_down

execute_acsii:
    mov     AH, 03h                     ; Set AH to 03h - query cursor pos. and size
	mov     BH, 0                       ; From the first page ...
	int     10h                         ; Call interrupt 10h to get cursor information

    inc     DH
    mov     DL, 0

    mov     AX, 0x0
    mov     ES, AX
    mov     BL, 07h
    mov     CX, ascii_test_string_len
    mov     BP, ascii_test_string
    mov     AX, 1301h
    int     0x10

    jmp move_curs_down

print_error:
    mov     AH, 03h                     ; Set AH to 03h - query cursor pos. and size
	mov     BH, 0                       ; From the first page ...
	int     10h                         ; Call interrupt 10h to get cursor information

    inc     DH
    mov     DL, 0

    mov     AX, 0x0
    mov     ES, AX
    mov     BL, 07h
    mov     CX, error_string_len
    mov     BP, error_string
    mov     AX, 1301h
    int     0x10

    jmp move_curs_down

section .data
    start                   db '>>> ', 0

    ; --------------------

    help_command_name       db 'help', 0
    help_name_len           dw 4
    
    help_line1              db 'help - list available commands', 0
    help_line1_len          equ $ - help_line1
    
    help_line2              db 'about - print some info about the software', 0
    help_line2_len          equ $ - help_line2
    
    help_line3              db 'ascii - print aschii table', 0
    help_line3_len          equ $ - help_line3

    ; --------------------
    
    ascii_command_name      db 'ascii', 0
    ascii_name_len          dw 5

    ascii_test_string       db 'ASCII TABLE', 0
    ascii_test_string_len   equ $ - ascii_test_string
    
    ; --------------------
    
    about_command_name      db 'about', 0
    about_name_len          dw 5
    
    about_string            db 'Developed by Kalamaghin Arteom for x64'
    about_string_len        equ $ - about_string

    ; --------------------

    error_string            db 'Unknown command!', 0
    error_string_len        equ $ - error_string

section .bss
    buffer              resb 10