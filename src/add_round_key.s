// ============================================================
// Función: add_round_key
// Descripción: Realiza XOR entre el estado y la clave de ronda
// Entrada:
//   x0 = dirección del estado (16 bytes)
//   x1 = dirección de la clave de ronda (16 bytes)
// Salida:
//   El estado en x0 se modifica con el resultado del XOR
// ============================================================
.global add_round_key

.text
add_round_key:
    stp x29, x30, [sp, #-16]!
    stp x19, x20, [sp, #-16]!
    stp x21, x22, [sp, #-16]!
    
    mov x19, x0      // x19 = dirección del estado
    mov x20, x1      // x20 = dirección de la clave de ronda
    
    // Procesar 16 bytes (4 palabras de 32 bits)
    mov x21, #0      // contador
    
add_round_key_loop:
    cmp x21, #4      // 4 palabras (16 bytes)
    bge add_round_key_done
    
    // Cargar palabra del estado
    ldr w22, [x19, x21, lsl #2]
    
    // Cargar palabra de la clave
    ldr w23, [x20, x21, lsl #2]
    
    // XOR
    eor w22, w22, w23
    
    // Guardar resultado en el estado
    str w22, [x19, x21, lsl #2]
    
    add x21, x21, #1
    b add_round_key_loop
    
add_round_key_done:
    ldp x21, x22, [sp], #16
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret
