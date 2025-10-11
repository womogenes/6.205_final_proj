ENTRY(_start)

SECTIONS
{
  /* Start address for code */
  . = 0x00000000;

  /* Executable code */
  .text : {
    *(.text)
    *(.text.*)
  }

  /* Read-only data */
  .rodata : {
    *(.rodata)
    *(.rodata.*)
    *(.srodata)
    *(.srodata.*)
  }

  /* Initialized global and static variables */
  .data : {
    *(.data)
    *(.data.*)
    *(.sdata)
    *(.sdata.*)
  }

  /* Uninitialized global and static variables */
  .bss : {
    *(.bss)
    *(COMMON)
  }
}
