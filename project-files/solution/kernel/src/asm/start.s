# crt0.S
.section .text._start
.globl _start
.globl init_proc

# Entrypoint that boots up the kernel before jumping to scheduler
# Does the following:
#  1) Initializes the Kernel Stack
#  2) Initializes the IVT & device handlers
#  3) Jumps to the scheduler (never to return)
_start:
    la $sp, BOTTOM_KERNEL_STACK

    la $t0, IVT

    la $t1, int_handler
    sw $t1, 0($t0)

    la $t1, syscall_handler
    sw $t1, 4($t0)

    j main
    nop


# Initializes a process's stack and entrypoint
init_proc:
    la $t0, trap

    # Push 0s for most general purpose registers
	addi $v0, $a1, -0x34
    sw   $zero, 0x30($v0)
    sw   $zero, 0x2C($v0)
    sw   $zero, 0x28($v0)
    sw   $zero, 0x24($v0)
    sw   $zero, 0x20($v0)
    sw   $zero, 0x1C($v0)
    sw   $zero, 0x18($v0)
    sw   $zero, 0x14($v0)
    sw   $zero, 0x10($v0)
    sw   $zero, 0xC($v0)

    # Push the entrypoint onto the user stack in place of $k0,
    # so during the trap handler when this value gets popped into $k0,
    # and eret is called, it will jump to the entrypoint for this process.
    sw $a0, 8($v0)

    sw   $fp, 4($v0)

    # Push the address for the trap handler onto the user stack in place of $ra,
    # so during swtch when this value gets popped into $ra, and `jr $ra` is called,
    # it will jump to the trap handler.
    sw $t0, 0($v0)

    jr $ra

.section .bss
# Here, we allocate 16 bytes for the Interrupt Vector Table and 1024 bytes for the kernel stack
IVT: .space 0x10

.space 0x400
BOTTOM_KERNEL_STACK:

