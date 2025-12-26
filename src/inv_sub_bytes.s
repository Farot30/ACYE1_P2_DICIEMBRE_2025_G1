// ============================================================
// Función: inv_sub_bytes
// Descripción: Realiza la sustitución inversa de bytes usando la S-Box inversa
// Entrada:
//   x0 = dirección del estado (16 bytes)
// Salida:
//   El estado en x0 se modifica con los bytes sustituidos
// ============================================================
.global inv_sub_bytes
.extern InvSbox


.text
inv_sub_bytes:
    stp x29, x30, [sp, #-16]!
    stp x19, x20, [sp, #-16]!
    stp x21, x22, [sp, #-16]!
    
    mov x19, x0              // x19 = dirección del estado
    ldr x20, =InvSbox        // x20 = dirección de la S-Box inversa
    mov x21, #0              // contador de bytes
    
inv_sub_bytes_loop:
    cmp x21, #16             // procesar 16 bytes
    bge inv_sub_bytes_done
    
    // Cargar byte del estado
    ldrb w22, [x19, x21]
    
    // Usar el byte como índice en la S-Box inversa
    uxtw x22, w22            // extender a 64 bits sin signo
    ldrb w22, [x20, x22]     // buscar en inv_sbox
    
    // Guardar byte sustituido
    strb w22, [x19, x21]
    
    add x21, x21, #1
    b inv_sub_bytes_loop
    
inv_sub_bytes_done:
    ldp x21, x22, [sp], #16
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret
    