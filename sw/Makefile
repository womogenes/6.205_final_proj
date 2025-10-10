program:
# Compile to assembly
	riscv64-elf-gcc -nostdlib -march=rv32i -mabi=ilp32 -O0 -S program.c -o program.s

# Compile to object file
# TODO: add linker for memory mapping
	riscv64-elf-gcc -nostdlib -march=rv32i -mabi=ilp32 -O0 -c program.s -o program.o

# Compile to machine code
	riscv64-elf-objcopy -O binary program.o program.bin

# Dump machine code to hex
# 1/4 means 1 element of 4 bytes, zero-padded, on each line
	hexdump -v -e '1/4 "%08x\n"' program.bin > program.hex
