ENTRY(_start)
SECTIONS
{
  . = 0x0;
  .text : {
    KEEP(*(.text._start))  /* Place _start first and prevent GC */
    *(.text*)              /* All other code */
  }

  .rodata : {
    *(.rodata*)
  }

  .data : {
    *(.data*)
  }

  .bss : {
    *(.bss*)
    *(COMMON)
  }

  __user1_start = 0x0;
  __user2_start = 0x0;
  __user1_mid = 0x0;
  __user2_mid = 0x0;
  __user1_stack = 0x0;
  __user2_stack = 0x0;
  __user1_end = 0x0;
  __user2_end = 0x0;

  /DISCARD/ : {
    *(.note.*)
    *(.MIPS.abiflags)
    *(.reginfo)
    *(.gnu.attributes)
  }
}
