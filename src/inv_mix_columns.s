.global inv_mix_columns

.section .text

// ============================================================
// Función: inv_mix_columns
// Descripción: Aplica la transformación InverseMixColumns sobre
//              la matriz de estado en formato COLUMN-MAJOR
//
// El estado en memoria está organizado por COLUMNAS:
//   Byte:  0  4  8  12
//          1  5  9  13
//          2  6  10 14
//          3  7  11 15
//
// Para procesar columnas, necesitamos los bytes en posiciones:
//   Columna 0: bytes[0, 1, 2, 3]
//   Columna 1: bytes[4, 5, 6, 7]
//   Columna 2: bytes[8, 9, 10, 11]
//   Columna 3: bytes[12, 13, 14, 15]
//
// Matriz de transformación:
//   [0E 0B 0D 09]   [s0]   [d0]
//   [09 0E 0B 0D] × [s1] = [d1]
//   [0D 09 0E 0B]   [s2]   [d2]
//   [0B 0D 09 0E]   [s3]   [d3]
// ============================================================
inv_mix_columns:
    // Guardar registros
    stp x29, x30, [sp, #-16]!
    stp x19, x20, [sp, #-16]!
    stp x21, x22, [sp, #-16]!
    stp x23, x24, [sp, #-16]!
    stp x25, x26, [sp, #-16]!
    stp x27, x28, [sp, #-16]!
    
    mov x19, x0  // x19 = dirección del estado
    mov x20, #0  // x20 = índice de columna (0, 1, 2, 3)
    
    // ========================================
    // Procesar cada una de las 4 columnas
    // ========================================
process_column_loop:
    cmp x20, #4
    bge inv_mix_columns_done
    
    // Cargar los 4 bytes de la columna en formato COLUMN-MAJOR
    // Columna C: bytes en posiciones [C*4, C*4+1, C*4+2, C*4+3]
    lsl x21, x20, #2               // x21 = C * 4
    ldrb w22, [x19, x21]           // s0 = state[C*4]
    add x21, x21, #1
    ldrb w23, [x19, x21]           // s1 = state[C*4+1]
    add x21, x21, #1
    ldrb w24, [x19, x21]           // s2 = state[C*4+2]
    add x21, x21, #1
    ldrb w25, [x19, x21]           // s3 = state[C*4+3]
    
    // Guardar s0-s3 en el stack para protegerlos
    stp x22, x23, [sp, #-16]!
    stp x24, x25, [sp, #-16]!
    
    // ========================================
    // Calcular d0 = (0E•s0) ⊕ (0B•s1) ⊕ (0D•s2) ⊕ (09•s3)
    // ========================================
    mov w0, w22
    bl gmult_0e
    mov w26, w0  // w26 = 0E•s0
    
    mov w0, w23
    bl gmult_0b
    eor w26, w26, w0  // w26 = (0E•s0) ⊕ (0B•s1)
    
    mov w0, w24
    bl gmult_0d
    eor w26, w26, w0  // w26 = (0E•s0) ⊕ (0B•s1) ⊕ (0D•s2)
    
    mov w0, w25
    bl gmult_09
    eor w26, w26, w0  // w26 = d0 completo
    
    // Restaurar s0-s3 antes de calcular d1
    ldp x24, x25, [sp], #16
    ldp x22, x23, [sp], #16
    
    // Guardar de nuevo para los siguientes cálculos
    stp x22, x23, [sp, #-16]!
    stp x24, x25, [sp, #-16]!
    
    // ========================================
    // Calcular d1 = (09•s0) ⊕ (0E•s1) ⊕ (0B•s2) ⊕ (0D•s3)
    // ========================================
    mov w0, w22
    bl gmult_09
    mov w27, w0  // w27 = 09•s0
    
    mov w0, w23
    bl gmult_0e
    eor w27, w27, w0  // w27 = (09•s0) ⊕ (0E•s1)
    
    mov w0, w24
    bl gmult_0b
    eor w27, w27, w0  // w27 = (09•s0) ⊕ (0E•s1) ⊕ (0B•s2)
    
    mov w0, w25
    bl gmult_0d
    eor w27, w27, w0  // w27 = d1 completo
    
    // Restaurar s0-s3 antes de calcular d2
    ldp x24, x25, [sp], #16
    ldp x22, x23, [sp], #16
    
    // Guardar de nuevo para los siguientes cálculos
    stp x22, x23, [sp, #-16]!
    stp x24, x25, [sp, #-16]!
    
    // ========================================
    // Calcular d2 = (0D•s0) ⊕ (09•s1) ⊕ (0E•s2) ⊕ (0B•s3)
    // ========================================
    mov w0, w22
    bl gmult_0d
    mov w28, w0  // w28 = 0D•s0
    
    mov w0, w23
    bl gmult_09
    eor w28, w28, w0  // w28 = (0D•s0) ⊕ (09•s1)
    
    mov w0, w24
    bl gmult_0e
    eor w28, w28, w0  // w28 = (0D•s0) ⊕ (0E•s2)
    
    mov w0, w25
    bl gmult_0b
    eor w28, w28, w0  // w28 = d2 completo
    
    // Restaurar s0-s3 antes de calcular d3
    ldp x24, x25, [sp], #16
    ldp x22, x23, [sp], #16
    
    // Guardar de nuevo para el último cálculo
    stp x22, x23, [sp, #-16]!
    stp x24, x25, [sp, #-16]!
    
    // ========================================
    // Calcular d3 = (0B•s0) ⊕ (0D•s1) ⊕ (09•s2) ⊕ (0E•s3)
    // ========================================
    mov w0, w22
    bl gmult_0b
    mov w6, w0  // w6 = 0B•s0 (usar w6 en lugar de w1)
    
    mov w0, w23
    bl gmult_0d
    eor w6, w6, w0  // w6 = (0B•s0) ⊕ (0D•s1)
    
    mov w0, w24
    bl gmult_09
    eor w6, w6, w0  // w6 = (0B•s0) ⊕ (0D•s1) ⊕ (09•s2)
    
    mov w0, w25
    bl gmult_0e
    eor w6, w6, w0  // w6 = d3 completo
    
    // Restaurar s0-s3 por última vez
    ldp x24, x25, [sp], #16
    ldp x22, x23, [sp], #16
    
    // ========================================
    // Guardar los 4 bytes calculados de vuelta en la columna
    // En formato COLUMN-MAJOR: [C*4, C*4+1, C*4+2, C*4+3]
    // ========================================
    lsl x21, x20, #2               // x21 = C * 4
    strb w26, [x19, x21]           // Guardar d0 en state[C*4]
    add x21, x21, #1
    strb w27, [x19, x21]           // Guardar d1 en state[C*4+1]
    add x21, x21, #1
    strb w28, [x19, x21]           // Guardar d2 en state[C*4+2]
    add x21, x21, #1
    strb w6, [x19, x21]            // Guardar d3 en state[C*4+3]
    
    // Siguiente columna
    add x20, x20, #1
    b process_column_loop

inv_mix_columns_done:
    // Restaurar registros
    ldp x27, x28, [sp], #16
    ldp x25, x26, [sp], #16
    ldp x23, x24, [sp], #16
    ldp x21, x22, [sp], #16
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret

// ============================================================
// FUNCIONES DE MULTIPLICACIÓN EN GF(2^8)
// ============================================================

// ------------------------------------------------------------
// gmult_02: Multiplicación por 0x02 en GF(2^8)
// ------------------------------------------------------------
gmult_02:
    and w4, w0, #0x80        // Verificar bit más significativo
    lsl w0, w0, #1           // Desplazar a la izquierda
    and w0, w0, #0xFF        // Mantener solo 8 bits
    
    cbz w4, gmult_02_done    // Si bit MSB era 0, terminar
    mov w5, #0x1B
    eor w0, w0, w5           // Si bit MSB era 1, XOR con 0x1B
    
gmult_02_done:
    ret

// ------------------------------------------------------------
// gmult_09: Multiplicación por 0x09 en GF(2^8)
// 0x09 = (b * 8) ⊕ b
// ------------------------------------------------------------
gmult_09:
    stp x29, x30, [sp, #-16]!
    stp x19, x20, [sp, #-16]!
    stp x21, x22, [sp, #-16]!
    
    mov w19, w0              // Guardar valor original
    
    bl gmult_02              // b * 2
    mov w20, w0
    mov w0, w20
    bl gmult_02              // b * 4
    mov w21, w0
    mov w0, w21
    bl gmult_02              // b * 8
    mov w22, w0
    
    eor w0, w22, w19         // (b * 8) ⊕ b
    and w0, w0, #0xFF
    
    ldp x21, x22, [sp], #16
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret

// ------------------------------------------------------------
// gmult_0b: Multiplicación por 0x0B en GF(2^8)
// 0x0B = (b * 8) ⊕ (b * 2) ⊕ b
// ------------------------------------------------------------
gmult_0b:
    stp x29, x30, [sp, #-16]!
    stp x19, x20, [sp, #-16]!
    stp x21, x22, [sp, #-16]!
    
    mov w19, w0              // Guardar valor original
    
    bl gmult_02              // b * 2
    mov w20, w0              // w20 = b * 2
    mov w0, w20
    bl gmult_02              // b * 4
    mov w21, w0
    mov w0, w21
    bl gmult_02              // b * 8
    mov w22, w0              // w22 = b * 8
    
    eor w0, w22, w20         // (b * 8) ⊕ (b * 2)
    eor w0, w0, w19          // ⊕ b
    and w0, w0, #0xFF
    
    ldp x21, x22, [sp], #16
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret

// ------------------------------------------------------------
// gmult_0d: Multiplicación por 0x0D en GF(2^8)
// 0x0D = (b*8) ⊕ (b*4) ⊕ b
// ------------------------------------------------------------
gmult_0d:
    stp x29, x30, [sp, #-16]!
    stp x19, x20, [sp, #-16]!
    stp x21, x22, [sp, #-16]!
    
    mov w19, w0              // Guardar valor original (b)
    
    bl gmult_02
    mov w20, w0              // w20 = b * 2
    
    mov w0, w20
    bl gmult_02
    mov w21, w0              // w21 = b * 4
    
    mov w0, w21
    bl gmult_02
    mov w22, w0              // w22 = b * 8
    
    eor w0, w22, w21         // (b*8) ⊕ (b*4)
    eor w0, w0, w19          // ⊕ b
    and w0, w0, #0xFF
    
    ldp x21, x22, [sp], #16
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret

// ------------------------------------------------------------
// gmult_0e: Multiplicación por 0x0E en GF(2^8)
// 0x0E = (b*8) ⊕ (b*4) ⊕ (b*2)
// ------------------------------------------------------------
gmult_0e:
    stp x29, x30, [sp, #-16]!
    stp x19, x20, [sp, #-16]!
    stp x21, x22, [sp, #-16]!
    
    mov w19, w0              // Guardar valor original (b)
    
    bl gmult_02
    mov w20, w0              // w20 = b * 2
    
    mov w0, w20
    bl gmult_02
    mov w21, w0              // w21 = b * 4
    
    mov w0, w21
    bl gmult_02
    mov w22, w0              // w22 = b * 8
    
    eor w0, w22, w21         // (b*8) ⊕ (b*4)
    eor w0, w0, w20          // ⊕ (b*2)
    and w0, w0, #0xFF
    
    ldp x21, x22, [sp], #16
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret
