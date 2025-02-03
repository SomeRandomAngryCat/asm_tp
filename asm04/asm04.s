section .bss
    number resb 10

section .text
    global _start

_start:

    mov rax, 0
    mov rdi, 0
    mov rsi, number
    mov rdx, 10
    syscall

    mov rbx, 0
    mov rdi, number

convert_ascii:
    movzx rax, byte [rdi]
    cmp rax, 10
    je check_parity
    sub rax, '0'
    imul rbx, rbx, 10
    add rbx, rax
    inc rdi
    jmp convert_ascii

check_parity:
    test rbx, 1
    jz return_0

return_1:
    mov rax, 60
    mov rdi, 1
    syscall

return_0:
    mov rax, 60
    xor rdi, rdi
    syscall