# Simple 32-bit Operating System

A minimal 32-bit protected-mode operating system with a basic shell, built from scratch using x86 assembly and C. This project demonstrates fundamental OS concepts including bootloading, memory management, interrupt handling, and user interaction.

## 🚀 Features

- **Bootloader**: Custom MBR (Master Boot Record) that loads the kernel
- **32-bit Protected Mode**: Transitions from 16-bit real mode to 32-bit protected mode
- **Memory Management**: Global Descriptor Table (GDT) for memory segmentation
- **Interrupt Handling**: Interrupt Descriptor Table (IDT) with PIC remapping
- **Keyboard Support**: Real-time keyboard input handling
- **Timer Support**: System timer for basic timing functionality
- **Simple Shell**: Interactive command-line interface with basic commands
- **VGA Text Mode**: Console output using VGA text buffer

## 📁 Project Structure

```
submit2/
├── mbr.asm              # Master Boot Record - initial bootloader
├── kernel-entry.asm     # Kernel entry point assembly code
├── kernel.c             # Main kernel implementation with shell
├── gdt.asm              # Global Descriptor Table setup
├── idt.asm              # Interrupt Descriptor Table and PIC setup
├── keyboard.asm         # Keyboard interrupt handler
├── disk.asm             # Disk I/O routines
├── switch-to-32bit.asm  # Mode switching from 16-bit to 32-bit
├── Makefile             # Build configuration
└── Readme.md           # This file
```

## 🛠️ Prerequisites

To build and run this operating system, you need:

- **Cross-compiler**: `i686-elf-gcc` and `i686-elf-ld`
- **NASM**: Netwide Assembler for x86 assembly
- **QEMU**: For emulating the x86 system
- **Make**: For build automation

### Installation on macOS

```bash
# Install cross-compiler toolchain
brew install i686-elf-gcc
brew install nasm
brew install qemu
```

### Installation on Ubuntu/Debian

```bash
# Install required packages
sudo apt-get update
sudo apt-get install build-essential nasm qemu-system-x86
```

## 🔨 Building the OS

### Quick Start

```bash
# Build and run the OS
make

# Clean build artifacts and rebuild
make clean && make
```

### Build Process

The build process follows these steps:

1. **Assembly Files**: NASM compiles `.asm` files to object files
2. **C Kernel**: Cross-compiler compiles `kernel.c` to object file
3. **Linking**: Object files are linked into `kernel.bin`
4. **Bootloader**: MBR is assembled to `mbr.bin`
5. **Image Creation**: MBR and kernel are concatenated into `os-image.img`
6. **Emulation**: QEMU runs the complete OS image

### Manual Build Steps

```bash
# Compile assembly files
nasm kernel-entry.asm -f elf -o kernel-entry.o
nasm idt.asm -f elf -o idt.o
nasm keyboard.asm -f elf -o keyboard.o

# Compile C kernel
i686-elf-gcc -m32 -ffreestanding -c kernel.c -o kernel.o

# Link kernel
i686-elf-ld -Ttext 0x1000 -o kernel.bin kernel-entry.o kernel.o idt.o keyboard.o --oformat binary

# Create bootloader
nasm mbr.asm -f bin -o mbr.bin

# Create OS image
cat mbr.bin kernel.bin > os-image.img

# Run in QEMU
qemu-system-i386 -fda os-image.img
```

## 🎮 Using the OS

Once the OS boots, you'll see a simple shell prompt (`>`). Available commands:

- **`help`** - Display available commands
- **`clear`** - Clear the screen
- **`echo <text>`** - Display the specified text
- **`exit`** - Reboot the system

### Example Session

```
> help
help  - show this message
clear - clear screen
echo  - echo arguments
exit  - reboot

> echo Hello, World!
Hello, World!

> clear
> exit
```

## 🔧 Technical Details

### Memory Layout

- **0x7C00**: MBR bootloader location
- **0x1000**: Kernel load address
- **0xB8000**: VGA text buffer
- **0x9000**: Stack setup

### Interrupt Handling

- **IRQ 0**: System timer
- **IRQ 1**: Keyboard controller
- **PIC Remapping**: IRQs 0-7 → Interrupts 0x20-0x27

### Protected Mode Features

- **GDT**: Flat memory model with code and data segments
- **IDT**: 256-entry interrupt descriptor table
- **Ring 0**: Kernel runs in highest privilege level

## 🐛 Debugging

### Debug Build

```bash
# Create debug version with disassembly
make debug
```

### QEMU Debug Options

```bash
# Run with debug output
qemu-system-i386 -fda os-image.img -d int,cpu_reset

# Run with serial output
qemu-system-i386 -fda os-image.img -serial stdio
```

## 📚 Learning Resources

This project demonstrates several fundamental OS concepts:

- **Boot Process**: From BIOS to kernel execution
- **Memory Segmentation**: GDT and protected mode memory management
- **Interrupt Handling**: IDT setup and interrupt service routines
- **Device Drivers**: Basic keyboard and timer drivers
- **System Programming**: Low-level x86 programming

## 🤝 Contributing

This is an educational project. Feel free to:

- Add new shell commands
- Implement additional device drivers
- Enhance the memory management system
- Add multitasking capabilities
- Improve the user interface

## 📄 License

This project is open source and available under the MIT License.

## 🙏 Acknowledgments

- Inspired by OS development tutorials and x86 architecture documentation
- Built for educational purposes to understand operating system fundamentals