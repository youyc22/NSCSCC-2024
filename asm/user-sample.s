.set noreorder
.set noat
.globl __start
.section .text
__start:
    lui $s0, 0x8040  # 数组A地址
    lui $s2, 0x8070  # 结果目标地址
    ori $t0, $zero, 0  
loop:
    lw $t2, 0($s0)  
    addiu $s0, $s0, 4  
    addu $t0, $t0, $t2 # 用addu指令代表无符号求最大值
    beq $s0, $s2, end  
    nop
    j loop  
    nop
end:
    sw $t0, 0($s2)
    jr $ra
    nop