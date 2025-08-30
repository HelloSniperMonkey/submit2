# submit2 — tiny 32-bit protected-mode kernel (educational)

This repository contains a small, educational x86 kernel written in C and x86
assembly. It's intended as a learning project: a bootable image with a tiny
kernel that switches to 32-bit protected mode, installs a minimal IDT/PIC
support, provides keyboard input and a simple shell using the VGA text buffer.

Files in this repo (relevant):

- `mbr.asm`          — MBR bootloader that loads the kernel to 0x1000
- `kernel-entry.asm` — 32-bit kernel entry wrapper that calls `start_kernel`
- `kernel.c`         — Kernel: VGA output, simple shell, keyboard and timer logic
- `idt.asm`          — IDT/PIC related assembly (interrupt wiring)
- `keyboard.asm`     — IRQ wrappers for keyboard and timer
- `Makefile`         — Build rules (see below)
- `kernel.bin`       — Linked binary kernel (build artifact)
- `mbr.bin`          — Assembled MBR (build artifact)
- `os-image.img`     — Concatenation of `mbr.bin` + `kernel.bin` (build artifact)

Note: some helper includes referenced by `mbr.asm` (for disk/GDT switching)
may be split into additional files in other branches; this README documents
what is currently present in the workspace.

Features implemented in the code:

- VGA text-mode console (writes directly to 0xB8000)
- Simple shell with commands: `help`, `clear`, `echo`, `exit`
- Keyboard IRQ handler and scan-code to ASCII mapping
- Timer IRQ hook (simple tick counter)
- IDT installation and PIC remapping hooks (implemented in `idt.asm`)

Prerequisites

You will need the following tools to build and run the image locally:

- `nasm` — assembler
- `i686-elf-gcc` and `i686-elf-ld` — cross-compiler and linker (or a suitable
	i386 toolchain that can produce 32-bit freestanding binaries)
- `qemu-system-i386` — to run the resulting image in an emulator
- `make`

On macOS you can install `nasm` and `qemu` via Homebrew. Cross-compilers
often need to be built or installed separately (tool names vary by distro).

Build and run

The `Makefile` provides a few targets. The default `make` invokes the `run`
target which launches QEMU; to only build the image without running it, build
the `os-image.img` target directly.

### Quick build (no emulator):

```bash
make os-image.img
```

Build and run in QEMU (default `make` runs this):

```bash
make       # runs the 'run' target which invokes qemu-system-i386 -fda os-image.img
```

Other useful targets in the Makefile:

- `make kernel.bin` — assemble/link the kernel binary
- `make mbr.bin`    — assemble the MBR boot sector
- `make clean`      — remove built artifacts (Makefile's `clean` is present)

### Manual build steps (what the Makefile does):

1. Assemble `.asm` sources with `nasm -f elf` (or `-f bin` for the MBR).
2. Compile `kernel.c` with a freestanding 32-bit cross-compiler flag
	 (example: `i686-elf-gcc -m32 -ffreestanding -c kernel.c -o kernel.o`).
3. Link object files into a flat binary at 0x1000 using the linker
	 (`i686-elf-ld -Ttext 0x1000 -o kernel.bin <objs> --oformat binary`).
4. Concatenate `mbr.bin` and `kernel.bin` into `os-image.img`.

Usage inside the running OS

When the image boots (in QEMU or real hardware), a simple prompt (`>`) is
present. Supported commands (case-insensitive in the C code):

- `help`  — list available commands
- `clear` — clear the VGA screen
- `echo`  — echo the following text
- `exit`  — trigger a BIOS reboot

### Example session:

> help

help  - show this message
clear - clear screen
echo  - echo arguments
exit  - reboot

### Development notes

- Keyboard and timer IRQ assembly wrappers are in `keyboard.asm` and call
	C callbacks implemented in `kernel.c`.
- `kernel.c` exposes `start_kernel` which is invoked from `kernel-entry.asm`.
- The kernel uses VGA direct memory writes and port I/O (`inb`/`outb`).

If you want help adding features (new shell commands, drivers, or memory
management), open an issue or send a patch with a focused change.

### References: 

https://dev.to/frosnerd/writing-my-own-boot-loader-3mld