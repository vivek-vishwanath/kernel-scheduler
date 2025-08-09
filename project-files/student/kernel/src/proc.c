#include "../include/proc.h"

extern struct context *init_proc(void (*entry)(void), struct context *sp);
extern void swtch(struct context **old_sp, struct context *new_sp);

struct proc procs[NUM_PROC];
struct cpu core;

__attribute__((weak)) char __user1_start[1];
__attribute__((weak)) char __user1_mid[1];
__attribute__((weak)) char __user1_stack[1];
__attribute__((weak)) char __user1_end[1];

__attribute__((weak)) char __user2_start[1];
__attribute__((weak)) char __user2_mid[1];
__attribute__((weak)) char __user2_stack[1];
__attribute__((weak)) char __user2_end[1];

struct fence fences[NUM_PROC] = {
    {__user1_start, __user1_mid, __user1_stack, __user1_end},
    {__user2_start, __user2_mid, __user2_stack, __user2_end}
};

void init_processes() {
    for (int i = 0; i < NUM_PROC; i++) {
        int pid = i + 1;
        void (*entry)(void) = (void (*)(void)) fences[i].start;
        struct context *sp = (struct context *) fences[i].sp;
        sp = init_proc(entry, sp);
        struct proc *p = procs + i;
        p->fence = fences[i];
        p->pid = pid;
        p->sp = sp;
        p->status = RUNNABLE;
    }
}


/**
 * Part 1: Scheduler
 * During the boot sequence for the kernel, after all the system initialization, the final block of code to run is
 * the scheduler. Once the kernel enters the scheduler, it never leaves (unless the kernel panics/reboots).
 * The scheduler should do the following:
 *  1) Select a process (this depends on the scheduling algorithm, but we will use RR)
 *  2) Check if the process is runnable
 *  3) If not, then select a different process until you find one that is runnable
 *  4) Schedule that process onto the CPU
 *      - Update the current CPU's running process. (The current CPU is represent by the `core` variable declared at the top of this file.)
 *      - Perform a context switch by invoking the `swtch` function defined in `swtch.s`
 *          - Save the current kernel context onto the stack (all the registers)
 *          - Switch from the kernel stack to the selected process's stack
 *          - Restore the user context from the stack (all the registers)
 *          - Jump to the address of the user process
 *  5) Go back to step 1
 */
void scheduler(void) {

}

/**
 * Typically this function would be used to perform much of the kernel's initialization
 * However, due to the simplicity of our kernel, much of that logic is unnecessary and has been omitted.
 * Additionally, in standard operating systems, programs are dynamically loaded into memory during runtime
 * from a secondary storage (e.g. disk) to allow more flexibility. Due to limitations with our simulator,
 * we will pre-compile and bundle all user processes into a single image along with the kernel.
 */
void main() {
    init_processes();
    scheduler();
}