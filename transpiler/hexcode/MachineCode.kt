package hexcode

import java.io.File
import kotlin.math.max
import kotlin.system.exitProcess

val mnemonics = arrayOf(
    arrayOf("ADD", "SUB", "AND", "OR", "XOR", "NOR", "SLT", "SLTU"),
    arrayOf("ADDI", null, "ANDI", "ORI", "XORI", null, "SLTI", "SLTIU", "LUI"),
    arrayOf(null, null, null, null, null, null, null, null, null, "SLL", "SRL", "SRA", "SLLV", "SRLV", "SRAV"),
    arrayOf("LB", "LH", null, "LW", "LBU", "LHU"),
    arrayOf("SB", "SH", null, "SW"),
    arrayOf(null, "BGT", "BEQ", "BGE", "BLT", "BNE", "BGE", null),
    arrayOf("JR", "JALR"),
    arrayOf("HALT"),
    emptyArray(),
    arrayOf("J", "JAL"),
    emptyArray(),
    emptyArray(),
    arrayOf("CSR"),
    arrayOf("ERET"),
    emptyArray(),
    arrayOf("SYSCALL"),
)
val regs = arrayOf("zero", "at", "v0", "a0", "a1", "a2", "t0", "t1", "t2", "s0", "s1", "s2", "k0", "sp", "fp", "ra")

val ALUR = 0
val ALUI = 1 shl 28
val SHIFT = 2 shl 28
val LOAD = 3 shl 28
val STORE = 4 shl 28
val BRANCH = 5 shl 28
val JUMP_REG = 6 shl 28

val JUMP_IMM = 9 shl 28

val CSR = 0xC shl 28
val ERET = 0xD shl 28

val SYSCALL = 0xF shl 28

val regMap = arrayOf(
    0,
    1,
    2,
    null,
    3,
    4,
    5,
    null,
    6,
    7,
    8,
    null,
    null,
    null,
    null,
    null,
    9,
    10,
    11,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    12,
    null,
    null,
    13,
    14,
    15
)
val funcMap = arrayOf(
    9, -1, 10, 11, 12, -1, 13, 14, 0, 0, 6, 7, 2, 3, 4, 8, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 1, 1, 2, 3, 4, 5, -1, -1, 6, 7,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1
)

fun main(args: Array<String>) {
    var args = args
    if (args.isEmpty()) {
        println("Usage: convert.kts [file.obj] -o [output.hex]")
        exitProcess(1)
    }

    var target: String? = null
    var files: List<Pair<File, String>>? = null
    val flag = args.indexOfFirst { it == "-o" }
    if (flag > -1) {
        if (flag + 1 >= args.size) {
            println("Error: Missing output file name")
            exitProcess(1)
        }
        target = args[flag + 1]
        if (target.endsWith(".hex")) {
            target = target.removeSuffix(".hex")
            args = args.sliceArray(0 until flag) + args.sliceArray(flag + 2 until args.size)
            files = args.map { File(it) to "" }
        } else {
            println("Error: Output file must be a hex file (*.hex)")
            exitProcess(1)
        }
    }

    if (!args.all { it.endsWith(".obj") }) {
        println("Error: Input files must be object dump files (*.obj)")
        exitProcess(1)
    }

    files = files ?: args.map { File(it) to it.removeSuffix(".obj") }
    var fail = false
    for ((file, _) in files)
        if (!file.exists()) {
            println("Error: File '${file.path}' not found")
            fail = true
        }
    if (fail) exitProcess(1)

    if (target == null) files.forEach { (file, rootPath) -> transpile(rootPath, file) }
    else transpile(target, *files.map { it.first }.toTypedArray())
}

fun transpile(rootPath: String, vararg files: File) {
    var end = 0
    val lc4200 = HashMap<Int, Int>()
    for (inputFile in files) {
        var data = false
        lc4200.putAll(inputFile.readLines().mapNotNull {
            if (it == ".data") {
                data = true
                return@mapNotNull null
            }
            val s = it.split(":")
            val address = s[0].toInt(16)
            end = max(end, address)
            val hexcode = s[1].toUInt(16).toInt()
            address to if (data) hexcode else hexcode.transpile()
        }.associate { it.first to it.second })
    }
    val program = IntArray(end / 4) { lc4200[it * 4] ?: 0 }

    File("$rootPath.hex").writeText(program.joinToString("\n") { it.toUInt().toString(16).padStart(8, '0') })
    println("Generated machine code file @ $rootPath.hex")

    File("$rootPath.s").writeText(program.joinToString("\n") { it.disassemble() })
    println("Generated disassembly file @ $rootPath.s")
}

fun Int.disassemble(): String {
    if (this == 0) return "NOP"
    val opcode = (this shr 28) and 0xF
    val func = (this shr 24) and 0xF
    val rx = regs[(this shr 20) and 0xF]
    val ry = regs[(this shr 16) and 0xF]
    val rz = regs[(this shr 12) and 0xF]
    val imm16 = (this and 0xFFFF).toString(16)
    val immStr = if (imm16[0] == '-') "-0x${imm16.substring(1)}" else "0x$imm16"
    val shamt = this and 0x1F
    val addr = this and 0xFFFFFF
    val mnemonics = mnemonics[opcode]
    val mnemonic = mnemonics[func]?.padEnd(4, ' ')
    return when (opcode) {
        0 -> "$mnemonic $rx, $ry, $rz"
        1, 5 -> "$mnemonic $rx, $ry, $immStr"
        2 -> if (func < 4) "$mnemonic $rx, $ry, $shamt" else "$mnemonic $rx, $ry, $rz"
        3, 4 -> "$mnemonic $rx, $immStr($ry)"
        6 -> if (func < 8) "$mnemonic $addr" else "$mnemonic $rx, $ry"
        7, 8, 9, 12, 13, 15 -> "$mnemonic"
        else ->
            throw IllegalOpcodeException("$opcode")
    }
}

fun Int.transpile(): Int {
    if (this == 0) return 0
    val opcode = (this shr 26) and 0x3F
    val rs = (this shr 21) and 0x1F
    val rt = (this shr 16) and 0x1F
    val rd = (this shr 11) and 0x1F
    val shamt = (this shr 6) and 0x1F
    val funct = this and 0x3F
    val imm16 = this and 0xFFFF
    val func = funcMap[funct]
    val r1 = regMap[rs]
    val r2 = regMap[rt]
    val r3 = regMap[rd]
    return when (opcode) {
        0 -> when {
            funct < 8 -> SHIFT + (func shl 24) + (r3 shl 20) + (r2 shl 16) + (r1 shl 12) + shamt
            funct < 10 -> JUMP_REG + ((funct - 8) shl 24) + (r1 shl 20) + (r3 shl 16)
            funct == 12 -> SYSCALL
            else -> ALUR + (func shl 24) + (r3 shl 20) + (r1 shl 16) + (r2 shl 12)
        }

        1, 4, 5, 6, 7 -> {
            val less = opcode == 1 && rt and 1 == 0 || opcode == 5 || opcode == 6
            val equal = opcode == 1 && rt and 1 == 1 || opcode == 4 || opcode == 6
            val greater = opcode == 1 && rt and 1 == 1 || opcode == 5 || opcode == 7
            val op2 = (if (less) 4 else 0) + (if (equal) 2 else 0) + (if (greater) 1 else 0)
            BRANCH + (op2 shl 24) + (r1 shl 20) + (r2 shl 16) + imm16
        }

        2, 3 -> JUMP_IMM + ((opcode - 2) shl 24) + (this and 0xFFFFFF)
        8, 9, 10, 11, 12, 13, 14, 15 -> ALUI + (funcMap[opcode] shl 24) + (r2 shl 20) + (r1 shl 16) + imm16
        16 -> when (rs) {
            16 -> ERET
            4 -> CSR + (r3 shl 20) + (r2 shl 16)
            else -> throw IllegalOpcodeException("$opcode; $rs")
        }
        32, 33, 35, 36, 37 -> LOAD + ((opcode - 0x20) shl 24) + (r2 shl 20) + (r1 shl 16) + imm16
        40, 41, 43 -> STORE + ((opcode - 0x28) shl 24) + (r2 shl 20) + (r1 shl 16) + imm16
        else -> throw IllegalOpcodeException("$opcode")
    }

}

infix fun Int?.shl(x: Int) = this!! shl x

class IllegalOpcodeException(msg: String) : RuntimeException("Invalid opcode: $msg")