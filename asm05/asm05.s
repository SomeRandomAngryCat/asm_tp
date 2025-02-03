section .text
    global _start

_start:
    mov rsi, [rsp + 16]
    test rsi, rsi
    jz exit_0

    mov rdi, rsi
    call string_length

    mov rax, 1
    mov rdi, 1
    syscall

exit_0:
    mov rax, 60
    xor rdi, rdi
    syscall

string_length:
    mov rdx, 0
.loop:
    cmp byte [rdi + rdx], 0
    je .done
    inc rdx
    jmp .loop
.done:
    ret
