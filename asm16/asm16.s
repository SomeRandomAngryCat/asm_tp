section .bss
    buffer resb 4096            ; Buffer pour stocker le contenu du fichier

section .text
    global _start

_start:
    ; Vérifier les arguments
    pop rcx                     ; Récupérer argc
    cmp rcx, 2                  ; Vérifier qu'on a un argument
    jl error_args               ; Si moins de 2 arguments, erreur
    
    pop rcx                     ; Ignorer argv[0] (nom du programme)
    pop rdi                     ; Récupérer argv[1] (nom du fichier asm01)
    
    ; Ouvrir le fichier en lecture/écriture
    mov rax, 2                  ; sys_open
    mov rsi, 2                  ; O_RDWR
    xor rdx, rdx                ; Mode (non utilisé pour O_RDWR)
    syscall
    
    ; Vérifier si l'ouverture a réussi
    test rax, rax
    js error_file               ; Si erreur (négatif), sortir avec erreur
    
    ; Sauvegarder le descripteur de fichier
    mov r12, rax
    
    ; Lire le contenu du fichier
    mov rax, 0                  ; sys_read
    mov rdi, r12                ; Descripteur de fichier
    mov rsi, buffer             ; Buffer de destination
    mov rdx, 4096               ; Nombre maximal d'octets à lire
    syscall
    
    ; Vérifier si la lecture a réussi
    test rax, rax
    js error_file               ; Si erreur (négatif), sortir avec erreur
    
    ; Sauvegarder la taille du fichier
    mov r13, rax
    
    ; Parcourir tout le fichier pour trouver et remplacer "1337"
    xor rcx, rcx                ; Initialiser l'index

search_loop:
    cmp rcx, r13                ; Vérifier si on a atteint la fin du fichier
    jge not_found               ; Si oui, chaîne non trouvée
    
    ; Vérifier si on a trouvé '1'
    cmp byte [buffer + rcx], '1'
    jne next_byte
    
    ; Vérifier s'il reste assez d'octets
    mov rax, rcx
    add rax, 4                  ; Vérifier s'il y a assez d'espace pour "1337"
    cmp rax, r13
    jg next_byte
    
    ; Vérifier les caractères suivants
    cmp byte [buffer + rcx + 1], '3'
    jne next_byte
    cmp byte [buffer + rcx + 2], '3'
    jne next_byte
    cmp byte [buffer + rcx + 3], '7'
    jne next_byte
    
    ; Trouvé! Remplacer "1337" par "H4CK"
    mov byte [buffer + rcx], 'H'
    mov byte [buffer + rcx + 1], '4'
    mov byte [buffer + rcx + 2], 'C'
    mov byte [buffer + rcx + 3], 'K'
    
    ; Remettre le curseur au début du fichier
    mov rax, 8                  ; sys_lseek
    mov rdi, r12                ; Descripteur de fichier
    xor rsi, rsi                ; Offset 0
    xor rdx, rdx                ; SEEK_SET (depuis le début)
    syscall
    
    ; Vérifier si lseek a réussi
    test rax, rax
    js error_file
    
    ; Écrire le buffer modifié dans le fichier
    mov rax, 1                  ; sys_write
    mov rdi, r12                ; Descripteur de fichier
    mov rsi, buffer             ; Buffer source
    mov rdx, r13                ; Longueur du fichier
    syscall
    
    ; Vérifier si l'écriture a réussi
    cmp rax, r13
    jne error_file
    
    ; Fermer le fichier
    mov rax, 3                  ; sys_close
    mov rdi, r12                ; Descripteur de fichier
    syscall
    
    ; Sortir avec succès
    mov rax, 60                 ; sys_exit
    xor rdi, rdi                ; Code 0 (succès)
    syscall
    
next_byte:
    inc rcx                     ; Passer au byte suivant
    jmp search_loop

not_found:
    ; Fermer le fichier
    mov rax, 3                  ; sys_close
    mov rdi, r12                ; Descripteur de fichier
    syscall
    
    ; Sortir avec erreur
    mov rax, 60                 ; sys_exit
    mov rdi, 1                  ; Code 1 (erreur)
    syscall
    
error_file:
    ; Erreur lors de l'accès au fichier
    mov rax, 60                 ; sys_exit
    mov rdi, 1                  ; Code 1 (erreur)
    syscall
    
error_args:
    ; Erreur: aucun nom de fichier fourni
    mov rax, 60                 ; sys_exit
    mov rdi, 1                  ; Code 1 (erreur)
    syscall
