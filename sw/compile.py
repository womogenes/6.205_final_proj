"""
compile.py

Script to compile a C file.
Inputs:
    - <program>.c OR <program>.s        C or assembly code
    - link.ld                           linker script

Outputs:
    - <program>.bin                     bitfile to be flashed
    - <program>.s (if given C file)     compiled
    - <program>.o                       object file
    - <program>.mem                     memory dump (lines of 8 hex values)
"""

import os
import sys
import shutil
import subprocess

from pathlib import Path

def compile(
        prog_path: Path,
        link_path: str = None,
        flags = "-O0"
    ):
    """
    Compile C program with given linker file to RISC-V-core-executable binary
    """
    prog_path = Path(prog_path).absolute()

    if link_path is None:
        # Assume in same directory
        link_path = prog_path.parent.parent / "link.ld"

    # Check that program and linker exist
    if not prog_path.exists():
        raise FileNotFoundError(f"Program '{prog_path}' does not exist")
    if not link_path.exists():
        raise FileNotFoundError(f"Linker file link.ld not found in {prog_path.parent.parent}")

    # Stem (e.g. `program` in `program.c`)
    stem = prog_path.stem

    os.chdir(prog_path.parent)

    if str(prog_path).endswith(".c"):
        print(f"Compiling {stem}.c to {stem}.s...")
        subprocess.run([f"riscv64-elf-gcc -ffreestanding -march=rv32i -mabi=ilp32 {flags} -S {stem}.c -o {stem}.s"], shell=True)

    print(f"Assembling {stem}.s to {stem}.o...")
    subprocess.run([f"riscv64-elf-gcc -ffreestanding -march=rv32i -mabi=ilp32 {flags} -c {stem}.s -o {stem}.o"], shell=True)

    print(f"Linking {stem}.elf from {stem}.s...")
    subprocess.run([f"riscv64-elf-gcc -nostdlib -march=rv32i -mabi=ilp32 -T {link_path} {stem}.o -lc -lgcc -o {stem}.elf"], shell=True)

    print(f"Exporting to binaries {stem}.bin and {stem}.mem...")
    subprocess.run([f"riscv64-elf-objcopy -O binary {stem}.elf {stem}.bin"], shell=True)
    subprocess.run([f"""hexdump -v -e '1/4 "%08x\n"' {stem}.bin > {stem}.mem"""], shell=True)

    print(f"Cleaning up...")
    subprocess.run([f"rm *.o *.elf"], shell=True)

    bin_path = Path(stem + ".bin").absolute()
    hex_path = Path(stem + ".mem").absolute()
    print(f"""Done.
        Binary at:  {bin_path}
        Hexdump at: {hex_path}""")
    
    return bin_path, hex_path


if __name__ == "__main__":
    # Usage: compile.py <program.py>

    if len(sys.argv) < 2:
        print(f"Usage: compile.py <program> <flags>")

    prog_path = Path(sys.argv[1])

    flags = sys.argv[2] if len(sys.argv) >= 3 else "-O0"
    compile(prog_path, flags=flags)
