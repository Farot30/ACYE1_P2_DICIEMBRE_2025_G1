.global _start

.data
    // Clave original de 128 bits (16 bytes) - Ejemplo de prueba
    original_key: .byte 0x2b, 0x7e, 0x15, 0x16, 0x28, 0xae, 0xd2, 0xa6
                  .byte 0xab, 0xf7, 0x15, 0x88, 0x09, 0xcf, 0x4f, 0x3c
    
    // Tabla S-Box para ByteSub (256 bytes)
    sbox: .byte 0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5
          .byte 0x30, 0x01, 0x67, 0x2b, 0xfe, 0xd7, 0xab, 0x76
          .byte 0xca, 0x82, 0xc9, 0x7d, 0xfa, 0x59, 0x47, 0xf0
          .byte 0xad, 0xd4, 0xa2, 0xaf, 0x9c, 0xa4, 0x72, 0xc0
          .byte 0xb7, 0xfd, 0x93, 0x26, 0x36, 0x3f, 0xf7, 0xcc
          .byte 0x34, 0xa5, 0xe5, 0xf1, 0x71, 0xd8, 0x31, 0x15
          .byte 0x04, 0xc7, 0x23, 0xc3, 0x18, 0x96, 0x05, 0x9a
          .byte 0x07, 0x12, 0x80, 0xe2, 0xeb, 0x27, 0xb2, 0x75
          .byte 0x09, 0x83, 0x2c, 0x1a, 0x1b, 0x6e, 0x5a, 0xa0
          .byte 0x52, 0x3b, 0xd6, 0xb3, 0x29, 0xe3, 0x2f, 0x84
          .byte 0x53, 0xd1, 0x00, 0xed, 0x20, 0xfc, 0xb1, 0x5b
          .byte 0x6a, 0xcb, 0xbe, 0x39, 0x4a, 0x4c, 0x58, 0xcf
          .byte 0xd0, 0xef, 0xaa, 0xfb, 0x43, 0x4d, 0x33, 0x85
          .byte 0x45, 0xf9, 0x02, 0x7f, 0x50, 0x3c, 0x9f, 0xa8
          .byte 0x51, 0xa3, 0x40, 0x8f, 0x92, 0x9d, 0x38, 0xf5
          .byte 0xbc, 0xb6, 0xda, 0x21, 0x10, 0xff, 0xf3, 0xd2
          .byte 0xcd, 0x0c, 0x13, 0xec, 0x5f, 0x97, 0x44, 0x17
          .byte 0xc4, 0xa7, 0x7e, 0x3d, 0x64, 0x5d, 0x19, 0x73
          .byte 0x60, 0x81, 0x4f, 0xdc, 0x22, 0x2a, 0x90, 0x88
          .byte 0x46, 0xee, 0xb8, 0x14, 0xde, 0x5e, 0x0b, 0xdb
          .byte 0xe0, 0x32, 0x3a, 0x0a, 0x49, 0x06, 0x24, 0x5c
          .byte 0xc2, 0xd3, 0xac, 0x62, 0x91, 0x95, 0xe4, 0x79
          .byte 0xe7, 0xc8, 0x37, 0x6d, 0x8d, 0xd5, 0x4e, 0xa9
          .byte 0x6c, 0x56, 0xf4, 0xea, 0x65, 0x7a, 0xae, 0x08
          .byte 0xba, 0x78, 0x25, 0x2e, 0x1c, 0xa6, 0xb4, 0xc6
          .byte 0xe8, 0xdd, 0x74, 0x1f, 0x4b, 0xbd, 0x8b, 0x8a
          .byte 0x70, 0x3e, 0xb5, 0x66, 0x48, 0x03, 0xf6, 0x0e
          .byte 0x61, 0x35, 0x57, 0xb9, 0x86, 0xc1, 0x1d, 0x9e
          .byte 0xe1, 0xf8, 0x98, 0x11, 0x69, 0xd9, 0x8e, 0x94
          .byte 0x9b, 0x1e, 0x87, 0xe9, 0xce, 0x55, 0x28, 0xdf
          .byte 0x8c, 0xa1, 0x89, 0x0d, 0xbf, 0xe6, 0x42, 0x68
          .byte 0x41, 0x99, 0x2d, 0x0f, 0xb0, 0x54, 0xbb, 0x16

    rcon: .byte 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1b, 0x36
    expanded_keys: .skip 176
    
    msg_original: .asciz "Clave Original:\n"
    msg_expanded: .asciz "\nClaves Expandidas (44 palabras):\n"
    msg_debug1: .asciz "[DEBUG] Iniciando key_expansion...\n"
    msg_debug2: .asciz "[DEBUG] Copiando primeras 4 palabras...\n"
    msg_debug3: .asciz "[DEBUG] Expansion loop iniciado, i = "
    msg_debug4: .asciz "[DEBUG] Procesando W["
    msg_debug5: .asciz "] - Es multiplo de 4\n"
    msg_debug6: .asciz "] - NO es multiplo de 4\n"
    msg_debug7: .asciz "[DEBUG] Antes de rot_byte\n"
    msg_debug8: .asciz "[DEBUG] Despues de rot_byte\n"
    msg_debug9: .asciz "[DEBUG] Antes de byte_sub\n"
    msg_debug10: .asciz "[DEBUG] Despues de byte_sub\n"
    msg_debug11: .asciz "[DEBUG] Key expansion completado!\n"
    newline: .asciz "\n"
    word_prefix: .asciz "W["
    word_sep: .asciz "]: "
    hex_buf: .skip 3
    num_buf: .skip 12

.text

_start:
    // Imprimir clave original
    adr x0, msg_original
    bl print_string
    
    mov x19, #0
print_original_loop:
    cmp x19, #4
    bge do_expansion
    
    adr x0, word_prefix
    bl print_string
    mov w0, w19
    adr x1, num_buf
    bl int_to_ascii
    adr x0, num_buf
    bl print_string
    adr x0, word_sep
    bl print_string
    
    adr x20, original_key
    ldr w0, [x20, x19, lsl #2]
    bl print_word_simple
    
    adr x0, newline
    bl print_string
    
    add x19, x19, #1
    b print_original_loop

do_expansion:
    // DEBUG
    adr x0, msg_debug1
    bl print_string
    
    // Realizar Key Expansion
    adr x0, original_key
    adr x1, expanded_keys
    bl key_expansion
    
    // DEBUG
    adr x0, msg_debug11
    bl print_string
    
    // Imprimir claves expandidas
    adr x0, msg_expanded
    bl print_string
    
    mov x19, #0
print_expanded_loop:
    cmp x19, #44
    bge done
    
    adr x0, word_prefix
    bl print_string
    mov w0, w19
    adr x1, num_buf
    bl int_to_ascii
    adr x0, num_buf
    bl print_string
    adr x0, word_sep
    bl print_string
    
    adr x20, expanded_keys
    ldr w0, [x20, x19, lsl #2]
    bl print_word_simple
    
    adr x0, newline
    bl print_string
    
    add x19, x19, #1
    b print_expanded_loop

done:
    mov x8, #93
    mov x0, #0
    svc #0

// ============================================================
// Función: key_expansion
// ============================================================
key_expansion:
    stp x29, x30, [sp, #-16]!
    stp x19, x20, [sp, #-16]!
    stp x21, x22, [sp, #-16]!
    stp x23, x24, [sp, #-16]!
    stp x25, x26, [sp, #-16]!
    
    mov x19, x0  // x19 = dirección clave original
    mov x20, x1  // x20 = dirección expanded_keys
    
    // DEBUG
    adr x0, msg_debug2
    bl print_string
    
    // Copiar las primeras 4 palabras
    mov x21, #0
copy_initial:
    cmp x21, #4
    bge expansion_loop_init
    
    ldr w22, [x19, x21, lsl #2]
    str w22, [x20, x21, lsl #2]
    add x21, x21, #1
    b copy_initial

expansion_loop_init:
    mov x21, #4  // i = 4

expansion_loop:
    cmp x21, #44
    bge expansion_done
    
    // DEBUG: Imprimir i actual
    adr x0, msg_debug4
    bl print_string
    mov w0, w21
    adr x1, num_buf
    bl int_to_ascii
    adr x0, num_buf
    bl print_string
    
    // Cargar W[i-1]
    sub x22, x21, #1
    ldr w23, [x20, x22, lsl #2]
    
    // Verificar si i es múltiplo de 4
    and x24, x21, #3
    cbnz x24, not_multiple
    
    // DEBUG
    adr x0, msg_debug5
    bl print_string
    
    // DEBUG
    adr x0, msg_debug7
    bl print_string
    
    // Es múltiplo de 4
    mov w0, w23
    bl rot_byte
    mov w23, w0
    
    // DEBUG
    adr x0, msg_debug8
    bl print_string
    
    // DEBUG
    adr x0, msg_debug9
    bl print_string
    
    mov w0, w23
    bl byte_sub
    mov w23, w0
    
    // DEBUG
    adr x0, msg_debug10
    bl print_string
    
    // XOR con Rcon
    lsr x24, x21, #2
    sub x24, x24, #1
    adr x25, rcon
    ldrb w25, [x25, x24]
    eor w23, w23, w25
    
    // Cargar W[i-4]
    sub x22, x21, #4
    ldr w24, [x20, x22, lsl #2]
    
    // W[i] = W[i-4] XOR resultado
    eor w23, w24, w23
    str w23, [x20, x21, lsl #2]
    
    add x21, x21, #1
    b expansion_loop

not_multiple:
    // DEBUG
    adr x0, msg_debug6
    bl print_string
    
    // No es múltiplo
    sub x22, x21, #4
    ldr w24, [x20, x22, lsl #2]
    eor w23, w24, w23
    str w23, [x20, x21, lsl #2]
    
    add x21, x21, #1
    b expansion_loop

expansion_done:
    ldp x25, x26, [sp], #16
    ldp x23, x24, [sp], #16
    ldp x21, x22, [sp], #16
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret

// ============================================================
// Función: rot_byte
// ============================================================
rot_byte:
    ror w0, w0, #8
    ret

// ============================================================
// Función: byte_sub
// ============================================================
byte_sub:
    stp x29, x30, [sp, #-16]!
    stp x19, x20, [sp, #-16]!
    stp x21, x22, [sp, #-16]!
    
    mov w19, w0
    adr x20, sbox
    mov w21, #0
    
    // Byte 0
    and w1, w19, #0xFF
    uxtw x1, w1
    ldrb w1, [x20, x1]
    orr w21, w21, w1
    
    // Byte 1
    lsr w1, w19, #8
    and w1, w1, #0xFF
    uxtw x1, w1
    ldrb w1, [x20, x1]
    lsl w1, w1, #8
    orr w21, w21, w1
    
    // Byte 2
    lsr w1, w19, #16
    and w1, w1, #0xFF
    uxtw x1, w1
    ldrb w1, [x20, x1]
    lsl w1, w1, #16
    orr w21, w21, w1
    
    // Byte 3
    lsr w1, w19, #24
    uxtw x1, w1
    ldrb w1, [x20, x1]
    lsl w1, w1, #24
    orr w21, w21, w1
    
    mov w0, w21
    
    ldp x21, x22, [sp], #16
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret

// ============================================================
// Funciones de impresión
// ============================================================
print_word_simple:
    stp x29, x30, [sp, #-16]!
    stp x19, x20, [sp, #-16]!
    
    mov w19, w0
    
    lsr w0, w19, #24
    and w0, w0, #0xFF
    bl print_byte_simple
    
    lsr w0, w19, #16
    and w0, w0, #0xFF
    bl print_byte_simple
    
    lsr w0, w19, #8
    and w0, w0, #0xFF
    bl print_byte_simple
    
    mov w0, w19
    and w0, w0, #0xFF
    bl print_byte_simple
    
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret

print_byte_simple:
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
    mov w0, #' '
    strb w0, [x20, #2]
    
    mov x0, #1
    mov x1, x20
    mov x2, #3
    mov x8, #64
    svc #0
    
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret

print_string:
    stp x29, x30, [sp, #-16]!
    mov x2, #0
.Lstrlen:
    ldrb w3, [x0, x2]
    cbz w3, .Lprint
    add x2, x2, #1
    b .Lstrlen
.Lprint:
    mov x1, x0
    mov x0, #1
    mov x8, #64
    svc #0
    ldp x29, x30, [sp], #16
    ret
