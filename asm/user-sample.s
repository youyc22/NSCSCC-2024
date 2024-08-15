.set noreorder
.set noat
.globl __start
.section text

__start:
.text
lui $s0, 0x8040  # A
lui $s1, 0x8050  # B
lui $s2, 0x8060  # C
# 数组长度为0x40000
ori $s3, $zero, 0x40000
ori $s4, $zero, 0x0

loop:
beq $s4, $s3, end
ori $zero, $zero, 0
ori $t3, $zero, 0x0
addiu $s4, $s4, 1
lw $t0, 0($s0)  # A[i]
lw $t1, 0($s1)  # B[i]

loop_mod:
addu $t3, $t3, $t1
subu $t2, $t0, $t3
bltz $t2, loop_mod_end
ori $zero, $zero, 0
j loop_mod
ori $zero, $zero, 0

loop_mod_end:
addu $t2, $t2, $t1
sw $t2, 0($s2)  # C[i]
addiu $s0, $s0, 4
addiu $s1, $s1, 4
addiu $s2, $s2, 4
j loop
ori $zero, $zero, 0

end:
jr $ra
ori $zero, $zero, 0