.extern key_expansion
.extern add_round_key
.extern inv_shift_rows
.extern inv_sub_bytes
.extern inv_mix_columns

.section .data
    // ========================================
    // DATOS DE PRUEBA AES-128
    // Ejemplo: "Thats my Kung Fu" / "Two One Nine Two"
    // ========================================
    
    // Ciphertext: 29C3505F 571420F6 402299B3 1A02D73A
    test_cipher: .byte 0x29, 0xC3, 0x50, 0x5F
                 .byte 0x57, 0x14, 0x20, 0xF6
                 .byte 0x40, 0x22, 0x99, 0xB3
                 .byte 0x1A, 0x02, 0xD7, 0x3A
    
    // Key: "Thats my Kung Fu" = 54686174 73206D79 204B756E 67204675
    test_key: .byte 0x54, 0x68, 0x61, 0x74
              .byte 0x73, 0x20, 0x6D, 0x79
              .byte 0x20, 0x4B, 0x75, 0x6E
              .byte 0x67, 0x20, 0x46, 0x75
    
    // Expected Plaintext: "Two One Nine Two" = 54776F20 4F6E6520 4E696E65 2054776F
    expected_plain: .byte 0x54, 0x77, 0x6F, 0x20
                    .byte 0x4F, 0x6E, 0x65, 0x20
                    .byte 0x4E, 0x69, 0x6E, 0x65
                    .byte 0x20, 0x54, 0x77, 0x6F
    
    expanded_keys: .skip 176
    work_state: .skip 16

    // ========================================
    // MENSAJES
    // ========================================
    msg_title: .asciz "\n╔═══════════════════════════════════════════════════════╗\n"
    msg_title2: .asciz "║   DESENCRIPTACIÓN AES-128 - MODO DEPURACIÓN           ║\n"
    msg_title3: .asciz "╚═══════════════════════════════════════════════════════╝\n\n"
    
    msg_separator: .asciz "========================================================\n"
    msg_cipher_input: .asciz "[ENTRADA] Texto Cifrado:\n  "
    msg_key_input: .asciz "\n[CLAVE] Clave Original:\n  "
    msg_expanding: .asciz "\n[EXPANSIÓN] Generando subclaves...\n"
    
    msg_expanded_header: .asciz "\n[DEBUG] Claves Expandidas (11 subclaves):\n"
    msg_round_key: .asciz "  Ronda "
    msg_colon: .asciz ": "
    
    msg_decrypting: .asciz "\n[DESENCRIPTACIÓN] Iniciando proceso...\n"
    msg_round_init: .asciz "\n╔══ RONDA INICIAL (Ronda 10) ══╗\n"
    msg_round_intermediate: .asciz "\n╔══ RONDA INTERMEDIA "
    msg_round_end_bracket: .asciz " ══╗\n"
    msg_round_final: .asciz "\n╔══ RONDA FINAL (Ronda 0) ══╗\n"
    
    msg_before: .asciz "  [ANTES]      "
    msg_after_ark: .asciz "  [ARK]       "
    msg_after_isr: .asciz "  [ISR]       "
    msg_after_isb: .asciz "  [ISB]       "
    msg_after_imc: .asciz "  [IMC]       "
    
    msg_round_key_used: .asciz "  [CLAVE]     "
    
   // msg_column: .asciz "    Columna "
   // msg_before_imc: .asciz ": ["
   // msg_after_imc_col: .asciz "] -> ["
   // msg_close_bracket: .asciz "]\n"
    
    msg_result: .asciz "\n[RESULTADO FINAL]\n"
    msg_decrypted: .asciz "  Descifrado: "
    msg_expected: .asciz "  Esperado:   "
    msg_ascii_out: .asciz "  ASCII:      \""
    msg_quote: .asciz "\"\n"
    
    msg_success: .asciz "\n✓✓✓ ¡DESENCRIPTACIÓN EXITOSA! ✓✓✓\n"
    msg_error: .asciz "\n✗✗✗ ERROR: El resultado NO coincide ✗✗✗\n"
    
    msg_byte_diff: .asciz "  Diferencias encontradas:\n"
    msg_pos: .asciz "    Pos "
    msg_expected_byte: .asciz ": esperado=0x"
    msg_got_byte: .asciz ", obtenido=0x"

    msg_open_bracket: .asciz "["
    msg_close_bracket_space: .asciz "] "
    
    newline: .asciz "\n"
    space: .asciz " "
    hex_buf: .skip 4
    num_buf: .skip 12

.section .text
.global _start

_start:
    // Imprimir título
    adr x0, msg_title
    bl print_string
    adr x0, msg_title2
    bl print_string
    adr x0, msg_title3
    bl print_string
    adr x0, msg_separator
    bl print_string

    // ========================================
    // MOSTRAR ENTRADA
    // ========================================
    adr x0, msg_cipher_input
    bl print_string
    adr x0, test_cipher
    mov x1, #16
    bl print_hex_line
    
    adr x0, msg_key_input
    bl print_string
    adr x0, test_key
    mov x1, #16
    bl print_hex_line

    // ========================================
    // EXPANDIR CLAVE
    // ========================================
    adr x0, msg_separator
    bl print_string
    adr x0, msg_expanding
    bl print_string
    
    adr x0, test_key
    adr x1, expanded_keys
    bl key_expansion
    
    // ========================================
    // MOSTRAR CLAVES EXPANDIDAS
    // ========================================
    adr x0, msg_expanded_header
    bl print_string
    
    mov x19, #0
print_expanded_keys_loop:
    cmp x19, #11
    bge keys_printed
    
    adr x0, msg_round_key
    bl print_string
    
    stp x19, x20, [sp, #-16]!
    mov x0, x19
    bl print_number
    ldp x19, x20, [sp], #16
    
    adr x0, msg_colon
    bl print_string

    adr x0, msg_open_bracket        
    bl print_string
    
    mov x20, #16
    mul x20, x19, x20
    adr x0, expanded_keys
    add x0, x0, x20
    mov x1, #16
    bl print_hex_line_no_newline    
    
   adr x0, msg_close_bracket_space
    bl print_string
    adr x0, newline
    bl print_string
    
    add x19, x19, #1
    b print_expanded_keys_loop

keys_printed:
    // ========================================
    // COPIAR TEXTO CIFRADO
    // ========================================
    adr x19, test_cipher
    adr x20, work_state
    mov x21, #0
copy_cipher_loop:
    cmp x21, #16
    bge start_decryption
    ldrb w22, [x19, x21]
    strb w22, [x20, x21]
    add x21, x21, #1
    b copy_cipher_loop

start_decryption:
    adr x0, msg_separator
    bl print_string
    adr x0, msg_decrypting
    bl print_string

    // ========================================
    // RONDA INICIAL (Ronda 10)
    // ========================================
    adr x0, msg_round_init
    bl print_string
    
    adr x0, msg_before
    bl print_string
    adr x0, work_state
    mov x1, #16
    bl print_hex_line
    
    adr x0, msg_round_key_used
    bl print_string
    adr x0, expanded_keys
    add x0, x0, #160
    mov x1, #16
    bl print_hex_line
    
    adr x0, work_state
    adr x1, expanded_keys
    add x1, x1, #160
    bl add_round_key
    
    adr x0, msg_after_ark
    bl print_string
    adr x0, work_state
    mov x1, #16
    bl print_hex_line

    // ========================================
    // RONDAS INTERMEDIAS (9 hasta 1)
    // ========================================
    mov x23, #9

round_loop:
    cmp x23, #0
    ble final_round
    
    adr x0, msg_round_intermediate
    bl print_string
    
    stp x23, x24, [sp, #-16]!
    mov x0, x23
    bl print_number
    ldp x23, x24, [sp], #16
    
    adr x0, msg_round_end_bracket
    bl print_string
    
    adr x0, msg_before
    bl print_string
    adr x0, work_state
    mov x1, #16
    bl print_hex_line
    
    // 1. InvShiftRows
    adr x0, work_state
    bl inv_shift_rows
    
    adr x0, msg_after_isr
    bl print_string
    adr x0, work_state
    mov x1, #16
    bl print_hex_line
    
    // 2. InvSubBytes
    adr x0, work_state
    bl inv_sub_bytes
    
    adr x0, msg_after_isb
    bl print_string
    adr x0, work_state
    mov x1, #16
    bl print_hex_line
    
    // 3. AddRoundKey
    mov x24, x23
    lsl x24, x24, #4
    
    adr x0, msg_round_key_used
    bl print_string
    adr x1, expanded_keys
    add x1, x1, x24
    mov x0, x1
    mov x1, #16
    bl print_hex_line
    
    adr x0, work_state
    adr x1, expanded_keys
    add x1, x1, x24
    bl add_round_key
    
    adr x0, msg_after_ark
    bl print_string
    adr x0, work_state
    mov x1, #16
    bl print_hex_line
    
    // 4. InvMixColumns con debug mejorado
    stp x19, x20, [sp, #-16]!
    stp x21, x22, [sp, #-16]!
    stp x23, x24, [sp, #-16]!
    stp x25, x26, [sp, #-16]!
    
    // Mostrar columnas ANTES (en formato correcto: row-major)
    mov x26, #0
debug_imc_before:
    cmp x26, #4
    bge debug_imc_apply
    
    //adr x0, msg_column
    //bl print_string
    //mov x0, x26
    //bl print_number
    //adr x0, msg_before_imc
    //bl print_string
    
    // En column-major: columna C = bytes[C*4, C*4+1, C*4+2, C*4+3]
    adr x25, work_state
    lsl x22, x26, #2          // x22 = C * 4
    ldrb w0, [x25, x22]
    //bl print_byte_hex
    //adr x0, space
    //bl print_string
    
    add x22, x22, #1
    ldrb w0, [x25, x22]
    //bl print_byte_hex
    //adr x0, space
    //bl print_string
    
    add x22, x22, #1
    ldrb w0, [x25, x22]
    //bl print_byte_hex
    //adr x0, space
    //bl print_string
    
    add x22, x22, #1
    ldrb w0, [x25, x22]
    //bl print_byte_hex
   // adr x0, msg_close_bracket
   // bl print_string
    
    add x26, x26, #1
    b debug_imc_before
    
debug_imc_apply:
    ldp x25, x26, [sp], #16
    ldp x23, x24, [sp], #16
    ldp x21, x22, [sp], #16
    ldp x19, x20, [sp], #16
    
    adr x0, work_state
    bl inv_mix_columns
    
    adr x0, msg_after_imc
    bl print_string
    adr x0, work_state
    mov x1, #16
    bl print_hex_line
    
    // Mostrar columnas DESPUÉS
    stp x19, x20, [sp, #-16]!
    stp x21, x22, [sp, #-16]!
    stp x23, x24, [sp, #-16]!
    stp x25, x26, [sp, #-16]!
    
    mov x26, #0
debug_imc_after:
    cmp x26, #4
    bge debug_imc_complete
    
    //adr x0, msg_column
    //bl print_string
    //mov x0, x26
    //bl print_number
    //adr x0, msg_after_imc_col
    //bl print_string
    
    adr x25, work_state
    lsl x22, x26, #2          // x22 = C * 4
    ldrb w0, [x25, x22]
    //bl print_byte_hex
    //adr x0, space
    //bl print_string
    
    add x22, x22, #1
    ldrb w0, [x25, x22]
    //bl print_byte_hex
    //adr x0, space
    //bl print_string
    
    add x22, x22, #1
    ldrb w0, [x25, x22]
    //bl print_byte_hex
    //adr x0, space
    //bl print_string
    
    add x22, x22, #1
    ldrb w0, [x25, x22]
    //bl print_byte_hex
    //adr x0, msg_close_bracket
    //bl print_string
    
    add x26, x26, #1
    b debug_imc_after
    
debug_imc_complete:
    ldp x25, x26, [sp], #16
    ldp x23, x24, [sp], #16
    ldp x21, x22, [sp], #16
    ldp x19, x20, [sp], #16
    
    sub x23, x23, #1
    b round_loop

    // ========================================
    // RONDA FINAL (Ronda 0)
    // ========================================
final_round:
    adr x0, msg_round_final
    bl print_string
    
    adr x0, msg_before
    bl print_string
    adr x0, work_state
    mov x1, #16
    bl print_hex_line
    
    adr x0, work_state
    bl inv_shift_rows
    
    adr x0, msg_after_isr
    bl print_string
    adr x0, work_state
    mov x1, #16
    bl print_hex_line
    
    adr x0, work_state
    bl inv_sub_bytes
    
    adr x0, msg_after_isb
    bl print_string
    adr x0, work_state
    mov x1, #16
    bl print_hex_line
    
    adr x0, msg_round_key_used
    bl print_string
    adr x0, expanded_keys
    mov x1, #16
    bl print_hex_line
    
    adr x0, work_state
    adr x1, expanded_keys
    bl add_round_key
    
    adr x0, msg_after_ark
    bl print_string
    adr x0, work_state
    mov x1, #16
    bl print_hex_line

    // ========================================
    // MOSTRAR RESULTADO
    // ========================================
    adr x0, msg_separator
    bl print_string
    adr x0, msg_result
    bl print_string
    
    adr x0, msg_decrypted
    bl print_string
    adr x0, work_state
    mov x1, #16
    bl print_hex_line
    
    adr x0, msg_expected
    bl print_string
    adr x0, expected_plain
    mov x1, #16
    bl print_hex_line
    
    adr x0, msg_ascii_out
    bl print_string
    adr x0, work_state
    bl print_ascii
    adr x0, msg_quote
    bl print_string

    // ========================================
    // VERIFICAR
    // ========================================
    adr x19, work_state
    adr x20, expected_plain
    mov x21, #0
    mov x25, #0
    
verify_loop:
    cmp x21, #16
    bge check_result
    
    ldrb w22, [x19, x21]
    ldrb w23, [x20, x21]
    cmp w22, w23
    beq verify_next
    
    cmp x25, #0
    bne print_diff
    
    adr x0, msg_byte_diff
    bl print_string
    
print_diff:
    adr x0, msg_pos
    bl print_string
    
    stp x21, x26, [sp, #-16]!
    mov w0, w21
    bl print_number
    ldp x21, x26, [sp], #16
    
    adr x0, msg_expected_byte
    bl print_string
    mov w0, w23
    bl print_byte_hex
    
    adr x0, msg_got_byte
    bl print_string
    mov w0, w22
    bl print_byte_hex
    
    adr x0, newline
    bl print_string
    
    add x25, x25, #1
    
verify_next:
    add x21, x21, #1
    b verify_loop

check_result:
    cmp x25, #0
    bne verify_failed
    
verify_success:
    adr x0, msg_success
    bl print_string
    b program_end

verify_failed:
    adr x0, msg_error
    bl print_string

program_end:
    adr x0, msg_separator
    bl print_string
    adr x0, newline
    bl print_string
    
    mov x8, #93
    mov x0, #0
    svc #0

// ============================================================
// FUNCIONES DE IMPRESIÓN
// ============================================================

print_hex_line:
    stp x29, x30, [sp, #-16]!
    stp x19, x20, [sp, #-16]!
    stp x21, x22, [sp, #-16]!
    
    mov x19, x0
    mov x20, x1
    mov x21, #0
    
    // Imprimir corchete de apertura
    adr x0, msg_open_bracket
    bl print_string
    
.Lhex_line_loop:
    cmp x21, x20
    bge .Lhex_line_done
    
    ldrb w0, [x19, x21]
    bl print_byte_hex
    
    adr x0, space
    bl print_string
    
    add x21, x21, #1
    b .Lhex_line_loop
    
.Lhex_line_done:
    // Imprimir corchete de cierre
    adr x0, msg_close_bracket_space
    bl print_string
    
    adr x0, newline
    bl print_string
    
    ldp x21, x22, [sp], #16
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret

print_ascii:
    stp x29, x30, [sp, #-16]!
    stp x19, x20, [sp, #-16]!
    
    mov x19, x0
    mov x20, #0
    
.Lascii_loop:
    cmp x20, #16
    bge .Lascii_done
    
    ldrb w0, [x19, x20]
    
    cmp w0, #32
    blt .Lprint_dot
    cmp w0, #126
    bgt .Lprint_dot
    
    adr x1, hex_buf
    strb w0, [x1]
    mov w2, #0
    strb w2, [x1, #1]
    mov x0, x1
    bl print_string
    b .Lascii_next
    
.Lprint_dot:
    mov w0, #'.'
    adr x1, hex_buf
    strb w0, [x1]
    mov w0, #0
    strb w0, [x1, #1]
    mov x0, x1
    bl print_string
    
.Lascii_next:
    add x20, x20, #1
    b .Lascii_loop
    
.Lascii_done:
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret

print_byte_hex:
    stp x29, x30, [sp, #-16]!
    stp x19, x20, [sp, #-16]!
    
    mov w19, w0
    
    lsr w0, w19, #4
    and w0, w0, #0x0F
    cmp w0, #10
    bge .Ldigit1
    add w0, w0, #'0'
    b .Lstore1
.Ldigit1:
    sub w0, w0, #10
    add w0, w0, #'A'
.Lstore1:
    adr x20, hex_buf
    strb w0, [x20]
    
    and w0, w19, #0x0F
    cmp w0, #10
    bge .Ldigit2
    add w0, w0, #'0'
    b .Lstore2
.Ldigit2:
    sub w0, w0, #10
    add w0, w0, #'A'
.Lstore2:
    strb w0, [x20, #1]
    mov w0, #0
    strb w0, [x20, #2]
    
    mov x0, x20
    bl print_string
    
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret

print_number:
    stp x29, x30, [sp, #-16]!
    stp x19, x20, [sp, #-16]!
    stp x21, x22, [sp, #-16]!
    
    adr x19, num_buf
    mov x20, x19
    mov w21, w0
    
    cbnz w21, .Lnot_zero
    mov w0, #'0'
    strb w0, [x20]
    add x20, x20, #1
    b .Lprint_num
    
.Lnot_zero:
    mov w22, #10
    mov x1, x20
    
.Lconvert_loop:
    cbz w21, .Lreverse
    udiv w2, w21, w22
    msub w3, w2, w22, w21
    add w3, w3, #'0'
    strb w3, [x1], #1
    mov w21, w2
    b .Lconvert_loop
    
.Lreverse:
    sub x1, x1, #1
    mov x2, x20
    sub x2, x2, #1
    mov x20, x1        // Guardar posición del último dígito
    add x20, x20, #1   // Apuntar después del último dígito
.Lreverse_loop:
    add x2, x2, #1
    cmp x2, x1
    bge .Lprint_num
    ldrb w3, [x2]
    ldrb w4, [x1]
    strb w4, [x2]
    strb w3, [x1]
    sub x1, x1, #1
    b .Lreverse_loop
    
.Lprint_num:
    mov w0, #0
    strb w0, [x20]
    mov x0, x19
    bl print_string
    
.Lprint_num_done:
    ldp x21, x22, [sp], #16
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret

print_string:
    stp x29, x30, [sp, #-16]!
    stp x19, x20, [sp, #-16]!
    
    mov x19, x0
    mov x20, #0
    
.Lstrlen:
    ldrb w1, [x19, x20]
    cbz w1, .Lprint
    add x20, x20, #1
    b .Lstrlen
    
.Lprint:
    mov x0, #1
    mov x1, x19
    mov x2, x20
    mov x8, #64
    svc #0
    
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret

// Imprime hex en una línea sin newline al final
print_hex_line_no_newline:
    stp x29, x30, [sp, #-16]!
    stp x19, x20, [sp, #-16]!
    stp x21, x22, [sp, #-16]!
    
    mov x19, x0
    mov x20, x1
    mov x21, #0
    
.Lhex_no_nl_loop:
    cmp x21, x20
    bge .Lhex_no_nl_done
    
    ldrb w0, [x19, x21]
    bl print_byte_hex
    
    adr x0, space
    bl print_string
    
    add x21, x21, #1
    b .Lhex_no_nl_loop
    
.Lhex_no_nl_done:
    ldp x21, x22, [sp], #16
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret