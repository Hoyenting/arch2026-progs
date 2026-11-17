    .text
    .balign 4
    .globl rubik_solve_asm
    .type rubik_solve_asm, @function
rubik_solve_asm:
    addi sp, sp, -80
    sw ra, 16(sp)
    sw s0, 20(sp)
    sw s1, 24(sp)
    sw s2, 28(sp)
    sw s3, 32(sp)
    sw s4, 36(sp)
    sw s5, 40(sp)
    sw s6, 44(sp)
    sw s7, 48(sp)
    sw s8, 52(sp)
    sw s9, 56(sp)
    sw s10, 60(sp)
    sw s11, 64(sp)
    mv s4, a0                    # input
    mv s5, a1                    # output, untouched until validation ends
    mv s6, a2                    # capacity

    li t0, 0                     # permutation character index
    li t1, 0                     # seen bit mask
.Lvalidate_perm:
    add t2, s4, t0
    lbu t2, 0(t2)
    addi t2, t2, -49
    li t3, 6
    bltu t3, t2, .Linvalid
    li t3, 1
    sll t3, t3, t2
    and t4, t1, t3
    bnez t4, .Linvalid
    or t1, t1, t3
    addi t0, t0, 1
    li t3, 7
    bltu t0, t3, .Lvalidate_perm

    li s8, 0                     # orientation rank
    li t1, 0                     # twist sum modulo three
.Lvalidate_ori:
    add t2, s4, t0
    lbu t2, 0(t2)
    addi t2, t2, -49
    li t3, 2
    bltu t3, t2, .Linvalid
    add t1, t1, t2
    li t3, 3
    bltu t1, t3, .Lsum_ready
    addi t1, t1, -3
.Lsum_ready:
    li t3, 13
    beq t0, t3, .Lori_rank_ready
    slli t3, s8, 1
    add s8, s8, t3
    add s8, s8, t2
.Lori_rank_ready:
    addi t0, t0, 1
    li t3, 14
    bltu t0, t3, .Lvalidate_ori
    bnez t1, .Linvalid
    lbu t1, 14(s4)
    bnez t1, .Linvalid
    beqz s6, .Lno_capacity

    li s7, 0                     # permutation rank
    li t0, 0
.Lrank_outer:
    add t2, s4, t0
    lbu t2, 0(t2)
    li t3, 0                     # number of smaller following digits
    addi t1, t0, 1
.Lrank_inner:
    li t4, 7
    bgeu t1, t4, .Lrank_accumulate
    add t4, s4, t1
    lbu t4, 0(t4)
    sltu t4, t4, t2
    add t3, t3, t4
    addi t1, t1, 1
    j .Lrank_inner
.Lrank_accumulate:
    li t4, 7
    sub t4, t4, t0               # factor 7-i: repeated addition, no M helper
    li t5, 0
.Lrank_multiply:
    add t5, t5, s7
    addi t4, t4, -1
    bnez t4, .Lrank_multiply
    add s7, t5, t3
    addi t0, t0, 1
    li t4, 7
    bltu t0, t4, .Lrank_outer

    la s0, .Lperm_dist
    la s1, .Lori_dist
    la s2, .Lperm_move
    la s3, .Lori_move
    add t0, s0, s7
    lbu s9, 0(t0)
    add t0, s1, s8
    lbu t0, 0(t0)
    bgeu s9, t0, .Lbound_ready
    mv s9, t0
.Lbound_ready:
    # The exact-distance-11 subset skips all unsuccessful shallower rounds.
    slli t0, s7, 9
    slli t1, s7, 7
    add t0, t0, t1
    slli t1, s7, 6
    add t0, t0, t1
    slli t1, s7, 4
    add t0, t0, t1
    slli t1, s7, 3
    add t0, t0, t1
    add t0, t0, s7
    add t0, t0, s8
    la t6, .Ldistance11
    li t1, 0
    li t2, 2644
.Ldistance_lookup:
    bgeu t1, t2, .Ldistance_done
    add t3, t1, t2
    srli t3, t3, 1
    slli t4, t3, 2
    add t4, t6, t4
    lw t4, 0(t4)
    beq t0, t4, .Ldistance_found
    bltu t0, t4, .Ldistance_lower
    addi t1, t3, 1
    j .Ldistance_lookup
.Ldistance_lower:
    mv t2, t3
    j .Ldistance_lookup
.Ldistance_found:
    li s9, 11
.Ldistance_done:
    mv s10, sp                   # path[11] in entry frame
    or t0, s7, s8
    beqz t0, .Lformat            # solved, length zero
.Ldeepen:
    mv a0, s7
    mv a1, s8
    mv a2, s9
    li a3, 9                     # no previous face: skip no move group
    mv a4, s10
    call .Lsearch
    bnez a0, .Lformat
    addi s9, s9, 1
    li t0, 11
    bgeu t0, s9, .Ldeepen
    j .Linvalid                  # unreachable for a valid cube

.Lformat:
    la t6, .Lmove_text
    li t0, 0
    li t1, 1                     # bytes needed, including NUL
.Lsize_loop:
    bgeu t0, s9, .Lsize_ready
    add t2, s10, t0
    lbu t2, 0(t2)
    slli t3, t2, 1
    add t2, t2, t3
    add t2, t6, t2               # move_text[move]
    lbu t2, 1(t2)
    snez t2, t2
    add t1, t1, t2               # optional suffix
    snez t2, t0
    add t1, t1, t2               # optional separating space
    addi t1, t1, 1               # face letter
    addi t0, t0, 1
    j .Lsize_loop
.Lsize_ready:
    bltu s6, t1, .Ltoo_small
    li t0, 0
    mv t1, s5                    # output cursor
.Lwrite_loop:
    bgeu t0, s9, .Lwrite_end
    beqz t0, .Lwrite_move
    li t2, 32
    sb t2, 0(t1)
    addi t1, t1, 1
.Lwrite_move:
    add t2, s10, t0
    lbu t2, 0(t2)
    slli t3, t2, 1
    add t2, t2, t3
    add t2, t6, t2
    lbu t3, 0(t2)
    sb t3, 0(t1)
    addi t1, t1, 1
    lbu t3, 1(t2)
    beqz t3, .Lnext_output
    sb t3, 0(t1)
    addi t1, t1, 1
.Lnext_output:
    addi t0, t0, 1
    j .Lwrite_loop
.Lwrite_end:
    sb zero, 0(t1)
    mv a0, s9
    j .Lreturn
.Ltoo_small:
    sb zero, 0(s5)
.Lno_capacity:
    li a0, -2
    j .Lreturn
.Linvalid:
    li a0, -1
.Lreturn:
    lw ra, 16(sp)
    lw s0, 20(sp)
    lw s1, 24(sp)
    lw s2, 28(sp)
    lw s3, 32(sp)
    lw s4, 36(sp)
    lw s5, 40(sp)
    lw s6, 44(sp)
    lw s7, 48(sp)
    lw s8, 52(sp)
    lw s9, 56(sp)
    lw s10, 60(sp)
    lw s11, 64(sp)
    addi sp, sp, 80
    ret
    .size rubik_solve_asm, .-rubik_solve_asm

    .balign 4
    .type .Lsearch, @function
.Lsearch:
    li t0, 5
    bgeu t0, a2, .Ltail_lookup
    addi sp, sp, -48
    sw ra, 0(sp)
    sw s4, 4(sp)
    sw s5, 8(sp)
    sw s6, 12(sp)
    sw s7, 16(sp)
    sw s8, 20(sp)
    sw s9, 24(sp)
    sw s10, 28(sp)
    sw s11, 32(sp)
    slli t0, a0, 2
    slli t1, a0, 1
    add t0, t0, t1
    add s4, s2, t0               # permutation row: rank*6, quarter turns only
    mv s10, s4                  # current repeated quarter-turn row
    li s11, 3                   # next face boundary
    slli t0, a1, 4
    slli t1, a1, 1
    add t0, t0, t1
    add s5, s3, t0               # orientation row: rank*18, all nine moves
    mv s6, a2
    mv s7, a3
    li s8, 0
    mv s9, a4
.Lchild:
    beq s8, s7, .Lskip_face
    li t0, 9
    bgeu s8, t0, .Lnot_found
    la t0, .Lperm_offset
    add t0, t0, s8
    lbu t0, 0(t0)
    add t1, s10, t0
    lhu a0, 0(t1)
    slli t1, a0, 2
    slli t2, a0, 1
    add t1, t1, t2
    add s10, s2, t1             # another quarter turn gives half/inverse
    slli t0, s8, 1
    add t1, s5, t0
    lhu a1, 0(t1)
    or t0, a0, a1
    beqz t0, .Lgoal_child
    add t0, s0, a0
    lbu t0, 0(t0)
    bgeu t0, s6, .Lnext_child    # child distance > remaining-1
    add t0, s1, a1
    lbu t0, 0(t0)
    bgeu t0, s6, .Lnext_child
    sb s8, 0(s9)
    addi a2, s6, -1
    la t0, .Lface_group
    add t0, t0, s8
    lbu a3, 0(t0)
    addi a4, s9, 1
    call .Lsearch
    bnez a0, .Lsearch_return
.Lnext_child:
    addi s8, s8, 1
    bne s8, s11, .Lchild
    mv s10, s4
    addi s11, s11, 3
    j .Lchild
.Lskip_face:
    addi s8, s8, 3
    addi s11, s11, 3
    j .Lchild
.Lgoal_child:
    sb s8, 0(s9)
    li a0, 1
    j .Lsearch_return
.Lnot_found:
    li a0, 0
.Lsearch_return:
    lw ra, 0(sp)
    lw s4, 4(sp)
    lw s5, 8(sp)
    lw s6, 12(sp)
    lw s7, 16(sp)
    lw s8, 20(sp)
    lw s9, 24(sp)
    lw s10, 28(sp)
    lw s11, 32(sp)
    addi sp, sp, 48
    ret
    .size .Lsearch, .-.Lsearch


.Ltail_lookup:
    or t0, a0, a1
    beqz t0, .Ltail_success
    slli t0, a0, 9
    slli t1, a0, 7
    add t0, t0, t1
    slli t1, a0, 6
    add t0, t0, t1
    slli t1, a0, 4
    add t0, t0, t1
    slli t1, a0, 3
    add t0, t0, t1
    add t0, t0, a0
    add t0, t0, a1               # combined rank
    li t1, 0
    li t2, 12224
    la t5, .Ltail_rank
.Ltail_binary:
    bgeu t1, t2, .Ltail_failure
    add t3, t1, t2
    srli t3, t3, 1
    slli t4, t3, 2
    add t4, t5, t4
    lw t4, 0(t4)
    srli t6, t4, 7              # high bits: combined state rank
    beq t0, t6, .Ltail_hit
    bltu t0, t6, .Ltail_lower
    addi t1, t3, 1
    j .Ltail_binary
.Ltail_lower:
    mv t2, t3
    j .Ltail_binary
.Ltail_hit:
    srli t0, t4, 4
    andi t0, t0, 7              # bits 4..6: exact distance
    bltu a2, t0, .Ltail_failure
    andi t0, t4, 15             # bits 0..3: one move toward solved
    sb t0, 0(a4)
    addi a4, a4, 1
    addi a2, a2, -1
    la t1, .Lperm_offset
    add t1, t1, t0
    lbu t1, 0(t1)               # face offset in a three-quarter-turn row
    la t2, .Lturn_count
    add t2, t2, t0
    lbu t2, 0(t2)
.Ltail_perm_turn:
    slli t3, a0, 2
    slli t4, a0, 1
    add t3, t3, t4
    add t3, s2, t3
    add t3, t3, t1
    lhu a0, 0(t3)
    addi t2, t2, -1
    bnez t2, .Ltail_perm_turn
    slli t0, t0, 1             # orientation table still has direct nine moves
    slli t1, a1, 4
    slli t2, a1, 1
    add t1, t1, t2
    add t1, s3, t1
    add t1, t1, t0
    lhu a1, 0(t1)
    j .Ltail_lookup
.Ltail_success:
    li a0, 1
    ret
.Ltail_failure:
    li a0, 0
    ret

    .section .rodata
.Lmove_text:
    .byte 82,0,0, 82,50,0, 82,39,0
    .byte 66,0,0, 66,50,0, 66,39,0
    .byte 68,0,0, 68,50,0, 68,39,0
.Lface_group:
    .byte 0,0,0,3,3,3,6,6,6
.Lperm_offset:
    .byte 0,0,0,2,2,2,4,4,4
.Lturn_count:
    .byte 1,2,3,1,2,3,1,2,3
    .include "src/rubik/rubik_tables.inc"
    .include "src/rubik/rubik_tail.inc"
    .include "src/rubik/rubik_distance11.inc"
    .section .note.GNU-stack,"",@progbits
