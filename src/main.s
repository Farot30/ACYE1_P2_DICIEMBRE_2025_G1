.global _start
.extern itoa

.data
msg: .asciz "Bienvenidos a mi mundo!\n"
len: .word . - msg

.text
_start:
    mov x0, #1              // file descriptor (stdout)
    ldr x1, =msg            // pointer to message
    ldr x2, =len            // length of message
    ldr w2, [x2]
    mov x8, #64             // syscall: write
    svc 0

    mov x8, #93             // syscall: exit
    mov x0, #0              
    svc 0
