.globl swtch

# Part 2: `swtch` is a block of kernel code that performs a context switch from kernel to user and vice versa
# Swtch works using the following mechanism:
#   - Push all necessary registers onto the stack
#   - Switch stacks from the old context (user proc or kernel) to the new context (user proc or kernel)
#   - Pop all necessary registers off the stack
#   - Return (but not to caller)

swtch:
    # [YOUR CODE GOES HERE]
