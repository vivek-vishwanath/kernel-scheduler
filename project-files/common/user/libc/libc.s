    .section .text._start, "ax"
.globl _start

# This library is a runtime provided for user processes that essentially wraps them. When the scheduler picks a process to run,
# and calls eret, it routes to this _start label which acts as a wrapper for its respective user process.
# After returning from the `main` function of the user process, the process makes a syscall to terminate itself.
# This means a user process doesn't need to manually terminate and it has somewhere to go to after returning.

_start:
    jal main
    nop
    j sys_exit

sys_call:
    move $v0, $a0
    syscall
    jr $ra
    nop

sys_exit:
    li $a0, 10
    jal sys_call
    b .

# Note: Each user program is individually compiled and linked with a copy of this runtime, so each user process has a
# duplicate section of this code within its address space/memory region. In modern systems, these kinds of programs
# that are typically shared by multiple processes are known as shared libraries (*.so, *.dll, *.dylib) which means
# that it only exists in 1 place in memory with each process mapping to the same block of code. Due to the simplicity
# of our memory mechanisms, our system will duplicate this runtime for each user process.
