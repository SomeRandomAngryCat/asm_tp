section .data
    new_string db "H4CK", 10    ; Nouvelle chaîne à insérer (avec saut de ligne)
    new_len equ $ - new_string  ; Longueur de la nouvelle chaîne

section .bss
    buffer resb 4096            ; Buffer pour stocker le contenu du fichier
    file_size resq 1            ; Variable pour stocker la taille du fichier

section .text
    global _start

_start:
    ; Vérifier si un nom de fichier a été fourni
    pop rcx                     ; Récupérer argc
    cmp rcx, 2                  ; Vérifier qu'on a un argument (programme + fichier)
    jl error_args               ; Si moins de 2 arguments, erreur
    
    pop rdi                     ; Ignorer argv[0] (nom du programme)
    pop rdi                     ; Récupérer argv[1] (nom du fichier asm01)
    
    ; Sauvegarder le nom du fichier
    mov r15, rdi                ; Garder le nom du fichier dans r15
    
    ; Ouvrir le fichier en lecture
    mov rax, 2                  ; sys_open
    ; rdi contient déjà le nom du fichier
    mov rsi, 0                  ; O_RDONLY
    xor rdx, rdx                ; Mode (non utilisé pour O_RDONLY)
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
    mov [file_size], rax
    
    ; Fermer le fichier
    mov rax, 3                  ; sys_close
    mov rdi, r12                ; Descripteur de fichier
    syscall
    
    ; Chercher "1337" dans le contenu du fichier
    mov rsi, buffer             ; Pointeur vers le contenu du fichier
    mov rcx, [file_size]        ; Taille du fichier
    
find_pattern:
    ; Vérifier si on a atteint la fin du fichier
    test rcx, rcx
    jz not_found                ; Si fin du fichier, pattern non trouvé
    
    ; Vérifier le premier caractère
    cmp byte [rsi], '1'
    jne next_char
    
    ; Vérifier si on a assez de caractères restants
    cmp rcx, 4                  ; Besoin d'au moins 4 caractères ("1337")
    jl next_char
    
    ; Vérifier les caractères suivants
    cmp byte [rsi+1], '3'
    jne next_char
    cmp byte [rsi+2], '3'
    jne next_char
    cmp byte [rsi+3], '7'
    jne next_char
    
    ; Pattern trouvé, remplacer par "H4CK"
    mov byte [rsi], 'H'
    mov byte [rsi+1], '4'
    mov byte [rsi+2], 'C'
    mov byte [rsi+3], 'K'
    
    ; Sauter à l'étape d'écriture du fichier modifié
    jmp write_file
    
next_char:
    ; Passer au caractère suivant
    inc rsi
    dec rcx
    jmp find_pattern
    
not_found:
    ; Pattern non trouvé, sortir avec erreur
    mov rax, 60                 ; sys_exit
    mov rdi, 1                  ; code 1 (erreur)
    syscall
    
write_file:
    ; Ouvrir le fichier en écriture
    mov rax, 2                  ; sys_open
    mov rdi, r15                ; Nom du fichier (sauvegardé dans r15)
    mov rsi, 0102o              ; O_WRONLY | O_CREAT
    mov rdx, 0755o              ; Permissions (rwxr-xr-x)
    syscall
    
    ; Vérifier si l'ouverture a réussi
    test rax, rax
    js error_file               ; Si erreur (négatif), sortir avec erreur
    
    ; Sauvegarder le descripteur de fichier
    mov r12, rax
    
    ; Écrire le contenu modifié
    mov rax, 1                  ; sys_write
    mov rdi, r12                ; Descripteur de fichier
    mov rsi, buffer             ; Contenu modifié
    mov rdx, [file_size]        ; Taille du fichier
    syscall
    
    ; Vérifier si l'écriture a réussi
    test rax, rax
    js error_file               ; Si erreur (négatif), sortir avec erreur
    
    ; Fermer le fichier
    mov rax, 3                  ; sys_close
    mov rdi, r12                ; Descripteur de fichier
    syscall
    
    ; Succès, sortir avec code 0
    mov rax, 60                 ; sys_exit
    xor rdi, rdi                ; code 0 (succès)
    syscall
    
error_file:
    ; Erreur lors de l'accès au fichier
    mov rax, 60                 ; sys_exit
    mov rdi, 1                  ; code 1 (erreur)
    syscall
    
error_args:
    ; Erreur: aucun nom de fichier fourni
    mov rax, 60                 ; sys_exit
    mov rdi, 1                  ; code 1 (erreur)
    syscall