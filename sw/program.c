// Must include relevant typedefs for compatability
typedef unsigned int uint32_t;
typedef unsigned short uint16_t;
typedef unsigned char uint8_t;
typedef int int32_t;

volatile uint32_t* const fb_ptr = (volatile uint32_t*) 0x40000000;

void _start() {
  int x = 0x200;
  int y = 0x200;
  int z = x + y;

  *fb_ptr = z;

  __asm__ volatile ("ecall");
}

// Compile with:
/*
  riscv64-elf-gcc -nostdlib -march=rv32i -mabi=ilp32 -O2 -S program.c -o program.s
  riscv64-elf-gcc -nostdlib -march=rv32i -mabi=ilp32 -O2 -c program.s -o program.o
  riscv64-elf-objcopy -O binary program.o program.bin
*/
