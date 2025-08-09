// A process can be in one of 6 statuses at any given time.
enum Status {
	EMBRYO, RUNNABLE, RUNNING, SLEEPING, KILLED, EXITED
};

struct context {
    int ra;
    int fp;
    int k0;
    int s2;
    int s1;
    int s0;
    int t2;
    int t1;
    int t0;
    int a2;
    int a1;
    int a0;
    int v0;
    int at;
};

// In order to provide memory protection and isolation between processes, we use fence registers that can be
// initialized using special instructions from our ISA. These fence registers separate the segments of a process:
// Text/Code segment, Read-only data Segment, Stack Segment, Global Data Segment (There is no heap segment)
struct fence {
    char *start;    // The lowest memory address that is accessible to its associated process.
    char *rw;               // The process's read/write boundary. Addresses less than this are read-only
    char *sp;     // The initial stack pointer for the associated process
    char *end;              // The lowest memory address that is inaccessible from its associated process.
};

// The primary struct to store a process's information (equivalent to PCB)
struct proc {
	int pid;                    // The process id (1, 2, 3, etc.)
	struct context *sp;         // The pointer to the top of this process's stack
	enum Status status;
	int start;                  // The entrypoint for the process
	struct fence fence;         // The fence registers for this process's memory region
};

struct cpu {
	struct context *sp;         // Context of the scheduler. Swtch() here to return to scheduler
	struct proc *p;		        // Currently running process on this cpu
};

#define NUM_PROC 2              // Since we know all the processes at build-time, we hardcode the # of processes here

// Define syscall codes here
#define SYS_EXIT 10

extern struct proc procs[NUM_PROC];     // The table of all processes that exist
extern struct cpu core;                 // The one and only CPU on which the processes run.
                                        // Hint: Use `core` to access the currently running process