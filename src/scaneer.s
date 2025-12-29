.global _start

.bss
password1: .skip 33     
password2: .skip 33     

.data
msg1: .ascii "Ingrese el criptograma: "
len1 = . - msg1
msg2: .ascii "Ingrese la clave: "
len2 = . - msg2
newline: .ascii "\n"
space: .ascii "    "    // 4 espacios entre columnas
estado: .ascii "Matriz estado:\n"
len3 = . - estado

.text
_start:
    // ===== Leer contraseña 1 =====
    mov x0, #1
    ldr x1, =msg1
    mov x2, #len1
    mov x8, #64
    svc #0

    mov x0, #0
    ldr x1, =password1
    mov x2, #33
    mov x8, #63
    svc #0

    // ===== Imprimir contraseña 1 en formato matriz =====
    bl print_estado         
    ldr x19, =password1     
    bl print_matrix   

    mov x0, #1
    ldr x1, =newline
    mov x2, #1
    mov x8, #64
    svc #0

    // ===== Leer contraseña 2 =====
    mov x0, #1
    ldr x1, =msg2
    mov x2, #len2
    mov x8, #64
    svc #0

    mov x0, #0
    ldr x1, =password2
    mov x2, #33
    mov x8, #63
    svc #0      

    // ===== Imprimir contraseña 2 en formato matriz =====
    bl print_estado         
    ldr x19, =password2     
    bl print_matrix

    // ===== Salir =====
    mov x8, #93
    svc #0

// ===== FUNCIÓN: print_matrix =====
print_matrix:
    stp x29, x30, [sp, #-16]!   // GUARDAR x30 (link register)
    stp x20, x21, [sp, #-16]!   // guardar registros que usaremos
    
    mov x20, #0             
    mov x21, #0             

print_loop:
    // Imprimir 2 caracteres
    ldrb w0, [x19, x20]     
    bl print_char
    add x20, x20, #1
    
    ldrb w0, [x19, x20]     
    bl print_char
    add x20, x20, #1
    
    add x21, x21, #1        
    
    // ¿Es la 4ta columna?
    cmp x21, #4
    beq print_newline
    
    // No es fin de fila, imprimir espacios
    mov x0, #1
    ldr x1, =space
    mov x2, #4
    mov x8, #64
    svc #0
    b check_end

print_newline:
    mov x0, #1
    ldr x1, =newline
    mov x2, #1
    mov x8, #64
    svc #0
    mov x21, #0             

check_end:
    cmp x20, #32            
    blt print_loop
    
    ldp x20, x21, [sp], #16     // RESTAURAR registros
    ldp x29, x30, [sp], #16     // RESTAURAR x30
    ret

// ===== FUNCIÓN: print_char =====
print_char:
    stp x29, x30, [sp, #-16]!   // GUARDAR x30
    sub sp, sp, #16             
    strb w0, [sp]           
    
    mov x0, #1              
    mov x1, sp              
    mov x2, #1              
    mov x8, #64             
    svc #0
    
    add sp, sp, #16             
    ldp x29, x30, [sp], #16     // RESTAURAR x30
    ret

print_estado:
    stp x29, x30, [sp, #-16]!   // GUARDAR x30

    mov x0, #1
    ldr x1, =estado
    mov x2, #len3
    mov x8, #64
    svc #0

    ldp x29, x30, [sp], #16     // RESTAURAR x30
    ret
    