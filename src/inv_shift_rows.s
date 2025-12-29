.global inv_shift_rows

.section .text

// ============================================================
// Función: inv_shift_rows
// Descripción: Realiza la transformación inversa ShiftRows de AES
//              Desplaza las filas del estado hacia la DERECHA
// Entrada: 
//   x0 = dirección del estado (16 bytes organizados como matriz 4x4)
// 
// Estado (vista por columnas en memoria):
//   Byte:  0  4  8  12
//          1  5  9  13
//          2  6  10 14
//          3  7  11 15
//
// Transformación InvShiftRows:
//   Fila 0: No se desplaza
//   Fila 1: Desplazamiento circular derecha 1 posición
//   Fila 2: Desplazamiento circular derecha 2 posiciones
//   Fila 3: Desplazamiento circular derecha 3 posiciones
//
// Ejemplo:
//   Antes:        Después:
//   a0 a1 a2 a3   a0 a1 a2 a3  (fila 0 sin cambios)
//   b0 b1 b2 b3   b3 b0 b1 b2  (fila 1 rotada derecha 1)
//   c0 c1 c2 c3   c2 c3 c0 c1  (fila 2 rotada derecha 2)
//   d0 d1 d2 d3   d1 d2 d3 d0  (fila 3 rotada derecha 3)
// ============================================================
inv_shift_rows:
    // Guardar registros
    stp x29, x30, [sp, #-16]!
    stp x19, x20, [sp, #-16]!
    stp x21, x22, [sp, #-16]!
    
    mov x19, x0  // x19 = dirección del estado
    
    // ========================================
    // FILA 0: Sin cambios
    // Bytes en posiciones: 0, 4, 8, 12
    // ========================================
    
    // ========================================
    // FILA 1: Rotar derecha 1 posición
    // Bytes en posiciones: 1, 5, 9, 13
    // Antes: [1] [5] [9] [13]
    // Después: [13] [1] [5] [9]
    // ========================================
    ldrb w20, [x19, #1]   // Guardar byte en pos 1
    ldrb w21, [x19, #5]   // Guardar byte en pos 5
    ldrb w22, [x19, #9]   // Guardar byte en pos 9
    ldrb w1, [x19, #13]   // Cargar byte en pos 13
    
    strb w1, [x19, #1]    // pos 13 -> pos 1
    strb w20, [x19, #5]   // pos 1 -> pos 5
    strb w21, [x19, #9]   // pos 5 -> pos 9
    strb w22, [x19, #13]  // pos 9 -> pos 13
    
    // ========================================
    // FILA 2: Rotar derecha 2 posiciones
    // Bytes en posiciones: 2, 6, 10, 14
    // Antes: [2] [6] [10] [14]
    // Después: [10] [14] [2] [6]
    // ========================================
    ldrb w20, [x19, #2]   // Guardar byte en pos 2
    ldrb w21, [x19, #6]   // Guardar byte en pos 6
    ldrb w22, [x19, #10]  // Cargar byte en pos 10
    ldrb w1, [x19, #14]   // Cargar byte en pos 14
    
    strb w22, [x19, #2]   // pos 10 -> pos 2
    strb w1, [x19, #6]    // pos 14 -> pos 6
    strb w20, [x19, #10]  // pos 2 -> pos 10
    strb w21, [x19, #14]  // pos 6 -> pos 14
    
    // ========================================
    // FILA 3: Rotar derecha 3 posiciones
    // Bytes en posiciones: 3, 7, 11, 15
    // Antes: [3] [7] [11] [15]
    // Después: [7] [11] [15] [3]
    // ========================================
    ldrb w20, [x19, #3]   // Guardar byte en pos 3
    ldrb w21, [x19, #7]   // Cargar byte en pos 7
    ldrb w22, [x19, #11]  // Cargar byte en pos 11
    ldrb w1, [x19, #15]   // Cargar byte en pos 15
    
    strb w21, [x19, #3]   // pos 7 -> pos 3
    strb w22, [x19, #7]   // pos 11 -> pos 7
    strb w1, [x19, #11]   // pos 15 -> pos 11
    strb w20, [x19, #15]  // pos 3 -> pos 15
    
    // Restaurar registros
    ldp x21, x22, [sp], #16
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret
    