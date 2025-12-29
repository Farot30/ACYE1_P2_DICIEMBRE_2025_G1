.extern key_expansion
.extern add_round_key
.extern inv_shift_rows
.extern inv_sub_bytes
.extern inv_mix_columns

.section .bss
    input_cipher: .skip 33
    input_key: .skip 33
    test_cipher: .skip 16
    test_key: .skip 16
    expanded_keys: .skip 176
    work_state: .skip 16
    hex_buf: .skip 4
    num_buf: .skip 12

.section .data
    msg_input_cipher: .asciz "Ingrese el criptograma (32 caracteres hexadecimales): "
    msg_input_key: .asciz "Ingrese la clave (32 caracteres hexadecimales): "
    msg_title: .asciz "\n╔═══════════════════════════════════════════════════════╗\n"
    msg_title2: .asciz "║   DESENCRIPTACIÓN AES-128 - MODO DEPURACIÓN           ║\n"
    msg_title3: .asciz "╚═══════════════════════════════════════════════════════╝\n\n"
    msg_separator: .asciz "========================================================\n"
    msg_cipher_input: .asciz "[ENTRADA] Texto Cifrado:\n"
    msg_key_input: .asciz "\n[CLAVE] Clave Original:\n"
    msg_expanding:  .asciz "\n[EXPANSIÓN] Generando subclaves...\n"
    msg_expanded_header: .asciz "\nClaves Expandidas (11 subclaves):\n"
    msg_round_key: .asciz "  Ronda "
    msg_colon: .asciz ": "
    msg_decrypting: .asciz "\n[DESENCRIPTACIÓN] Iniciando proceso...\n"
    msg_round_init: .asciz "\n╔══ RONDA INICIAL (Ronda 10) ══╗\n"
    msg_round_intermediate: .asciz "\n╔══ RONDA INTERMEDIA "
    msg_round_end_bracket: .asciz " ══╗\n"
    msg_round_final: .asciz "\n╔══ RONDA FINAL (Ronda 0) ══╗\n"
    msg_before:  .asciz "  [ANTES]      "
    msg_after_ark: .asciz "  [ARK]       "
    msg_after_isr: .asciz "  [ISR]       "
    msg_after_isb: .asciz "  [ISB]       "
    msg_after_imc: .asciz "  [IMC]       "
    msg_round_key_used: .asciz "  [CLAVE]     "
    msg_result: .asciz "\n[RESULTADO FINAL]\n"
    msg_decrypted: .asciz "  Descifrado: "
    msg_ascii_out: .asciz "  ASCII:       \""
    msg_quote:  .asciz "\"\n"
    msg_error_input: .asciz "Error: Debe ingresar exactamente 32 caracteres hexadecimales.\n"
    msg_matriz_estado: .asciz "Matriz estado:\n"
    newline: .asciz "\n"
    space: .asciz " "
    space4: .asciz "    "

.section .text
.global _start

_start: 
    // ========================================
    // LEER CRIPTOGRAMA
    // ========================================
    mov x0, #1
    adr x1, msg_input_cipher
    mov x2, #54                 // Longitud del mensaje
    mov x8, #64                 // syscall write
    svc #0

    mov x0, #0                  // stdin
    adr x1, input_cipher
    mov x2, #33                 // 32 hex chars + newline
    mov x8, #63                 // syscall read
    svc #0
    
    // Convertir entrada hex a bytes
    adr x0, input_cipher
    adr x1, test_cipher
    bl hex_string_to_bytes
    
    // Verificar si la conversión fue exitosa
    cbnz x0, input_error

    // ========================================
    // LEER CLAVE
    // ========================================
    mov x0, #1
    adr x1, msg_input_key
    mov x2, #47                 // Longitud del mensaje
    mov x8, #64                 // syscall write
    svc #0

    mov x0, #0                  // stdin
    adr x1, input_key
    mov x2, #33                 // 32 hex chars + newline
    mov x8, #63                 // syscall read
    svc #0
    
    // Convertir entrada hex a bytes
    adr x0, input_key
    adr x1, test_key
    bl hex_string_to_bytes
    
    // Verificar si la conversión fue exitosa
    cbnz x0, input_error

    // ========================================
    // MOSTRAR TÍTULO
    // ========================================
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
    adr x0, msg_matriz_estado
    bl print_string
    adr x0, test_cipher
    bl print_matrix_4x4
    
    adr x0, msg_key_input
    bl print_string
    adr x0, msg_matriz_estado
    bl print_string
    adr x0, test_key
    bl print_matrix_4x4

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
    adr x0, newline
    bl print_string
    
    mov x20, #16
    mul x20, x19, x20
    adr x0, expanded_keys
    add x0, x0, x20
    bl print_hex_matrix
    
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
    adr x0, newline
    bl print_string
    adr x0, work_state
    bl print_hex_matrix
    
    adr x0, msg_round_key_used
    bl print_string
    adr x0, newline
    bl print_string
    adr x0, expanded_keys
    add x0, x0, #160
    bl print_hex_matrix
    
    adr x0, work_state
    adr x1, expanded_keys
    add x1, x1, #160
    bl add_round_key
    
    adr x0, msg_after_ark
    bl print_string
    adr x0, newline
    bl print_string
    adr x0, work_state
    bl print_hex_matrix

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
    adr x0, newline
    bl print_string
    adr x0, work_state
    bl print_hex_matrix
    
    // InvShiftRows
    adr x0, work_state
    bl inv_shift_rows
    
    adr x0, msg_after_isr
    bl print_string
    adr x0, newline
    bl print_string
    adr x0, work_state
    bl print_hex_matrix
    
    // InvSubBytes
    adr x0, work_state
    bl inv_sub_bytes
    
    adr x0, msg_after_isb
    bl print_string
    adr x0, newline
    bl print_string
    adr x0, work_state
    bl print_hex_matrix
    
    // AddRoundKey
    mov x24, x23
    lsl x24, x24, #4
    
    adr x0, msg_round_key_used
    bl print_string
    adr x0, newline
    bl print_string
    adr x1, expanded_keys
    add x1, x1, x24
    mov x0, x1
    bl print_hex_matrix
    
    adr x0, work_state
    adr x1, expanded_keys
    add x1, x1, x24
    bl add_round_key
    
    adr x0, msg_after_ark
    bl print_string
    adr x0, newline
    bl print_string
    adr x0, work_state
    bl print_hex_matrix
    
    stp x19, x20, [sp, #-16]!
    stp x21, x22, [sp, #-16]!
    stp x23, x24, [sp, #-16]!
    stp x25, x26, [sp, #-16]! 
    
    mov x26, #0
    
debug_imc_apply:
    ldp x25, x26, [sp], #16
    ldp x23, x24, [sp], #16
    ldp x21, x22, [sp], #16
    ldp x19, x20, [sp], #16
    
    adr x0, work_state
    bl inv_mix_columns
    
    adr x0, msg_after_imc
    bl print_string
    adr x0, newline
    bl print_string
    adr x0, work_state
    bl print_hex_matrix
    
    stp x19, x20, [sp, #-16]!
    stp x21, x22, [sp, #-16]! 
    stp x23, x24, [sp, #-16]!
    stp x25, x26, [sp, #-16]!
    
    mov x26, #0
    
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
    adr x0, newline
    bl print_string
    adr x0, work_state
    bl print_hex_matrix
    
    adr x0, work_state
    bl inv_shift_rows
    
    adr x0, msg_after_isr
    bl print_string
    adr x0, newline
    bl print_string
    adr x0, work_state
    bl print_hex_matrix
    
    adr x0, work_state
    bl inv_sub_bytes
    
    adr x0, msg_after_isb
    bl print_string
    adr x0, newline
    bl print_string
    adr x0, work_state
    bl print_hex_matrix
    
    adr x0, msg_round_key_used
    bl print_string
    adr x0, newline
    bl print_string
    adr x0, expanded_keys
    bl print_hex_matrix
    
    adr x0, work_state
    adr x1, expanded_keys
    bl add_round_key
    
    adr x0, msg_after_ark
    bl print_string
    adr x0, newline
    bl print_string
    adr x0, work_state
    bl print_hex_matrix

    // ========================================
    // MOSTRAR RESULTADO
    // ========================================
    adr x0, msg_separator
    bl print_string
    adr x0, msg_result
    bl print_string
    
    adr x0, msg_decrypted
    bl print_string
    adr x0, newline
    bl print_string
    adr x0, work_state
    bl print_hex_matrix
    
    adr x0, msg_ascii_out
    bl print_string
    adr x0, work_state
    bl print_ascii
    adr x0, msg_quote
    bl print_string

    // ========================================
    // FIN DEL PROGRAMA
    // ========================================
program_end:
    adr x0, msg_separator
    bl print_string
    adr x0, newline
    bl print_string
    
    mov x8, #93
    mov x0, #0
    svc #0

input_error:
    adr x0, msg_error_input
    bl print_string
    mov x8, #93
    mov x0, #1
    svc #0

// ============================================================
// FUNCIÓN:  hex_string_to_bytes
// Convierte una cadena hexadecimal a bytes
// Entrada: x0 = dirección de cadena hex (32 chars sin espacios)
//          x1 = dirección de salida (16 bytes)
// Salida: x0 = 0 si éxito, 1 si error
// ============================================================
hex_string_to_bytes:
    stp x29, x30, [sp, #-16]! 
    stp x19, x20, [sp, #-16]!
    stp x21, x22, [sp, #-16]!
    stp x23, x24, [sp, #-16]! 
    
    mov x19, x0         // Dirección de entrada
    mov x20, x1         // Dirección de salida
    mov x21, #0         // Índice de entrada
    mov x22, #0         // Índice de salida (bytes)
    
.Lhex_convert_loop:
    cmp x22, #16        // ¿Hemos procesado 16 bytes?
    bge .Lhex_success
    
    // Leer primer dígito hex
    ldrb w23, [x19, x21]
    add x21, x21, #1
    
    // Convertir primer dígito
    mov w0, w23
    bl hex_char_to_nibble
    cmp w0, #-1
    beq .Lhex_error
    lsl w23, w0, #4     // Mover a nibble alto
    
    // Leer segundo dígito hex
    ldrb w24, [x19, x21]
    add x21, x21, #1
    
    // Convertir segundo dígito
    mov w0, w24
    bl hex_char_to_nibble
    cmp w0, #-1
    beq .Lhex_error
    
    // Combinar nibbles
    orr w23, w23, w0
    
    // Guardar byte
    strb w23, [x20, x22]
    add x22, x22, #1
    
    b .Lhex_convert_loop
    
.Lhex_success:
    mov x0, #0
    b .Lhex_done
    
.Lhex_error:
    mov x0, #1
    
.Lhex_done:
    ldp x23, x24, [sp], #16
    ldp x21, x22, [sp], #16
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret

// ============================================================
// FUNCIÓN: hex_char_to_nibble
// Convierte un carácter hexadecimal a su valor numérico
// Entrada: w0 = carácter ASCII
// Salida: w0 = valor (0-15) o -1 si error
// ============================================================
hex_char_to_nibble:
    // Verificar '0'-'9'
    cmp w0, #'0'
    blt .Lnot_digit
    cmp w0, #'9'
    bgt .Lcheck_upper
    sub w0, w0, #'0'
    ret
    
.Lcheck_upper:
    // Verificar 'A'-'F'
    cmp w0, #'A'
    blt .Lcheck_lower
    cmp w0, #'F'
    bgt .Lcheck_lower
    sub w0, w0, #'A'
    add w0, w0, #10
    ret
    
.Lcheck_lower:
    // Verificar 'a'-'f'
    cmp w0, #'a'
    blt .Lnot_digit
    cmp w0, #'f'
    bgt .Lnot_digit
    sub w0, w0, #'a'
    add w0, w0, #10
    ret
    
.Lnot_digit:
    mov w0, #-1
    ret

// ============================================================
// FUNCIÓN: print_matrix_4x4
// Imprime matriz 4x4 con formato de 2 hex chars + espacio
// ============================================================
print_matrix_4x4:
    stp x29, x30, [sp, #-16]! 
    stp x19, x20, [sp, #-16]!
    stp x21, x22, [sp, #-16]!
    
    mov x19, x0         // Dirección de datos
    mov x20, #0         // Fila actual
    
.Lmat4_row_loop:
    cmp x20, #4
    bge .Lmat4_done
    
    // Imprimir 4 espacios de indentación
    adr x0, space4
    bl print_string
    
    mov x21, #0         // Columna actual
    
.Lmat4_col_loop:
    cmp x21, #4
    bge .Lmat4_row_end
    
    // Calcular índice:  fila + (columna * 4)
    mov x22, #4
    mul x22, x21, x22
    add x22, x22, x20
    
    // Cargar y mostrar byte
    ldrb w0, [x19, x22]
    bl print_byte_hex
    
    // Si no es la última columna, imprimir espacio
    cmp x21, #3
    beq .Lmat4_no_space
    adr x0, space
    bl print_string
    
.Lmat4_no_space:
    add x21, x21, #1
    b .Lmat4_col_loop
    
.Lmat4_row_end:
    adr x0, newline
    bl print_string
    
    add x20, x20, #1
    b .Lmat4_row_loop
    
.Lmat4_done:
    ldp x21, x22, [sp], #16
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret

// ============================================================
// FUNCIONES DE IMPRESIÓN ORIGINALES
// ============================================================

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
    mov x20, x1
    add x20, x20, #1
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

print_hex_matrix:
    stp x29, x30, [sp, #-16]!
    stp x19, x20, [sp, #-16]!
    stp x21, x22, [sp, #-16]! 
    stp x23, x24, [sp, #-16]! 
    
    mov x19, x0
    mov x20, #0
    
.Lmatrix_row_loop:
    cmp x20, #4
    bge .Lmatrix_done
    
    adr x0, space
    bl print_string
    adr x0, space
    bl print_string
    
    mov x21, #0
    
.Lmatrix_col_loop:
    cmp x21, #4
    bge .Lmatrix_row_end
    
    mov x22, #4
    mul x22, x21, x22
    add x22, x22, x20
    
    ldrb w0, [x19, x22]
    bl print_byte_hex
    
    adr x0, space
    bl print_string
    
    add x21, x21, #1
    b .Lmatrix_col_loop
    
.Lmatrix_row_end:
    adr x0, newline
    bl print_string
    
    add x20, x20, #1
    b .Lmatrix_row_loop
    
.Lmatrix_done:
    ldp x23, x24, [sp], #16
    ldp x21, x22, [sp], #16
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret