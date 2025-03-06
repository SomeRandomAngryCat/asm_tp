section .data
    msg db "1337", 10      ; Message à afficher (1337) suivi d'un saut de ligne
    msg_len equ $ - msg    ; Longueur du message
    
    input_val db "42"      ; Valeur attendue en entrée
    input_len equ $ - input_val ; Longueur de la valeur attendue

section .bss
    buffer resb 16         ; Buffer pour stocker l'entrée utilisateur

section .text
    global _start

_start:
    ; Lire l'entrée utilisateur
    mov rax, 0          ; syscall read
    mov rdi, 0          ; stdin
    mov rsi, buffer     ; buffer où stocker l'entrée
    mov rdx, 16         ; taille maximale à lire
    syscall

    ; Vérifier si l'entrée est valide
    cmp rax, input_len  ; Comparer la longueur lue avec la longueur attendue
    jne exit_failure    ; Si différent, sortir avec échec

    ; Comparer l'entrée avec "42"
    mov rcx, input_len
    mov rsi, buffer
    mov rdi, input_val
    repe cmpsb          ; Comparer les chaînes octet par octet
    jne exit_failure    ; Si différent, sortir avec échec

    ; Afficher "1337" si l'entrée est "42"
    mov rax, 1          ; syscall write
    mov rdi, 1          ; stdout
    mov rsi, msg        ; message à afficher
    mov rdx, msg_len    ; longueur du message
    syscall

exit_success:
    ; Retourner 0 (succès)
    mov rax, 60         ; syscall exit
    mov rdi, 0          ; code de retour 0 (succès)
    syscall

exit_failure:
    ; Retourner 1 (échec)
    mov rax, 60         ; syscall exit
    mov rdi, 1          ; code de retour 1 (échec)
    syscall