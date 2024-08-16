.set noreorder
.set noat
.globl __start
.section .text

__start:
    lui $s0, 0x3
    ori $s0, $zero, 0x1112  # 假设我们要计算这个数的二进制1的个数
    ori $s1, $zero, 0       # 用于存储1的个数
    ori $s2, $zero, 0x1     # 用于循环计数
    ori $s3, $zero, 0x0     # 用于存储临时值
    
loop_1: 
    beq $s2, $s0, end
    nop
    addu $s3, $s2, $zero
    addi $s2, $s2, 1

loop_2:
    beq $s3, $zero, loop_1     # 如果数字变为0，结束循环
    nop
    addi $s1, $s1, 1        # 计数器加1
    subu $t0, $s3, 1        # n-1
    and $s3, $s3, $t0       # n = n & (n-1)
    j loop_2
    nop
end:
    jr $ra
    ori $zero, $zero, 0