section .text
global _start

_start:
    mov rax, 60      ; numéro de l'appel système exit
    xor rdi, rdi     ; rdi = 0, c'est la valeur de retour du programme
    syscall          ; appel système
