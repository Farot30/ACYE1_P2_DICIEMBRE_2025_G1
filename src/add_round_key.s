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
    
    // Procesar 16 bytes individualmente
    mov x21, #0      // contador
    
add_round_key_loop:
    cmp x21, #16     // 16 bytes
    bge add_round_key_done
    
    // Cargar byte del estado
    ldrb w22, [x19, x21]
    
    // Cargar byte de la clave
    ldrb w1, [x20, x21]
    
    // XOR
    eor w22, w22, w1
    
    // Guardar resultado en el estado
    strb w22, [x19, x21]
    
    add x21, x21, #1
    b add_round_key_loop
    
add_round_key_done:
    ldp x21, x22, [sp], #16
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret
