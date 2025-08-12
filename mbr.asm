[bits 16]
[org 0x7c00]

; where to load the kernel to
KERNEL_OFFSET equ 0x1000

; BIOS sets boot drive in 'dl'; store for later use
mov [BOOT_DRIVE], dl

; setup stack
mov bp, 0x9000
mov sp, bp

; Print loading message
mov si, MSG_LOAD_KERNEL
call print_string

call load_kernel

; Print switching message
mov si, MSG_SWITCH_32BIT
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
    call KERNEL_OFFSET ; give control to the kernel
    jmp $ ; loop in case kernel returns

; Messages
MSG_LOAD_KERNEL: db "Loading kernel...", 13, 10, 0
MSG_SWITCH_32BIT: db "Switching to 32-bit mode...", 13, 10, 0

; boot drive variable
BOOT_DRIVE db 0

; padding
times 510 - ($-$$) db 0

; magic number
dw 0xaa55