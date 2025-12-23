.extern key_expansion

.section .data
    // ========================================
    // Clave de prueba (ejemplo del estándar FIPS-197)
    // ========================================
    test_key: .byte 0x54, 0x68, 0x61, 0x74
              .byte 0x73, 0x20, 0x6D, 0x79
              .byte 0x20, 0x4B, 0x75, 0x6E
              .byte 0x67, 0x20, 0x46, 0x75
    
    // ========================================
    // Buffer para claves expandidas
    // 44 palabras × 4 bytes = 176 bytes
    // ========================================
    expanded_keys: .skip 176
    
    // ========================================
    // Mensajes para la salida
    // ========================================
    msg_title: .asciz "\n=== AES-128 KEY EXPANSION TEST ===\n\n"
    msg_original: .asciz "Clave Original (128 bits):\n"
    msg_expanded: .asciz "\nClaves Expandidas (44 palabras):\n"
    msg_separator: .asciz "-----------------------------------\n"
    msg_round: .asciz "\n[Ronda "
    msg_round_end: .asciz "]\n"
    msg_word: .asciz "W["
    msg_colon: .asciz "]: "
    newline: .asciz "\n"
    space: .asciz " "
    
    // Buffers temporales
    hex_buf: .skip 4
    num_buf: .skip 12

.section .text
.global _start

_start:
    adr x0, msg_title
    bl print_string

    adr x0, msg_original
    bl print_string
    
    adr x0, msg_separator
    bl print_string
    
    mov x19, #0
print_original_loop:
    cmp x19, #4
    bge do_key_expansion
    
    // Imprimir "W[i]: "
    adr x0, msg_word
    bl print_string
    
    mov w0, w19
    bl print_number
    
    adr x0, msg_colon
    bl print_string
    
    // Imprimir palabra en formato hexadecimal
    adr x20, test_key
    ldr w0, [x20, x19, lsl #2]
    bl print_word_hex
    
    adr x0, newline
    bl print_string
    
    add x19, x19, #1
    b print_original_loop

do_key_expansion:
    adr x0, test_key
    adr x1, expanded_keys
    bl key_expansion
    
    adr x0, msg_expanded
    bl print_string
    
    adr x0, msg_separator
    bl print_string
    
    mov x19, #0
    mov x22, #0

print_by_rounds:
    cmp x22, #11
    bge program_end
    
    adr x0, msg_round
    bl print_string
    
    mov w0, w22
    bl print_number
    
    adr x0, msg_round_end
    bl print_string
    
    // Imprimir 4 palabras de esta ronda
    mov x21, #0
print_round_words:
    cmp x21, #4
    bge next_round
    
    adr x0, msg_word
    bl print_string
    
    mov w0, w19
    bl print_number
    
    adr x0, msg_colon
    bl print_string
    
    // Imprimir palabra
    adr x20, expanded_keys
    ldr w0, [x20, x19, lsl #2]
    bl print_word_hex
    
    adr x0, newline
    bl print_string
    
    add x19, x19, #1
    add x21, x21, #1
    b print_round_words

next_round:
    add x22, x22, #1
    b print_by_rounds

program_end:
    adr x0, newline
    bl print_string
    
    adr x0, msg_separator
    bl print_string
    
    // Salir
    mov x8, #93  // syscall exit
    mov x0, #0
    svc #0

print_word_hex:
    stp x29, x30, [sp, #-16]!
    stp x19, x20, [sp, #-16]!
    
    mov w19, w0
    
    mov w0, w19
    and w0, w0, #0xFF
    bl print_byte_hex
    
    adr x0, space
    bl print_string
    
    lsr w0, w19, #8
    and w0, w0, #0xFF
    bl print_byte_hex
    
    adr x0, space
    bl print_string
    
    // Byte 2
    lsr w0, w19, #16
    and w0, w0, #0xFF
    bl print_byte_hex
    
    adr x0, space
    bl print_string
    
    lsr w0, w19, #24
    and w0, w0, #0xFF
    bl print_byte_hex
    
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret

// print_byte_hex: Imprime un byte en hexadecimal
print_byte_hex:
    stp x29, x30, [sp, #-16]!
    stp x19, x20, [sp, #-16]!
    
    and w19, w0, #0xFF
    adr x20, hex_buf
    
    lsr w0, w19, #4
    cmp w0, #10
    blt .Ldigit1
    add w0, w0, #'A' - 10
    b .Lstore1
.Ldigit1:
    add w0, w0, #'0'
.Lstore1:
    strb w0, [x20]
    
    and w0, w19, #0x0F
    cmp w0, #10
    blt .Ldigit2
    add w0, w0, #'A' - 10
    b .Lstore2
.Ldigit2:
    add w0, w0, #'0'
.Lstore2:
    strb w0, [x20, #1]
    
    // Imprimir
    mov x0, #1      // stdout
    mov x1, x20     // buffer
    mov x2, #2      // longitud
    mov x8, #64     // syscall write
    svc #0
    
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret

// print_number: Imprime un número decimal

print_number:
    stp x29, x30, [sp, #-16]!
    stp x19, x20, [sp, #-16]!
    
    // Manejar caso especial: 0
    cbnz w0, .Lnot_zero
    mov w1, #'0'
    adr x2, num_buf
    strb w1, [x2]
    mov x0, #1
    mov x1, x2
    mov x2, #1
    mov x8, #64
    svc #0
    b .Lprint_num_done

.Lnot_zero:
    adr x19, num_buf
    mov x20, #0      // Contador de dígitos
    mov w1, w0       // Número a convertir
    mov w2, #10      // Divisor

.Lconvert_loop:
    cbz w1, .Lreverse
    udiv w3, w1, w2
    msub w4, w3, w2, w1
    add w4, w4, #'0'
    strb w4, [x19, x20]
    add x20, x20, #1
    mov w1, w3
    b .Lconvert_loop
    
    // Invertir dígitos
.Lreverse:
    mov x1, #0
    mov x2, x20
    sub x2, x2, #1
.Lreverse_loop:
    cmp x1, x2
    bge .Lprint_num
    ldrb w3, [x19, x1]
    ldrb w4, [x19, x2]
    strb w4, [x19, x1]
    strb w3, [x19, x2]
    add x1, x1, #1
    sub x2, x2, #1
    b .Lreverse_loop
    
    // Imprimir
.Lprint_num:
    mov x0, #1
    mov x1, x19
    mov x2, x20
    mov x8, #64
    svc #0
    
.Lprint_num_done:
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret

// print_string: Imprime una cadena terminada en null

print_string:
    stp x29, x30, [sp, #-16]!
    stp x19, x20, [sp, #-16]!
    
    mov x19, x0
    mov x20, #0
    
    // Calcular longitud
.Lstrlen:
    ldrb w1, [x19, x20]
    cbz w1, .Lprint
    add x20, x20, #1
    b .Lstrlen
    

.Lprint:
    mov x0, #1      // stdout
    mov x1, x19     // buffer
    mov x2, x20     // longitud
    mov x8, #64     // syscall write
    svc #0
    
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret
