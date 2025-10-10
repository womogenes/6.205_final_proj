int main() {
  int x = 0x100;
  int y = 0x200;
  int z = x + y;
  
  return 1;
}

// Compile with:
/*
  riscv64-elf-gcc -nostdlib -march=rv32i -mabi=ilp32 -O2 -S program.c -o program.s
  riscv64-elf-gcc -nostdlib -march=rv32i -mabi=ilp32 -O2 -c program.s -o program.o
  riscv64-elf-objcopy -O binary program.o program.bin
*/
