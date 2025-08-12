[bits 16]
[org 0x7c00]

; Simple test MBR - just print a message
mov si, MSG_BOOT
call print_string
jmp $

; Print string utility
print_string:
    mov ah, 0x0e
.loop:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .loop
.done:
    ret

MSG_BOOT: db "MBR Test - Hello from bootloader!", 13, 10, 0

; padding
times 510 - ($-$$) db 0

; magic number
dw 0xaa55
