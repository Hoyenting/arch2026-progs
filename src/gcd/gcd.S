    .text
    .balign 4
    .globl gcd_u32_asm
    .type gcd_u32_asm, @function
gcd_u32_asm:
    beqz a0, .Lreturn_b
    beqz a1, .Lreturn
    li t0, 0
    li t3, 1

    # Remove twos shared by both numbers.
.Lshared_twos:
    or t1, a0, a1
    andi t1, t1, 1
    bnez t1, .Lmake_a_odd
    srli a0, a0, 1
    srli a1, a1, 1
    addi t0, t0, 1
    j .Lshared_twos

.Lmake_a_odd:
    andi t1, a0, 1
    bnez t1, .Lmake_b_odd
.Lshift_a:
    srli a0, a0, 1
    andi t1, a0, 1
    beqz t1, .Lshift_a

    # b is nonzero here. Keep a odd and remove all twos from b.
.Lmake_b_odd:
    andi t1, a1, 1
    bnez t1, .Lorder
.Lshift_b:
    srli a1, a1, 1
    andi t1, a1, 1
    beqz t1, .Lshift_b

.Lorder:
    bgeu a1, a0, .Lsubtract
    mv t2, a0
    mv a0, a1
    mv a1, t2
.Lsubtract:
    # a is the smaller odd number. If it is 1, the remaining GCD is 1.
    beq a0, t3, .Lrestore_twos
    sub a1, a1, a0
    # An odd minus an odd is even: start with the shift, not another test.
    bnez a1, .Lshift_b
.Lrestore_twos:
    sll a0, a0, t0
.Lreturn:
    ret
.Lreturn_b:
    mv a0, a1
    ret
    .size gcd_u32_asm, .-gcd_u32_asm
    .section .note.GNU-stack,"",@progbits
