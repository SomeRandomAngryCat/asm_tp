section .text
global _start

_start:
    mov rax, [rsp]
    cmp rax, 2
    jb no_param
    mov rsi, [rsp+16]
    mov rbx, rsi
    xor rcx, rcx
.loop:
    mov al, byte [rsi+rcx]
    cmp al, 0
    je print
    inc rcx
    jmp .loop
print:
    mov rax, 1
    mov rdi, 1
    mov rsi, rbx
    mov rdx, rcx
    syscall
    mov rax, 60
    xor rdi, rdi
    syscall
no_param:
    mov rax, 60
    mov rdi, 1
    syscall
