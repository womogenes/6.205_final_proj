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
