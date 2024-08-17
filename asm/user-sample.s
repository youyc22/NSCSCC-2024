.set noreorder
.set noat
.globl __start
.section .text
__start:
    lui $s0, 0x8050  # 数组A地址
    lui $s1, 0x8070
    lui $s2, 0x806f  # 结果目标地址
    ori $s2, $s2, 0xfffc
    ori $t0, $zero, 0  
loop:
    lw $t2, 0($s0)  
    addu $t0, $t0, $t2 # 用addu指令代表无符号求最大值
    beq $s0, $s1, end  
    addiu $s0, $s0, 4  
    j loop  
    nop
end:
    sw $t0, 4($s2)
    jr $ra
    nop