section .bss
    input resb 3   ; Réserver 3 octets pour l'entrée ("42\n")

section .text
    global _start

_start:
    ; Lire l'entrée standard
    mov rax, 0        ; sys_read
    mov rdi, 0        ; stdin
    mov rsi, input    ; buffer
    mov rdx, 3        ; taille
    syscall
    
    ; Comparer avec "42\n"
    mov rax, [input]
    cmp word [input], 0x3234  ; Vérifie si "42"
    jne exit_1
    cmp byte [input+2], 0x0A  ; Vérifie si "\n"
    jne exit_1
    
    ; Afficher "1337\n"
    mov rax, 1        ; sys_write
    mov rdi, 1        ; stdout
    mov rsi, msg
    mov rdx, msg_len
    syscall
    
    ; Retourner 0
    xor rdi, rdi
    jmp exit

exit_1:
    mov rdi, 1   ; Code de retour 1
    
exit:
    mov rax, 60  ; sys_exit
    syscall

section .data
    msg db "1337\n"
    msg_len equ $ - msg
