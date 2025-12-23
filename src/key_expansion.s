.global key_expansion
.global rot_byte
.global byte_sub

.extern Sbox
.extern Rcon

.section .text

// ============================================================
// Función: key_expansion
// Descripción: Genera las 44 palabras (176 bytes) necesarias
//              para las 11 subclaves de AES-128
// Entrada: 
//   x0 = dirección de la clave original (16 bytes)
//   x1 = dirección del buffer de salida (176 bytes)
// Salida: 
//   Buffer en x1 contendrá las 44 palabras expandidas
// Uso: 
//   W[0-3]   = Clave original (Ronda 0)
//   W[4-7]   = Subclave Ronda 1
//   ...
//   W[40-43] = Subclave Ronda 10
// ============================================================
key_expansion:
    // Guardar registros en el stack
    stp x29, x30, [sp, #-16]!
    stp x19, x20, [sp, #-16]!
    stp x21, x22, [sp, #-16]!
    stp x23, x24, [sp, #-16]!
    stp x25, x26, [sp, #-16]!
    
    mov x19, x0
    mov x20, x1
    
    // ========================================
    // PASO 1: Copiar las primeras 4 palabras
    // W[0] = clave[0-3]
    // W[1] = clave[4-7]
    // W[2] = clave[8-11]
    // W[3] = clave[12-15]
    // ========================================
    mov x21, #0  // contador i = 0
copy_initial:
    cmp x21, #4
    bge expansion_loop_init
    
    // Cargar palabra i de la clave original (32 bits)
    ldr w22, [x19, x21, lsl #2]
    // Guardar en expanded_keys
    str w22, [x20, x21, lsl #2]
    
    add x21, x21, #1
    b copy_initial

    // ========================================
    // PASO 2: Generar palabras W[4] a W[43]
    // ========================================
expansion_loop_init:
    mov x21, #4  // i = 4 (empezamos desde W[4])

expansion_loop:
    cmp x21, #44  // ¿Hemos generado las 44 palabras?
    bge expansion_done
    
    // Cargar W[i-1]
    sub x22, x21, #1
    ldr w23, [x20, x22, lsl #2]  // w23 = W[i-1]
    
    // Verificar si i es múltiplo de 4
    and x24, x21, #3  // x24 = i % 4
    cbnz x24, not_multiple
    
    // ========================================
    // CASO 1: i es múltiplo de 4
    // W[i] = W[i-4] xor [ByteSub(RotByte(W[i-1])) xor Rcon[i/4-1]]
    // ========================================
multiple_of_4:
    // Paso 1: RotByte(W[i-1])
    mov w0, w23
    bl rot_byte
    mov w23, w0  // w23 = RotByte(W[i-1])
    
    // Paso 2: ByteSub(resultado anterior)
    mov w0, w23
    bl byte_sub
    mov w23, w0  // w23 = ByteSub(RotByte(W[i-1]))
    
    // Paso 3: XOR con Rcon[i/4 - 1]
    lsr x24, x21, #2      // x24 = i / 4
    sub x24, x24, #1      // x24 = i/4 - 1
    
    // Cargar Rcon[i/4 - 1]
    adr x25, Rcon
    ldrb w25, [x25, x24]
    
    // XOR solo en el primer byte (LSB de la palabra)
    eor w23, w23, w25
    
    // Paso 4: Cargar W[i-4]
    sub x22, x21, #4
    ldr w24, [x20, x22, lsl #2]  // w24 = W[i-4]
    
    // Paso 5: W[i] = W[i-4] xor resultado
    eor w23, w24, w23
    
    // Guardar W[i]
    str w23, [x20, x21, lsl #2]
    
    add x21, x21, #1
    b expansion_loop

    // ========================================
    // CASO 2: i NO es múltiplo de 4
    // W[i] = W[i-4] xor W[i-1]
    // ========================================
not_multiple:

    sub x22, x21, #4
    ldr w24, [x20, x22, lsl #2]  // w24 = W[i-4]
    
    // W[i] = W[i-4] xor W[i-1]
    eor w23, w24, w23
    
    // Guardar W[i]
    str w23, [x20, x21, lsl #2]
    
    add x21, x21, #1
    b expansion_loop

expansion_done:
    // Restaurar registros del stack
    ldp x25, x26, [sp], #16
    ldp x23, x24, [sp], #16
    ldp x21, x22, [sp], #16
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret

// ============================================================
// Función: rot_byte
// Descripción: Rotación de bytes hacia la izquierda
// Entrada: w0 = palabra de 32 bits [byte0, byte1, byte2, byte3]
// Salida: w0 = [byte1, byte2, byte3, byte0]
// Ejemplo:
//   Entrada:  0x09CF4F3C = [3C, 4F, CF, 09]
//   Salida:   0x3C09CF4F = [4F, CF, 09, 3C]
// ============================================================
rot_byte:
    // ROR (Rotate Right) de 8 bits = ROL (Rotate Left) de 24 bits
    // En ARM64, rotar a la derecha 8 bits equivale a rotar a la izquierda 1 byte
    ror w0, w0, #8
    ret

// ============================================================
// Función: byte_sub
// Descripción: Sustituye cada byte de una palabra usando S-Box
// Entrada: w0 = palabra de 32 bits
// Salida: w0 = palabra con cada byte sustituido
// Nota: Usa la S-Box NORMAL (no la inversa)
// ============================================================
byte_sub:
    // Guardar registros
    stp x29, x30, [sp, #-16]!
    stp x19, x20, [sp, #-16]!
    stp x21, x22, [sp, #-16]!
    
    mov w19, w0       // Guardar palabra original
    adr x20, Sbox     // Cargar dirección de S-Box
    mov w21, #0       // Inicializar resultado
    
    // ========================================
    // Byte 0 (LSB - bits 0-7)
    // ========================================
    and w1, w19, #0xFF       // Extraer byte 0
    uxtw x1, w1              // Extender a 64 bits para indexar
    ldrb w1, [x20, x1]       // Buscar en S-Box
    orr w21, w21, w1         // Insertar en resultado
    
    // ========================================
    // Byte 1 (bits 8-15)
    // ========================================
    lsr w1, w19, #8          // Desplazar para acceder byte 1
    and w1, w1, #0xFF        // Extraer byte 1
    uxtw x1, w1
    ldrb w1, [x20, x1]       // Buscar en S-Box
    lsl w1, w1, #8           // Posicionar en bits 8-15
    orr w21, w21, w1         // Insertar en resultado
    
    // ========================================
    // Byte 2 (bits 16-23)
    // ========================================
    lsr w1, w19, #16         // Desplazar para acceder byte 2
    and w1, w1, #0xFF        // Extraer byte 2
    uxtw x1, w1
    ldrb w1, [x20, x1]       // Buscar en S-Box
    lsl w1, w1, #16          // Posicionar en bits 16-23
    orr w21, w21, w1         // Insertar en resultado
    
    // ========================================
    // Byte 3 (MSB - bits 24-31)
    // ========================================
    lsr w1, w19, #24         // Desplazar para acceder byte 3
    uxtw x1, w1              // No necesita AND porque ya es el byte superior
    ldrb w1, [x20, x1]       // Buscar en S-Box
    lsl w1, w1, #24          // Posicionar en bits 24-31
    orr w21, w21, w1         // Insertar en resultado
    
    // Mover resultado a w0
    mov w0, w21
    
    // Restaurar registros
    ldp x21, x22, [sp], #16
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret
