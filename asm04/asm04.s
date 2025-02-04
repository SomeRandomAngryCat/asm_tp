section .bss
    buffer: resb 32

section .text
    global _start

_start:

    mov rax, 0
    mov rdi, 0
    lea rsi, [buffer]
    mov rdx, 32
    syscall


    lea rsi, [buffer]
    xor rbx, rbx

parse_loop:
    mov al, byte [rsi]
    cmp al, 10
    je check_parity
    cmp al, '0'
    jl check_parity
    cmp al, '9'
    jg check_parity

    imul rbx, rbx, 10
    sub al, '0'
    movzx rax, al
    add rbx, rax
    inc rsi
    jmp parse_loop

check_parity:
    mov rax, rbx
    and rax, 1
    mov rdi, rax
    mov rax, 60
    syscall
