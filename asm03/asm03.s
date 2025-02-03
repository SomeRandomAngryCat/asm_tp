section .text
    global _start

_start:
    ; Vérifier le nombre d'arguments (argc)
    mov rdi, [rsp]
    cmp rdi, 2
    jne exit_1

    mov rsi, [rsp+8]
    mov rsi, [rsp+16]
    mov rax, [rsi]
    cmp word [rsi], 0x3234
    jne exit_1
    cmp byte [rsi+2], 0
    jne exit_1


    ; Afficher "1337\n"
    mov rax, 1        ; sys_write
    mov rdi, 1        ; stdout
    mov rsi, msg
    mov rdx, msg_len
    syscall

    xor rdi, rdi
    jmp exit

exit_1:
    mov rdi, 1

exit:
    mov rax, 60
    syscall

section .data
    msg db "1337\n"
    msg_len equ $ - msg