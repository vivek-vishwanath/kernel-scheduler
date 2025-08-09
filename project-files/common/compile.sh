#!/usr/bin/env bash

set -e

# Common variables
CC="mipsel-linux-gnu-gcc"
READELF="mipsel-linux-gnu-readelf"
OBJDUMP="mipsel-linux-gnu-objdump"
NM="mipsel-linux-gnu-nm"

# Common compiler flags
COMMON_FLAGS=(
    -nostdlib -nostartfiles -nodefaultlibs
    -march=mips3 -mfp32 -mno-abicalls -mno-mips16 -mno-long-calls
    -fno-builtin -fno-pic -fno-schedule-insns -fno-schedule-insns2 -fno-delayed-branch
    -fno-inline -fno-inline-functions -fno-inline-small-functions -fno-default-inline
    -ffixed-{v1,a3,t3,t4,t5,t6,t7,s3,s4,s5,s6,s7,t8,t9}
    "-Wl,--build-id=none"
    -O2
)

get_end_addr() {
    local elf_file="$1"
    $READELF -S "$elf_file" | awk '
        $0 ~ /\[ *[0-9]+\]/ && ($0 ~ "  WA" || $0 ~ "  AX" || $0 ~ "   A") && strtonum("0x" $5) > 0 {
            addr = strtonum("0x" $5); size = strtonum("0x" $7); end = addr + size;
            if (end > max) max = end
        } END { printf "0x%x\n", max }'
}

get_section_addr() {
    local elf_file="$1" section="$2"
    $READELF -S "$elf_file" | awk -v sec="$section" '
        $0 ~ /\[ *[0-9]+\]/ && $3 == sec { printf "0x%x\n", strtonum("0x" $5) }'
}

get_section_end() {
    local elf_file="$1" section="$2"
    $READELF -S "$elf_file" | awk -v sec="$section" '
        $0 ~ /\[ *[0-9]+\]/ && $3 == sec {
            addr = strtonum("0x" $5); size = strtonum("0x" $7);
            printf "0x%x\n", addr + size
        }'
}

get_symbol_addr() {
    local elf_file="$1" symbol="$2"
    $NM "$elf_file" | awk -v sym="$symbol" '$3 == sym { print $1 }'
}

gen_obj_dump() {
    local elf_file="$1" obj_file="$2"
    local hex_pattern='^[[:space:]]*[0-9a-fA-F]+:[[:space:]]*[0-9a-fA-F]+'
    local sed_pattern='s/^[[:space:]]*([0-9a-fA-F]+):[[:space:]]*([0-9a-fA-F]+).*/\1:\2/'

    # Extract .text section
    $OBJDUMP -D "$elf_file" -j .text | grep -E "$hex_pattern" | sed -E "$sed_pattern" > "$obj_file"

    # Add .data marker and extract .data/.rodata sections (silence missing section warnings)
    echo ".data" >> "$obj_file"
    $OBJDUMP -D "$elf_file" -j .data .rodata 2>/dev/null | grep -E "$hex_pattern" | sed -E "$sed_pattern" >> "$obj_file"
}

# Initialize associative arrays for user program data
declare -A USER_STARTS=()
declare -A USER_MIDS=()
declare -A USER_STACKS=()
declare -A USER_ENDS=()
declare -A USER_OBJS=()

# Define user programs: (source_file)
USER_PROGRAMS=(
    "pow.c"
    "factorial.c"
)

# Build kernel
$CC "${COMMON_FLAGS[@]}" -T linkers/kernel.ld -o build/kernel.elf kernel/src/*.c kernel/include/*.h kernel/src/asm/*.s
gen_obj_dump build/kernel.elf build/kernel.obj

# Build user programs
next_start=$(get_end_addr build/kernel.elf)
for i in "${!USER_PROGRAMS[@]}"; do
    user_num=$((i + 1))

    elf_file="build/user${user_num}.elf"
    obj_file="build/user${user_num}.obj"

    # Build user program
    $CC "${COMMON_FLAGS[@]}" -T linkers/user.ld -Wl,--defsym=start="$next_start" \
        -o "$elf_file" "user/src/${USER_PROGRAMS[i]}" user/libc/*

    # Extract addresses
    mid_addr=$(get_section_addr "$elf_file" ".stack")
    stack_addr=$(get_symbol_addr "$elf_file" "__stack_bottom")
    end_addr=$(get_section_end "$elf_file" ".end")

    # Generate object dump
    gen_obj_dump "$elf_file" "$obj_file"

    # Store addresses in global arrays
    USER_STARTS[$user_num]="$next_start"
    USER_MIDS[$user_num]="$mid_addr"
    USER_STACKS[$user_num]="$stack_addr"
    USER_ENDS[$user_num]="$end_addr"
    USER_OBJS[$user_num]="$obj_file"

    # Update next_start for next iteration
    next_start="$end_addr"
done

# Print all array elements in order
echo "============================== User Program Segments ===================================="
for i in "${!USER_PROGRAMS[@]}"; do
    user_num=$((i + 1))
    echo "USER${user_num}: START=${USER_STARTS[$user_num]} MID=${USER_MIDS[$user_num]} STACK=${USER_STACKS[$user_num]} END=${USER_ENDS[$user_num]} OBJ=${USER_OBJS[$user_num]}"
done
echo "========================================================================================"

# Generate final linker script with dynamic user program symbols
linker_symbols=""
for user_num in "${!USER_STARTS[@]}"; do
    linker_symbols+="
  __user${user_num}_start = ${USER_STARTS[$user_num]};
  __user${user_num}_mid = ${USER_MIDS[$user_num]};
  __user${user_num}_stack = 0x${USER_STACKS[$user_num]};
  __user${user_num}_end = ${USER_ENDS[$user_num]};"
done

cat > linkers/final.ld <<EOF
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
${linker_symbols}

  /DISCARD/ : {
    *(.note.*) *(.MIPS.abiflags) *(.reginfo) *(.gnu.attributes)
  }
}
EOF

# Build final executable
$CC "${COMMON_FLAGS[@]}" -T linkers/final.ld -o build/final.elf \
    kernel/src/*.c kernel/include/*.h kernel/src/asm/*.s

# Generate final object dump and run transpiler with all user object files
gen_obj_dump build/final.elf build/final.obj

# Build transpiler arguments dynamically
transpiler_args="build/final.obj"
for user_num in "${!USER_OBJS[@]}"; do
    transpiler_args+=" ${USER_OBJS[$user_num]}"
done

java -jar transpiler.jar $transpiler_args -o build/img.hex