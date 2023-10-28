org 7c00h

section .text
global _start

_start:
    mov     AH, 0xE         ; 0xE - write a char as TTY (M1)
    mov     AL, 'A'         ; Char to display
    int     0x10            ; Call the Video ServicES BIOS Interrupt

    mov     AH, 0x2         ; Move coursor
    mov     DH, 0x1         ; 2nd row
    mov     DL, 0x1         ; 2nd column
    int     0x10            ; Call the Video ServicES BIOS Interrupt

    ; ===============

    mov     AH, 0xA         ; 0xA - write character (M2)
    mov     AL, 'B'         ; Char to display
    mov     CX, 0x3         ; 3 timES
    int     0x10            ; Call the Video ServicES BIOS Interrupt

    mov     AH, 0x2         ; Move coursor
    mov     DH, 0x2         ; 3rd row
    mov     DL, 0x2         ; 3rd column
    int     0x10            ; Call the Video ServicES BIOS Interrupt

    ; ===============

    mov     AH, 0x9         ; 0xA - write character/attribute (M3)
    mov     AL, 'C'         ; Char to display
    mov     BL, 0x2         ; Text color (green)
    mov     CX, 0x1         ; 1 time
    int     0x10            ; Call the Video ServicES BIOS Interrupt

    ; ===============

    mov     AX, 0x0         ; ?
    mov     ES, AX          ; ?
    mov     CX, 0x1         ; 1 character to display
    mov     DH, 0x3         ; On the 4th row
    mov     DL, DH          ; In the 4th column
    mov     BP, char        ; The character to display
    mov     AX, 1302h       ; 1302h - display character/attribute cells
    int     0x10            ; Call the Video ServicES BIOS Interrupt

    ; ===============

    mov     AX, 0x0         ; ?
    mov     ES, AX          ; ?
    mov     CX, 0x1         ; 1 character to display
    mov     DH, 0x4         ; On the 5th row
    mov     DL, DH          ; In the 5th column
    mov     BP, char        ; The character to display
    mov     AX, 1303h       ; 1302h - display character/attribute cells
    int     10h             ; Call the Video ServicES BIOS Interrupt

    ; ================

    mov     AX, 0x0         ; Prepare memory
    mov     ES, AX          ; Prepare memory
    mov     BL, 0x2         ; Text color (green)
    mov     CX, 0xF         ; 15 characters to display
    mov     DH, 0x5         ; On the 6th row
    mov     DL, DH          ; In the 6th column
    mov     BP, string      ; The string to display
    mov     AX, 1300h       ; 1300h - display string 
    int     0x10            ; Call the Video ServicES BIOS Interrupt

    ; ================

    mov     AX, 0x0         ; Prepare memory
    mov     ES, AX          ; Prepare memory
    mov     BL, 0x3         ; Text color (cyan)
    mov     CX, 0xF         ; 15 characters to display
    mov     DH, 0x6         ; On the 7th row
    mov     DL, DH          ; In the 7th column
    mov     BP, string      ; The string to display
    mov     AX, 1301h       ; 1301h - display string and update cursor
    int     0x10            ; Call the Video ServicES BIOS Interrupt

section .data
    char db '0', 0x7
    string dd "Hello, World!"