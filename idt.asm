[bits 32]

global install_idt
global remap_pic
global enable_irq

section .data
; IDT with 256 entries, each 8 bytes
idt_entries times 256*8 db 0

; IDT descriptor
idt_descriptor:
    dw 256*8-1  ; size
    dd idt_entries ; address

section .text

; Install basic IDT
install_idt:
    ; Set up default interrupt handlers (just infinite loop for now)
    mov eax, default_handler
    mov ecx, 256
    mov edi, idt_entries
    
.loop:
    ; Low 16 bits of handler address
    mov [edi], ax
    ; Selector (kernel code segment)
    mov word [edi+2], 0x08
    ; Clear reserved byte
    mov byte [edi+4], 0
    ; Type and attributes (present, ring 0, 32-bit interrupt gate)
    mov byte [edi+5], 0x8E
    ; High 16 bits of handler address
    mov edx, eax
    shr edx, 16
    mov [edi+6], dx
    
    add edi, 8
    loop .loop
    
    ; Load IDT
    lidt [idt_descriptor]
    ret

; Remap PIC (Programmable Interrupt Controller)
remap_pic:
    ; Save masks
    in al, 0x21
    mov cl, al
    in al, 0xA1
    mov ch, al
    
    ; Start initialization sequence
    mov al, 0x11
    out 0x20, al    ; Master PIC
    out 0xA0, al    ; Slave PIC
    
    ; Set vector offsets
    mov al, 0x20    ; Master PIC starts at 0x20
    out 0x21, al
    mov al, 0x28    ; Slave PIC starts at 0x28
    out 0xA1, al
    
    ; Tell master about slave
    mov al, 0x04
    out 0x21, al
    ; Tell slave its cascade identity
    mov al, 0x02
    out 0xA1, al
    
    ; Set mode to 8086
    mov al, 0x01
    out 0x21, al
    out 0xA1, al
    
    ; Restore masks
    mov al, cl
    out 0x21, al
    mov al, ch
    out 0xA1, al
    ret

; Enable specific IRQ
enable_irq:
    push ebp
    mov ebp, esp
    
    ; Get IRQ number from first argument
    mov eax, [ebp+8]
    
    ; Get handler from second argument
    mov edx, [ebp+12]
    
    ; Install handler in IDT
    mov ecx, eax
    add ecx, 0x20   ; IRQ 0 maps to interrupt 0x20
    shl ecx, 3      ; multiply by 8 (each IDT entry is 8 bytes)
    add ecx, idt_entries
    
    ; Install handler address
    mov [ecx], dx       ; low 16 bits
    mov word [ecx+2], 0x08  ; kernel code segment
    mov byte [ecx+4], 0     ; reserved byte must be 0
    mov byte [ecx+5], 0x8E  ; present, ring 0, interrupt gate
    shr edx, 16
    mov [ecx+6], dx     ; high 16 bits
    
    ; Enable IRQ in PIC
    cmp eax, 8
    jl .master_pic
    
    ; Slave PIC (IRQ 8-15)
    ; First enable IRQ 2 (cascade) on master PIC
    in al, 0x21
    and al, 0xFB    ; Clear bit 2 (enable IRQ 2)
    out 0x21, al
    
    ; Now enable the specific IRQ on slave PIC
    sub eax, 8
    mov bl, 1
    mov cl, al
    shl bl, cl
    not bl
    in al, 0xA1
    and al, bl
    out 0xA1, al
    jmp .done
    
.master_pic:
    ; Master PIC (IRQ 0-7)
    mov bl, 1
    mov cl, al
    shl bl, cl
    not bl
    in al, 0x21
    and al, bl
    out 0x21, al
    
.done:
    pop ebp
    ret

; Default interrupt handler
default_handler:
    iret
