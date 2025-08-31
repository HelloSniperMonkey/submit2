/* kernel.c — a tiny 32-bit protected-mode kernel with a simple shell */

#include <stdint.h>
#include <stdbool.h>

/* VGA text buffer at 0xB8000 */
static volatile uint16_t* const VGA = (void*)0xB8000;
static int cursor_pos = 0;

/* shell input buffer */
#define MAX_INPUT 128
static char input_buf[MAX_INPUT];

/* I/O port helpers */
static inline void outb(uint16_t port, uint8_t val) {
  asm volatile("outb %0,%1" : : "a"(val), "Nd"(port));
}
static inline uint8_t inb(uint16_t port) {
  uint8_t ret;
  asm volatile("inb %1,%0" : "=a"(ret) : "Nd"(port));
  return ret;
}

/* update hardware cursor */
static void update_cursor() {
  uint16_t pos = cursor_pos;
  outb(0x3D4, 0x0F);
  outb(0x3D5, pos & 0xFF);
  outb(0x3D4, 0x0E);
  outb(0x3D5, (pos >> 8) & 0xFF);
}

/* put a character at cursor */
static void putchar(char c) {
  if (c == '\n') {
    cursor_pos += 80 - (cursor_pos % 80);
  } else {
    VGA[cursor_pos++] = (uint8_t)c | (0x07 << 8);
  }
  if (cursor_pos >= 80*25) cursor_pos = 0;
  update_cursor();
}

/* print a NUL-terminated string */
static void printk(const char* s) {
  for (int i = 0; s[i]; i++) putchar(s[i]);
}

/* clear the screen */
static void clear_screen() {
  for (int i = 0; i < 80*25; i++)
    VGA[i] = ' ' | (0x07 << 8);
  cursor_pos = 0;
  update_cursor();
}

/* prompt */
static void prompt() {
  printk("> ");
}

/* string utilities */
static int strlen(const char* s) {
  int i = 0;
  while (s[i]) i++;
  return i;
}
static int strcmp(const char* a, const char* b) {
  int i = 0;
  while (a[i] && a[i] == b[i]) i++;
  return (int)(unsigned char)a[i] - (int)(unsigned char)b[i];
}
static bool starts_with(const char* s, const char* p) {
  for (int i = 0; p[i]; i++)
    if (s[i] != p[i]) return false;
  return true;
}

/* handle a completed command line */
static void execute(const char* cmd) {
  if (strcmp(cmd, "HELP") == 0) {
    printk("\n");
    printk("help  - show this message\n");
    printk("clear - clear screen\n");
    printk("echo  - echo arguments\n");
    printk("exit  - reboot\n");
  }
  else if (strcmp(cmd, "CLEAR") == 0) {
    clear_screen();
  }
  else if (starts_with(cmd, "ECHO ")) {
    printk("\n");
    printk(cmd + 5);
    printk("\n");
  }
  else if (strcmp(cmd, "EXIT") == 0) {
  /* graceful shutdown: show messages, then disable keyboard input */
  printk("\nShutting down DummyOS...\n");
  printk("Goodbye!\n");
  /* mask keyboard IRQ (IRQ1) on PIC */
  uint8_t mask = inb(0x21);
  outb(0x21, mask | 0x02);
  /* disable keyboard at controller */
  outb(0x64, 0xAD);
  /* do not show a new prompt; CPU will just hlt in main loop */
  return; /* skip prompt */
  }
  else {
    printk("\nUnknown command: ");
    printk(cmd);
    printk("\n");
  }
  /* always show next prompt */
  prompt();
}

/* keyboard IRQ handler */
#define SC_MAX      57
#define BACKSPACE   0x0E
#define ENTER       0x1C
static const char sc_to_chr[] = {
  0, 0, '1','2','3','4','5','6','7','8','9','0','-','=', 0, 0,
  'Q','W','E','R','T','Y','U','I','O','P','[',']', 0, 0, 'A','S',
  'D','F','G','H','J','K','L',';','\'','`', 0, '\\','Z','X','C','V',
  'B','N','M',',','.','/','?','?','?',' '
};

struct regs { uint32_t dummy; };

/* forward */
void keyboard_callback(struct regs* r);
void timer_callback(struct regs* r);

/* Simple timer interrupt handler for testing */
static int timer_ticks = 0;
void timer_callback(struct regs* r) {
  (void)r;
  timer_ticks++;
  /* Remove the visual timer indicator since keyboard is working */
  /* if (timer_ticks % 18 == 0) {
    putchar('T');
  } */
}

/* debug helper to check PIC masks */
static void check_pic_masks() {
  uint8_t master = inb(0x21);
  uint8_t slave = inb(0xA1);
  printk("  PIC masks: Master=0x");
  /* Simple hex print */
  char hex[] = "0123456789ABCDEF";
  putchar(hex[(master >> 4) & 0xF]);
  putchar(hex[master & 0xF]);
  printk(" Slave=0x");
  putchar(hex[(slave >> 4) & 0xF]);
  putchar(hex[slave & 0xF]);
  printk("\n");
}

extern void install_idt();
extern void remap_pic();
extern void enable_irq(int irq, void (*handler)(struct regs*));
extern void keyboard_handler_asm();
extern void timer_handler_asm();

/* initialize timer IRQ for testing */
static void init_timer() {
  printk("  Setting up timer IRQ 0...\n");
  enable_irq(0, (void (*)(struct regs*))timer_handler_asm);
}

/* initialize keyboard IRQ */
static void init_keyboard() {
  printk("  Configuring PS/2 controller...\n");
  /* Initialize PS/2 keyboard controller */
  /* Disable keyboard */
  outb(0x64, 0xAD);
  
  /* Flush output buffer */
  while (inb(0x64) & 0x01) {
    inb(0x60);
  }
  
  /* Get controller configuration byte */
  outb(0x64, 0x20);
  while (!(inb(0x64) & 0x01));
  uint8_t config = inb(0x60);
  
  /* Enable keyboard interrupt (bit 0) and disable mouse interrupt (bit 1) */
  config |= 0x01;   /* Enable keyboard interrupt */
  config &= ~0x20;  /* Enable keyboard clock */
  
  /* Set controller configuration */
  outb(0x64, 0x60);
  while (inb(0x64) & 0x02);
  outb(0x60, config);
  
  /* Enable keyboard */
  outb(0x64, 0xAE);
  
  printk("  Enabling keyboard IRQ...\n");
  enable_irq(1, (void (*)(struct regs*))keyboard_handler_asm);
  
  check_pic_masks();
  printk("  Keyboard ready!\n");
}

/* buffer write position */
static int buf_pos = 0;

void keyboard_callback(struct regs* r) {
  (void)r;
  uint8_t sc = inb(0x60);

  /* if exit was invoked, ignore any further input */
  /* We detect this by checking that keyboard IRQ is masked (bit 1) */
  if (inb(0x21) & 0x02) return;
  
  /* Ignore key releases (high bit set) */
  if (sc & 0x80) return;
  
  if (sc > SC_MAX) return;
  
  if (sc == BACKSPACE) {
    if (buf_pos > 0) {
      buf_pos--;
      input_buf[buf_pos] = 0;
      cursor_pos--;
      putchar(' ');  /* erase */
      cursor_pos--;
      update_cursor();
    }
  }
  else if (sc == ENTER) {
    input_buf[buf_pos] = 0;
    execute(input_buf);
    buf_pos = 0;
    input_buf[0] = 0;
  }
  else {
    char c = sc_to_chr[sc];
    if (c != 0 && buf_pos < MAX_INPUT - 1) {
      input_buf[buf_pos++] = c;
      putchar(c);
    }
  }
}

/* kernel entrypoint */
void start_kernel() {
  clear_screen();
  printk("Welcome to DummyOS!\n");
  printk("Setting up IDT...\n");
  install_idt();   /* set up a bare IDT that defaults to hangs */
  printk("Setting up PIC...\n");
  remap_pic();
  printk("Initializing timer...\n");
  init_timer();
  printk("Initializing keyboard...\n");
  init_keyboard();
  printk("Enabling interrupts...\n");
  asm volatile("sti");    /* enable interrupts */
  printk("System ready! Type 'help' for commands.\n");
  prompt();
  while (1) asm volatile("hlt");
}