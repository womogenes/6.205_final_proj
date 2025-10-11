program.s: program.c
# Compile to assembly (program.s)
	riscv64-elf-gcc -nostdlib -march=rv32i -mabi=ilp32 -O3 -S program.c -o program.s

program.o: program.s
# Compile to object file (program.o)
# TODO: add linker for robustness?
	riscv64-elf-gcc -nostdlib -march=rv32i -mabi=ilp32 -O3 -c program.s -o program.o

program.elf: program.o link.ld
# Link object file to ELF using linker script link.ld
	riscv64-elf-gcc -nostdlib -march=rv32i -mabi=ilp32 -T link.ld program.o -o program.elf

# Compile to machine code
program.bin: program.elf
	riscv64-elf-objcopy -O binary program.elf program.bin

# Dump machine code to hex
# 1/4 means 1 element of 4 bytes, zero-padded, on each line
program.mem: program.bin
	hexdump -v -e '1/1 "%02x\n"' program.bin > program.mem
