.globl swtch

# Part 2: `swtch` is a block of kernel code that performs a context switch from kernel to user and vice versa
# Swtch works using the following mechanism:
#   - Push all necessary registers onto the stack
#   - Switch stacks from the old context (user proc or kernel) to the new context (user proc or kernel)
#   - Pop all necessary registers off the stack
#   - Return (but not to caller)

swtch:
	addi $sp, $sp, -0x34
    sw   $v0, 0x30($sp)
    sw   $a0, 0x2C($sp)
    sw   $a1, 0x28($sp)
    sw   $a2, 0x24($sp)
    sw   $t0, 0x20($sp)
    sw   $t1, 0x1C($sp)
    sw   $t2, 0x18($sp)
    sw   $s0, 0x14($sp)
    sw   $s1, 0x10($sp)
    sw   $s2, 0xC($sp)
    sw   $k0, 8($sp)
    sw   $fp, 4($sp)
    sw   $ra, 0($sp)

	sw $sp, 0($a0)
	move $sp, $a1

	lw $ra, 0($sp)
	lw $fp, 4($sp)
	lw $k0, 8($sp)
	lw $s2, 0xC($sp)
	lw $s1, 0x10($sp)
	lw $s0, 0x14($sp)
	lw $t2, 0x18($sp)
	lw $t1, 0x1C($sp)
	lw $t0, 0x20($sp)
	lw $a2, 0x24($sp)
	lw $a1, 0x28($sp)
	lw $a0, 0x2C($sp)
	lw $v0, 0x30($sp)
	addi $sp, $sp, 0x34

	jr $ra
