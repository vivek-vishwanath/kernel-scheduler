ENTRY(_start)
SECTIONS
{
  . = 0x0;
  .text : {
    KEEP(*(.text._start))
    *(.text*)
  }

  .rodata : { *(.rodata*) }
  .data : { *(.data*) }
  .bss : { *(.bss*) }

  __user2_start = 0xac0;
  __user2_mid = 0xbe0;
  __user2_stack = 0x00000ce0;
  __user2_end = 0xcf0;
  __user1_start = 0x860;
  __user1_mid = 0x9b0;
  __user1_stack = 0x00000ab0;
  __user1_end = 0xac0;

  /DISCARD/ : {
    *(.note.*) *(.MIPS.abiflags) *(.reginfo) *(.gnu.attributes)
  }
}
