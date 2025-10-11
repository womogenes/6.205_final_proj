# 6.205 final project

## Memory

We want to have code on an SD card for ease of reprogramming.

### Flashing code onto SD card

On Unix you can do

```sh
sudo dd if=<binary.bin> of=/dev/sdX bs=512 seek=0
```

To get the value of `sdX`, use `lsblk`. For example, on my machine the SD card shows up under `/dev/sda`.

### SD card protocol

SD cards have an SPI mode available. Recall all transactions are most-significant bit first. Reference sheet: https://chlazza.nfshost.com/sdcardinfo.html

1. Commands are 48 bits wide, consisting of:
   - 1 byte: Command index (6 bits, sent as a byte `01xxxxxx`).
   - 4 bytes: Argument (4 bytes, 32 bits)
   - 1 byte: CRC7 checksum + end bit (always a `1`)

Initialization loop:

1. Card reset & idle. Send CMD0 (`0x40 00 00 00 00 95`). SD card returns `0x01` immediately after.
2. Interface check. Send CMD8 (`0x48 00 00 01 AA 87`). SD card returns some debug info we don't care about in 7 bytes.
3. Initialization loop. Send CMD55 and then CMD41, looping until we receive R1 (`0x00`).
   - CMD55 is `0x77 00 00 00 00 65` (not 100% sure about the `0x65`)
   - ACMD41 is `0x69 40 00 00 00 77` (again, not 100% usr)
4. Read data

## CPU

Lives in `hdl/cpu` and implements a minimal RISC-V processor.

### Tests

Tests live in `sim/cpu`. Decoder is `sim/cpu/test_decoder.py` and runs a bunch of instructions/verifies their outputs. Test cases are auto-generated and the code used to auto-generate them was written by an LLM. Execute state tests are in `/sim/cpu/test_execute.py` and operate similiarly.

### C code

Lives in `sw/` for now. Currently working on documenting the compilation process to go from C to RISC-V machine code runnable by the CPU. Simulator lives in `sim/cpu_picorv/test_cpu_picorv.py`.

There's a Makefile in `sw/Makefile` that:

1. Compiles `program.c` to `program.s` (assembly)
2. Assembles `program.s` to `program.o` (object file)
3. Turns `program.o` into `program.bin` (binary file, ready to be flashed)
4. Dumps `program.bin` into `program.hex` (hex dump)

You can run `make <program.s|program.o|program.o|program.hex>` to generate any file from all the steps above (unless you modify something in the middle, because `make` starts from the most recently changed file).
