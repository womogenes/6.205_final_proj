ENTRY(_start)

SECTIONS
{
  /* Start address for code */
  . = 0x00000000;

  /* Executable code */
  .text : {
    *(.text)
  }

  /* Initialized global and static variables */
  .data : {
    *(.data)
  }

  /* Uninitialized global and static variables */
  .bss : {
    *(.bss)
    *(COMMON)
  }
}
