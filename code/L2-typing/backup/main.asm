section .text
    ; org     7c00h               ; Set the origin of the program to 7c00h
    global  _start              ; Global label for program entry point

_start:
    mov     si, input           ; Initialize si register to point to the start of the buffer
    call    move_curs_down      ; Just need to print the ">>> " the process called ends up with calling typing

typing:
    mov     ah, 00h             ; Set ah register to 00h - read keyboard input
    int     16h                 ; Call the interruption to get the key press

    cmp     al, 08h             ; Compare the value in al with Backspace (08h) ...
	je      handle_backspace    ; If equal handle Backspace

	cmp     al, 0dh             ; Compare the value in al with Enter (0dh) ...
	je      handle_enter        ; If equal handle Enter

	cmp     si, input + 256     ; Compare si with the end of the buffer ...
	je      typing              ; If 256 characters were inserted, leave only Enter and Backspace as options

    mov     [si], al            ; Store the character in al in the buffer at [si]
	add     si, 1               ; Increment si to point to the next buffer location

    mov     ah, 0eh             ; Set ah to 0eh - write character as TTY
	int     10h                 ; Call the interruption to print on the screen

	jmp     typing              ; Continue typing

handle_backspace:
	cmp     si, input           ; Compare si with the start of the buffer
	je      typing              ; If si is at the start - line is empty, we skip

	dec     si                  ; Decrement si to point to the previous buffer location
	mov     byte [si], 0        ; Erase the character in the buffer at [si]

    mov     ah, 03h             ; Set ah to 03h - query cursor pos. and size
	mov     bh, 0               ; From the first page ...
	int     10h                 ; Call the interruption to get the cursor information

	cmp     dl, 0               ; Prev. interruption saved the cursor column to dl ...
	jz      previous_line       ; If cursor is at the start of the line - return to the previous line

    ; Otherwise, print a blank space to effectively erase the last typed character

    mov     ah, 02h             ; Set ah to 02h - set cursor position
	dec     dl                  ; Decrement dl to return the cursor one column back
	int     10h                 ; Call the interruption to move the cursor

    mov     ah, 0eh             ; Set ah to 0eh - write character as TTY
    mov     al, 20h             ; 20h for the blank space character
    int     10h                 ; Call the interruption to print on the screen

    ; TTY advanced the cursor automatically so we need the return it once more

    mov     ah, 02h             ; Set ah to 02h - set cursor position
	int     10h                 ; Call the interruption to move the cursor

	jmp     typing              ; Continue typing

previous_line:
    mov     ah, 02h             ; Set ah to 02h - set cursor position
	mov     dl, 79              ; Set dl to 79 (last column)
	dec     dh                  ; Decrement dh to return one row back (up)
	int     10h                 ; Call the interruption to move the cursor

    ; There is a character on this position we need to erase

    mov     ah, 0eh             ; Set ah to 0eh - write character as TTY
    mov     al, 20h             ; 20h for the blank space char.
    int     10h                 ; Call the interruption to print on the screen

    ; TTY advanced the cursor automatically so, to end up an the last column of the prev. row, we need to move it one column back

    mov     ah, 02h             ; Set ah to 02h for the set cursor function
	int     10h                 ; Call the interruption to move the cursor

    jmp     typing              ; Continue typing

handle_enter:
    mov     ah, 03h             ; Set ah to 03h - query cursor pos. and size
	mov     bh, 0               ; From the first page ...
	int     10h                 ; Call interrupt 10h to get cursor information

	sub     si, input           ; Calculate the number of characters in the buffer
	je      move_curs_down      ; If si == 0 (no characters were in the buffer), just advance one row down

	cmp     dh, 24              ; Compare dh with 24 (the max. row val)...
	jmp     print_buffer        ; If dh is less than 24, print the buffer

    ; Else it is possible to scroll the screen down to fit another line

print_buffer:
    mov     ah, 03h             ; Set ah to 03h - query cursor pos. and size
	mov     bh, 0               ; From the first page ...
	int     10h                 ; Call interrupt 10h to get cursor information

    mov     bh, 0               ; On the first page ...
    inc     dh                  ; Increment dh - from the next row
    mov     dl, 0               ; From the start of the next line

	mov     ax, 0               ; Clear ax register
	mov     es, ax              ; Set es register to 0 for video memory
	mov     bp, input           ; Send reference to the start of the buffer
	mov     bl, 07h             ; Set bl to 07h - print in light-gray
	mov     cx, si              ; Set cx to the number of characters in the buffer (stored in si after line 89)
	mov     ax, 1301h           ; Set ah to 1300h - display string and advance the cursor
	int     10h                 ; Call the interrupt to display the string

    ; Don't need a jump since we anyway need to move to the next line after buffer echo - handled by the floowong process

move_curs_down:
	mov     ah, 03h             ; Set ah to 03h - query cursor pos. and size
	mov     bh, 0               ; From the first page ...
	int     10h                 ; Call interrupt 10h to get cursor information

	mov     ah, 02h             ; Set ah to 02h - set cursor position
	mov     bh, 0               ; On the first page ...
	inc     dh                  ; Increment dh - advance one row down
	int     10h                 ; Call the interruption to move the cursor

	mov     si, input           ; Reset the buffer pointer to be ready to read a new line of characters and

    ; A short ">>> " at the start of the new line to indicate type field

    mov     dl, 0               ; From the start of the line

    mov     ax, 0x0             ; Clear ax register
    mov     es, ax              ; Set es register to 0 for video memory
    mov     bp, string          ; The string to display
    mov     bl, 07h             ; Set bl to 07h - print in light-gray
    mov     cx, 4               ; Set cx to 4 - 4 characters (">>> ") to display
    mov     ax, 1301h           ; Set ah to 1301h - display string and advance the cursor
    int     0x10                ; Call the interrupt to display the string

    jmp     typing              ; Continue typing

section .data
    string dd ">>> "            ; Just a string to start echo line with

section .bss
    input resb 256              ; Define a 256-byte buffer for input