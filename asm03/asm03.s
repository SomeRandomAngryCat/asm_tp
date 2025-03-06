section .data
    msg db "1337", 10      ; Message à afficher (1337) suivi d'un saut de ligne
    msg_len equ $ - msg    ; Longueur du message
    
    expected_arg db "42"    ; Valeur attendue en paramètre
    expected_len equ $ - expected_arg ; Longueur de la valeur attendue

section .text
    global _start

_start:
    ; Récupérer le nombre d'arguments
    pop rdi                 ; rdi = argc (nombre d'arguments)
    cmp rdi, 2              ; Vérifier s'il y a exactement 2 arguments (nom du programme + 1 argument)
    jne exit_failure        ; Si non, sortir avec échec
    
    ; Ignorer le nom du programme (premier argument)
    pop rsi                 ; Ignorer argv[0] (nom du programme)
    
    ; Récupérer l'argument à vérifier
    pop rsi                 ; rsi = argv[1] (l'argument à vérifier)
    
    ; Comparer l'argument avec "42"
    mov rdi, expected_arg   ; rdi = "42"
    mov rcx, expected_len   ; rcx = longueur de "42"
    repe cmpsb              ; Comparer les chaînes octet par octet
    jne exit_failure        ; Si différent, sortir avec échec

    ; Afficher "1337" si l'argument est "42"
    mov rax, 1              ; syscall write
    mov rdi, 1              ; stdout
    mov rsi, msg            ; message à afficher
    mov rdx, msg_len        ; longueur du message
    syscall

exit_success:
    ; Retourner 0 (succès)
    mov rax, 60             ; syscall exit
    mov rdi, 0              ; code de retour 0 (succès)
    syscall

exit_failure:
    ; Retourner 1 (échec)
    mov rax, 60             ; syscall exit
    mov rdi, 1              ; code de retour 1 (échec)
    syscall
