section .data
    message db "Hello Universe!", 10  ; Message à écrire avec saut de ligne
    message_len equ $ - message       ; Longueur du message

section .text
    global _start

_start:
    ; Vérifier si un nom de fichier a été fourni
    pop rcx                      ; Récupérer argc
    cmp rcx, 2                   ; Vérifier que nous avons un argument (prog + filename)
    jl error                     ; Si moins de 2 arguments, erreur
    
    pop rdi                      ; Ignorer argv[0] (nom du programme)
    pop rdi                      ; Récupérer argv[1] (nom du fichier)
    
    ; Ouvrir/créer le fichier
    mov rax, 2                   ; sys_open
    ; rdi contient déjà le nom du fichier
    mov rsi, 0102o               ; O_CREAT | O_WRONLY
    mov rdx, 0666o               ; Permissions (rw-rw-rw-)
    syscall
    
    ; Vérifier si l'ouverture a réussi
    test rax, rax
    js error                     ; Si erreur (négatif), sortir avec erreur
    
    ; Sauvegarder le descripteur de fichier
    mov r12, rax
    
    ; Écrire dans le fichier
    mov rax, 1                   ; sys_write
    mov rdi, r12                 ; Descripteur de fichier
    mov rsi, message             ; Message à écrire
    mov rdx, message_len         ; Longueur du message
    syscall
    
    ; Vérifier si l'écriture a réussi
    test rax, rax
    js error                     ; Si erreur (négatif), sortir avec erreur
    
    ; Fermer le fichier
    mov rax, 3                   ; sys_close
    mov rdi, r12                 ; Descripteur de fichier
    syscall
    
    ; Terminer avec succès
    mov rax, 60                  ; sys_exit
    xor rdi, rdi                 ; Code 0 (succès)
    syscall
    
error:
    ; Terminer avec erreur
    mov rax, 60                  ; sys_exit
    mov rdi, 1                   ; Code 1 (erreur)
    syscall