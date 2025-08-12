[bits 32]
[extern start_kernel]

global _start
_start:
call start_kernel
jmp $