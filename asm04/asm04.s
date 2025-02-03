section .text
    global _start

_start:
    mov rdi, [rsp]
    cmp rdi, 2
    jne exit_1
    
    mov rsi, [rsp+16]
    call validate_number
    cmp rax, 0
    jne exit_2
    
    mov rax, [rsi]
    cmp word [rsi], 0x3234
    jne exit_1
    cmp byte [rsi+2], 0
    jne exit_1
    
    mov rax, 1
    mov rdi, 1
    mov rsi, msg
    mov rdx, msg_len
    syscall
    
    xor rdi, rdi
    jmp exit

validate_number:
    mov rcx, 0
check_loop:
    mov al, [rsi+rcx]
    test al, al
    jz valid
    cmp al, '0'
    jb invalid_input
    cmp al, '9'
    ja invalid_input
    inc rcx
    jmp check_loop
invalid_input:
    mov rax, 1
    jmp exit_2
valid:
    xor rax, rax
    ret

exit_2:
    mov rdi, 2
    jmp exit

exit_1:
    mov rdi, 1
    
exit:
    mov rax, 60
    syscall

section .data
    msg db "1337\n"
    msg_len equ $ - msg
