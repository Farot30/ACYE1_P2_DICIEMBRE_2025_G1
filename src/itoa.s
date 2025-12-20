.global int_to_ascii
int_to_ascii:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    mov x2, x1
    mov x3, #0
    mov w4, #10
    mov w8, #0
    cmp w0, #0
    bge convert_loop_start
    neg w0, w0
    mov w8, #1
convert_loop_start:
convert_loop:
    udiv w5, w0, w4
    msub w6, w5, w4, w0
    add w6, w6, #'0'
    strb w6, [x1], #1
    mov w0, w5
    add x3, x3, #1
    cbnz w0, convert_loop
    cmp w8, #0
    beq reverse_prep
    mov w6, #'-'
    strb w6, [x1], #1
    add x3, x3, #1
reverse_prep:
    sub x1, x1, #1
    mov x5, x2
reverse_loop:
    cmp x5, x1
    bge done_reverse
    ldrb w6, [x5]
    ldrb w7, [x1]
    strb w7, [x5]
    strb w6, [x1]
    add x5, x5, #1
    sub x1, x1, #1
    b reverse_loop
done_reverse:
    add x1, x2, x3
    mov w6, #0
    strb w6, [x1]
    ldp x29, x30, [sp], #16
    ret