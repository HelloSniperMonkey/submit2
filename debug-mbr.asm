[bits 16]
[org 0x7c00]

; where to load the kernel to
KERNEL_OFFSET equ 0x1000

; BIOS sets boot drive in 'dl'; store for later use
mov [BOOT_DRIVE], dl

; setup stack
mov bp, 0x9000
mov sp, bp

; Print starting message
mov si, MSG_START
call print_string

call load_kernel

; Print kernel loaded message
mov si, MSG_KERNEL_LOADED
call print_string

call switch_to_32bit
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

%include "disk.asm"
%include "gdt.asm"
%include "switch-to-32bit.asm"

[bits 16]
load_kernel:
    mov bx, KERNEL_OFFSET ; bx -> destination
    mov dh, 16            ; dh -> num sectors (enough for ~8KB kernel)
    mov dl, [BOOT_DRIVE]  ; dl -> disk
    call disk_load
    ret

[bits 32]
BEGIN_32BIT:
    ; Just hang here for now to test if we get this far
    jmp $

; Messages
MSG_START: db "Starting boot process...", 13, 10, 0
MSG_KERNEL_LOADED: db "Kernel loaded successfully!", 13, 10, 0

; boot drive variable
BOOT_DRIVE db 0

; padding
times 510 - ($-$$) db 0

; magic number
dw 0xaa55
