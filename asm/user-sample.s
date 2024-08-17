.set noreorder
.set noat
.globl __start
.section .text
__start:
    lui $s0, 0x8040  # 数组A地址
    lui $s2, 0x8070  # 结果目标地址
    ori $t0, $zero, 0  # Initialize max value to 0
loop:
    lw $t2, 0($s0)  # Load value from array A
    addiu $s0, $s0, 4  # Increment array pointer by 4 bytes
    slt $t3, $t0, $t2  # Compare max and value (unsigned)
    bgtz $t3, update_max  # Branch if value is greater than max
    nop
    beq $s0, $s2, end  # Branch if loop counter is less than array length
    nop
    j loop  # Jump to loop
    nop
update_max:
    move $t0, $t2  # Update max value
    beq $s0, $s2, end  # Branch if loop counter is less than array length
    nop
    j loop  # Jump to loop
    nop
end:
    sw $t0, 0($s2)
    jr $ra
    nop