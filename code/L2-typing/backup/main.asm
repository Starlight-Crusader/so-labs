org 7c00h                       ; Set the origin of the program to 7c00h

section .bss
    input resb 256              ; Define a 256-byte buffer for input

section .text
    global _start               ; Global label for program entry point

_start:
    mov     SI, input           ; Initialize SI register to point to the start of the buffer
    call    move_curs_down      ; Just need to print the ">>> " ...
                                ; the process called ends up with calling typing

typing:
    mov     AH, 00h             ; Set AH register to 00h - read keyboard input
    int     16h                 ; Call the interruption to get the key press

    cmp     AL, 08h             ; Compare the value in AL with Backspace (08h) ...
	je      handle_backspace    ; If equal handle Backspace

	cmp     AL, 0Dh             ; Compare the value in AL with Enter (0Dh) ...
	je      handle_enter        ; If equal handle Enter

	cmp     SI, input + 256     ; Compare SI with the end of the buffer ...
	je      typing              ; If 256 characters were inserted, ..
                                ; leave only Enter and Backspace as options

    mov     [SI], AL            ; Store the character in AL in the buffer at [SI]
	add     SI, 1               ; Increment SI to point to the next buffer location

    mov     AH, 0eh             ; Set AH to 0eh - write character as TTY
	int     10h                 ; Call the interruption to print on the screen

	jmp     typing              ; Continue typing

handle_backspace:
	cmp     SI, input           ; Compare SI with the start of the buffer
	je      typing              ; If SI is at the start - line is empty, we skip

	dec     SI                  ; Decrement SI to point to the previous buffer location
	mov     byte [SI], 0        ; Erase the character in the buffer at [SI]

    mov     AH, 03h             ; Set AH to 03h - query cursor pos. and size
	mov     BH, 0               ; From the first page ...
	int     10h                 ; Call the interruption to get the cursor information

	cmp     DL, 0               ; Prev. interruption saved the cursor column to DL ...
	jz      previous_line       ; If cursor is at the start of the line - ...
                                ; - return to the previous line

    ; Otherwise, print a blank space to effectively erase ...
    ; the last typed character

    mov     AH, 02h             ; Set AH to 02h - set cursor position
	dec     DL                  ; Decrement DL to return the cursor one column back
	int     10h                 ; Call the interruption to move the cursor

    mov     AH, 0eh             ; Set AH to 0eh - write character as TTY
    mov     AL, 20h             ; 20h for the blank space character
    int     10h                 ; Call the interruption to print on the screen

    ; TTY advanced the cursor automatically so we need the return it once more

    mov     AH, 02h             ; Set AH to 02h - set cursor position
	int     10h                 ; Call the interruption to move the cursor

	jmp     typing              ; Continue typing

previous_line:
    mov     AH, 02h             ; Set AH to 02h - set cursor position
	mov     DL, 79              ; Set DL to 79 (last column)
	dec     DH                  ; Decrement DH to return one row back (up)
	int     10h                 ; Call the interruption to move the cursor

    ; There is a character on this position we need to erase

    mov     AH, 0eh             ; Set AH to 0eh - write character as TTY
    mov     AL, 20h             ; 20h for the blank space char.
    int     10h                 ; Call the interruption to print on the screen

    ; TTY advanced the cursor automatically so, to end up ...
    ; an the last column of the prev. row, we need to move it one column back

    mov     AH, 02h             ; Set AH to 02h for the set cursor function
	int     10h                 ; Call the interruption to move the cursor

    jmp     typing              ; Continue typing

handle_enter:
    mov     AH, 03h             ; Set AH to 03h - query cursor pos. and size
	mov     BH, 0               ; From the first page ...
	int     10h                 ; Call interrupt 10h to get cursor information

	sub     SI, input           ; Calculate the number of characters in the buffer
	je      move_curs_down      ; If SI == 0 (no characters were in the buffer), ...
                                ; just advance one row down

	cmp     DH, 24              ; Compare DH with 24 (the max. row val)...
	jmp     print_buffer        ; If DH is less than 24, print the buffer

    ; Else it is possible to scroll the screen down to ...
    ; fit another line

print_buffer:
    mov     AH, 03h             ; Set AH to 03h - query cursor pos. and size
	mov     BH, 0               ; From the first page ...
	int     10h                 ; Call interrupt 10h to get cursor information

    mov     BH, 0               ; On the first page ...
    inc     DH                  ; Increment DH - from the next row
    mov     DL, 0               ; From the start of the next line

	mov     AX, 0               ; Clear AX register
	mov     ES, AX              ; Set ES register to 0 for video memory
	mov     BP, input           ; Send reference to the start of the buffer
	mov     BL, 07h             ; Set BL to 07h - print in light-gray
	mov     CX, SI              ; Set CX to the number of characters in the ...
                                ; buffer (stored in SI after line 89)
	mov     AX, 1301h           ; Set AH to 1300h - display string and advance the cursor
	int     10h                 ; Call the interrupt to display the string

    ; Don't need a jump since we anyway need to move to the next ...
    ; line after buffer echo - handled by the floowong process

move_curs_down:
	mov     AH, 03h             ; Set AH to 03h - query cursor pos. and size
	mov     BH, 0               ; From the first page ...
	int     10h                 ; Call interrupt 10h to get cursor information

	mov     AH, 02h             ; Set AH to 02h - set cursor position
	mov     BH, 0               ; On the first page ...
	inc     DH                  ; Increment DH - advance one row down
	int     10h                 ; Call the interruption to move the cursor

	mov     SI, input           ; Reset the buffer pointer to be ready ...
                                ; to read a new line of characters and

    ; A short ">>> " at the start of the new line to indicate type field

    mov     DL, 0               ; From the start of the line

    mov     AX, 0x0             ; Clear AX register
    mov     ES, AX              ; Set ES register to 0 for video memory
    mov     BP, string          ; The string to display
    mov     BL, 07h             ; Set BL to 07h - print in light-gray
    mov     CX, 4               ; Set CX to 4 - 4 characters (">>> ") to display
    mov     AX, 1301h           ; Set AH to 1301h - display string and advance the cursor
    int     0x10                ; Call the interrupt to display the string

    jmp     typing              ; Continue typing

section .data
    string dd ">>> "            ; Just a string to start echo line with