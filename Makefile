# $@ = target file
# $< = first dependency
# $^ = all dependencies

# First rule is the one executed when no parameters are fed to the Makefile
all: run

kernel.bin: kernel-entry.o kernel.o idt.o keyboard.o
	i686-elf-ld -Ttext 0x1000 -o $@ $^ --oformat binary

kernel-entry.o: kernel-entry.asm
	nasm $< -f elf -o $@

kernel.o: kernel.c
	i686-elf-gcc -m32 -ffreestanding -c $< -o $@

idt.o: idt.asm
	nasm $< -f elf -o $@

keyboard.o: keyboard.asm
	nasm $< -f elf -o $@

mbr.bin: mbr.asm
	nasm $< -f bin -o $@

os-image.img: mbr.bin kernel.bin
	cat $^ > $@

run: os-image.img
	qemu-system-i386 -fda $<

clean:
	$(RM) *.bin *.o *.dis