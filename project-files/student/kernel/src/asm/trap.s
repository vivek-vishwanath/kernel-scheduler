.globl int_handler
.globl syscall_handler
.globl trap

syscall_handler:
    addi $sp, $sp, -4
    sw $k0, 0($sp)
    jal syscall
    lw $k0, 0($sp)
    addi $sp, $sp, 4
    b trap

int_handler:
    addi $sp, $sp, -0x34
    sw $k0, 0x30($sp)
    sw $v0, 0x2C($sp)
    sw $a0, 0x28($sp)
    sw $a1, 0x24($sp)
    sw $a2, 0x20($sp)
    sw $t0, 0x1C($sp)
    sw $t1, 0x18($sp)
    sw $t2, 0x14($sp)
    sw $s0, 0x10($sp)
    sw $s1, 0xC($sp)
    sw $s2, 8($sp)
    sw $fp, 4($sp)
    sw $ra, 0($sp)
    jal force_preempt
    lw $ra, 0($sp)
    lw $fp, 4($sp)
    lw $s2, 8($sp)
    lw $s1, 0xC($sp)
    lw $s0, 0x10($sp)
    lw $t2, 0x14($sp)
    lw $t1, 0x18($sp)
    lw $t0, 0x1C($sp)
    lw $a2, 0x20($sp)
    lw $a1, 0x24($sp)
    lw $a0, 0x28($sp)
    lw $v0, 0x2C($sp)
    lw $k0, 0x30($sp)
    addi $sp, $sp, 0x34

trap:
    addi $sp, $sp, -8
    sw $s0, 4($sp)
    sw $s1, 0($sp)
    la $s0, core
    lw $s0, 4($s0)
    lw $s1, 16($s0)
    mtc0 $s1, $0
    lw $s1, 20($s0)
    mtc0 $s1, $1
    lw $s1, 24($s0)
    mtc0 $s1, $2
    lw $s0, 0($sp)
    lw $s0, 4($sp)
    addi $sp, $sp, 8
    eret
