section .data
    message db "1337", 10    ; 10 est le code ASCII pour le saut de ligne
    message_len equ $ - message

section .text
    global _start

_start:
    ; Récupérer le nombre d'arguments
    pop rdi         ; Le nombre d'arguments est placé en haut de la pile
    
    ; Vérifier s'il y a au moins un argument (en plus du nom du programme)
    cmp rdi, 2
    jl exit_with_error    ; S'il n'y a pas assez d'arguments, on quitte avec une erreur
    
    ; Récupérer le pointeur vers le premier argument
    pop rdi         ; On retire le nom du programme (argv[0])
    pop rdi         ; Le premier argument est maintenant dans rdi (argv[1])
    
    ; Vérifier si l'argument est "42"
    mov al, [rdi]
    cmp al, '4'
    jne exit_with_error
    
    mov al, [rdi+1]
    cmp al, '2'
    jne exit_with_error
    
    ; Vérifier que la chaîne se termine ici (pas d'autres caractères)
    mov al, [rdi+2]
    test al, al
    jnz exit_with_error
    
    ; Afficher "1337"
    mov rax, 1      ; syscall number pour write
    mov rdi, 1      ; file descriptor: STDOUT
    mov rsi, message
    mov rdx, message_len
    syscall
    
    ; Quitter avec le code de retour 0
    mov rax, 60     ; syscall number pour exit
    xor rdi, rdi    ; code de retour 0
    syscall
    
exit_with_error:
    ; Quitter avec le code de retour 1
    mov rax, 60     ; syscall number pour exit
    mov rdi, 1      ; code de retour 1
    syscall
