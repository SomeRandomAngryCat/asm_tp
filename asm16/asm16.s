section .data
    new_string db "H4CK", 0      ; Nouvelle chaîne à insérer

section .bss
    buffer resb 4096             ; Buffer pour stocker le contenu du fichier

section .text
    global _start

_start:
    ; Vérifier si un nom de fichier a été fourni
    pop rcx                     ; Récupérer argc
    cmp rcx, 2                  ; Vérifier qu'on a un argument
    jl error_args               ; Si moins de 2 arguments, erreur
    
    pop rdi                     ; Ignorer argv[0] (nom du programme)
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
    
    ; Stocker la taille du fichier
    mov r13, rax
    
    ; Chercher la chaîne "1337" dans le buffer
    mov rcx, 0                  ; Initialiser l'index
    
search_loop:
    ; Vérifier si on est arrivé à la fin du buffer
    cmp rcx, r13
    jge not_found               ; Si fin du buffer, chaîne non trouvée
    
    ; Vérifier le premier caractère ('1')
    mov al, byte [buffer + rcx]
    cmp al, '1'
    jne next_char

    ; Vérifier s'il reste assez d'espace pour "337"
    mov rdx, r13
    sub rdx, rcx
    cmp rdx, 4                  ; On a besoin d'au moins 4 octets
    jl next_char
    
    ; Vérifier les 3 caractères suivants
    cmp byte [buffer + rcx + 1], '3'
    jne next_char
    cmp byte [buffer + rcx + 2], '3'
    jne next_char
    cmp byte [buffer + rcx + 3], '7'
    jne next_char
    
    ; Trouvé! Remplacer la chaîne
    mov byte [buffer + rcx], 'H'
    mov byte [buffer + rcx + 1], '4'
    mov byte [buffer + rcx + 2], 'C'
    mov byte [buffer + rcx + 3], 'K'
    
    ; Écrire le buffer modifié dans le fichier
    mov rax, 8                  ; sys_lseek
    mov rdi, r12                ; Descripteur de fichier
    xor rsi, rsi                ; Offset 0
    xor rdx, rdx                ; SEEK_SET (depuis le début)
    syscall
    
    ; Vérifier si lseek a réussi
    test rax, rax
    js error_file
    
    ; Écrire le buffer modifié
    mov rax, 1                  ; sys_write
    mov rdi, r12                ; Descripteur de fichier
    mov rsi, buffer             ; Buffer modifié
    mov rdx, r13                ; Taille du fichier
    syscall
    
    ; Vérifier si l'écriture a réussi
    cmp rax, r13
    jne error_file
    
    ; Fermer le fichier
    mov rax, 3                  ; sys_close
    mov rdi, r12                ; Descripteur de fichier
    syscall
    
    ; Succès
    mov rax, 60                 ; sys_exit
    xor rdi, rdi                ; Code 0 (succès)
    syscall
    
next_char:
    inc rcx                     ; Passer au caractère suivant
    jmp search_loop
    
not_found:
    ; Si la chaîne n'est pas trouvée, fermer le fichier et sortir avec erreur
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
