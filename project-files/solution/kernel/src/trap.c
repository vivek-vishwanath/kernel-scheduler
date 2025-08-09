#include "../include/proc.h"
#include "../include/syscall.h"

extern void swtch(struct context **old_sp, struct context *new_sp);

/**
 * Part 3A: Yield is a kernel function that transfers control of the CPU back to the scheduler on behalf of the user process.
 * Yield is invoked in the following situations:
 *  - Timer interrupt fires, requiring the kernel to force preempt the user process
 *  - User process finishes and makes a call to sys_exit
 *  - User makes a syscall that involves I/O
 */
void yield(void) {
    swtch(&(core.p->sp), core.sp);
    return;
}

/*
 * Part 3B: Force preempt is a function that gets called when a user process spends too much time on the CPU without yielding
 * so that other user processes get a chance to use the CPU (timesharing).
 */
void force_preempt(void) {
    struct proc *p = core.p;
    p->status = RUNNABLE;
    yield();
    return;
}

// Part 3C: When a user process voluntarily terminates,
// this kernel function performs the termination on behalf of the user.
void exit(void) {
    struct proc *p = core.p;
    p->status = EXITED;
    yield();
}

// Part 3D: When a user process performs a violation such as an invalid memory access,
// this kernel function performs the termination on behalf of the user.
void kill_handler(void) {
    struct proc *p = core.p;
    p->status = KILLED;
    yield();
}

/* Part 3E: In order to perform privileged operations such as accessing/manipulating hardware resources,
 * user processes need to hand control to the kernel and request it to perform the operation on its behalf.
 * This allows the kernel to regulate/mediate such privileged operations.
 *
 * When a user emits the `syscall` instruction (found in the ISA), the CPU will switch to kernel mode and
 * transfer control to the syscall_handler, which invokes this function.
 * `syscall_id` is the id number associated with the syscall.
 * Refer to include/syscall.h for which functions are associated with which syscalls.
 * If the syscall_id is invalid, then kill the process.
 * a1 and a2 are optional arguments for certain syscalls.
 */
void syscall(int syscall_id, int a1, int a2) {
    switch (syscall_id) {
        case SYS_EXIT:
            exit();
            break;
        default:
            kill_handler();
    }
}

