.set noreorder
.set noat
.globl __start
.section .text

__start:
    ori $s0, $zero, 0x20  # 被除数为32
    ori $s1, $zero, 0x9   # 除数为9
    ori $s2, $zero, 0x0   # 商
    ori $s3, $zero, 0x0   # 余数
    lui $s4, 0x8040  # A
    
    # 初始化二分查找的范围
    ori $t0, $zero, 0     # 左边界
    addu $t1, $zero, $s0   # 右边界 = 被除数
    
loop:
    slt $t2, $t0, $t1     # 如果左边界 < 右边界，$t2 = 1，否则 $t2 = 0
    beq $t2, $zero, end   # 如果左边界 >= 右边界，结束循环
    nop
    
    # 计算中间值 mid = (left + right) / 2
    addu $t3, $t0, $t1
    srl $t3, $t3, 1       # $t3 = mid
    
    # 计算 mid * 除数
    mul $t4, $t3, $s1
    
    # 比较 mid * 除数 和 被除数
    slt $t5, $s0, $t4     # 如果被除数 < mid * 除数，$t5 = 1，否则 $t5 = 0
    beq $t5, $zero, adjust_left
    nop
    
    # 如果 mid * 除数 > 被除数，调整右边界
    addi $t1, $t3, -1
    j loop
    nop
    
adjust_left:
    # 如果 mid * 除数 <= 被除数，调整左边界和商
    addi $t0, $t3, 1
    addu $s2, $zero, $t3   # 更新商
    j loop
    nop
    
end:
    # 计算余数
    mul $t6, $s2, $s1
    sub $s3, $s0, $t6
    sw $s3, 0($s4)
    jr $ra
    nop

    # 程序结束