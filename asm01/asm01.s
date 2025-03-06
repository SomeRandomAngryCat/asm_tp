section .data
    message db "1337"           ; La chaîne à afficher
    message_len equ $ - message ; Calcul de la longueur de la chaîne

section .text
global _start

_start:
    ; Appel système write: écrire la chaîne sur stdout
    mov rax, 1          ; numéro de l'appel système write (1)
    mov rdi, 1          ; fd = 1 (stdout)
    mov rsi, message    ; adresse du message
    mov rdx, message_len; longueur du message
    syscall

    ; Appel système exit: terminer le programme avec un code de retour 0
    mov rax, 60         ; numéro de l'appel système exit (60)
    xor rdi, rdi        ; rdi = 0 (code de sortie)
    syscall