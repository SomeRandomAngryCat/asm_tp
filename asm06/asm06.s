section .bss
outbuf: resb 32

section .text
global _start

_start:
    mov rax, [rsp]
    cmp rax, 3
    jne error_exit
    mov rdi, [rsp+16]
    call convert
    mov r8, rax
    mov rdi, [rsp+24]
    call convert
    add rax, r8
    mov rbx, rax
    cmp rbx, 0
    jne convert_to_ascii
    mov byte [outbuf], '0'
    mov rsi, outbuf
    mov rdx, 1
    jmp write_result

convert_to_ascii:
    mov r8, 10
    lea rsi, [outbuf+32]
    xor rcx, rcx
.convert_loop:
    xor rdx, rdx
    mov rax, rbx
    div r8
    add rdx, '0'
    dec rsi
    mov byte [rsi], dl
    inc rcx
    mov rbx, rax
    cmp rax, 0
    jne .convert_loop
    mov rdx, rcx

write_result:
    mov rax, 1
    mov rdi, 1
    syscall
    mov rax, 60
    xor rdi, rdi
    syscall

error_exit:
    mov rax, 60
    mov rdi, 1
    syscall

convert:
    xor rax, rax
.convert_loop_atoi:
    mov bl, byte [rdi]
    cmp bl, 0
    je .done
    cmp bl, '0'
    jb .done
    cmp bl, '9'
    ja .done
    imul rax, rax, 10
    sub bl, '0'
    movzx rdx, bl
    add rax, rdx
    inc rdi
    jmp .convert_loop_atoi
.done:
    ret
