[bits 32]

global keyboard_handler_asm
global timer_handler_asm
extern keyboard_callback
extern timer_callback

section .text

; Assembly wrapper for keyboard interrupt
keyboard_handler_asm:
    pushad                  ; Save all 32-bit registers (EAX, ECX, EDX, EBX, ESP, EBP, ESI, EDI)
    push ds                 ; Save data segment
    push es                 ; Save extra segment
    
    ; Set up kernel data segment
    mov ax, 0x10           ; Kernel data segment selector
    mov ds, ax
    mov es, ax
    
    ; Pass ESP as argument (pointer to register structure)
    push esp
    call keyboard_callback
    add esp, 4             ; Clean up stack (remove esp argument)
    
    ; Send EOI (End of Interrupt) to PIC
    mov al, 0x20
    out 0x20, al
    
    ; Restore segments and registers
    pop es
    pop ds
    popad                  ; Restore all 32-bit registers
    
    iret                   ; Return from interrupt

; Assembly wrapper for timer interrupt
timer_handler_asm:
    pushad                  ; Save all 32-bit registers
    push ds                 ; Save data segment
    push es                 ; Save extra segment
    
    ; Set up kernel data segment
    mov ax, 0x10           ; Kernel data segment selector
    mov ds, ax
    mov es, ax
    
    ; Pass ESP as argument (pointer to register structure)
    push esp
    call timer_callback
    add esp, 4             ; Clean up stack
    
    ; Send EOI (End of Interrupt) to PIC
    mov al, 0x20
    out 0x20, al
    
    ; Restore segments and registers
    pop es
    pop ds
    popad                  ; Restore all 32-bit registers
    
    iret                   ; Return from interrupt
