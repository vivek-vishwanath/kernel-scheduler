ENTRY(_start)

SECTIONS {
  . = start;

  .text : {
    KEEP(*(.text._start))  /* Place _start first and prevent GC */
    *(.text*)              /* All other code */
  }


  .rodata : {
    *(.rodata*)
  }

  /* Stack allocation */
  .stack (NOLOAD) : {
    __stack_top = .;
    . = . + 0x100;
    __stack_bottom = .;
  }

  .data : {
    *(.data*)
  }

  .bss : {
    *(.bss*)
    *(COMMON)
  }

  .end : {
    . = . + 0x10;
  }

  /DISCARD/ : {
    *(.note.*)
    *(.MIPS.abiflags)
    *(.reginfo)
    *(.gnu.attributes)
  }
}