section .data
    new_string db "H4CK", 0     ; Nouvelle chaîne à insérer

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
    
    ; Ouvrir le fichier en lecture/écriture
    mov rax, 2                  ; sys_open
    ; rdi contient déjà le nom du fichier
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
    mov [file_size], rax
    
    ; Chercher "1337" dans le contenu du fichier
    xor r13, r13                ; Index de recherche
    
find_pattern:
    ; Vérifier si on a atteint la fin du fichier
    cmp r13, [file_size]
    jge not_found               ; Si fin du fichier, pattern non trouvé
    
    ; Vérifier s'il reste assez d'octets pour le pattern
    mov rax, [file_size]
    sub rax, r13
    cmp rax, 4                  ; Besoin d'au moins 4 octets
    jl next_index
    
    ; Vérifier si on a trouvé "1337"
    cmp byte [buffer + r13], '1'
    jne next_index
    cmp byte [buffer + r13 + 1], '3'
    jne next_index
    cmp byte [buffer + r13 + 2], '3'
    jne next_index
    cmp byte [buffer + r13 + 3], '7'
    jne next_index
    
    ; Pattern trouvé, remplacer par "H4CK"
    mov byte [buffer + r13], 'H'
    mov byte [buffer + r13 + 1], '4'
    mov byte [buffer + r13 + 2], 'C'
    mov byte [buffer + r13 + 3], 'K'
    jmp pattern_found
    
next_index:
    ; Passer au caractère suivant
    inc r13
    jmp find_pattern
    
pattern_found:
    ; Remettre le curseur au début du fichier
    mov rax, 8                  ; sys_lseek
    mov rdi, r12                ; Descripteur de fichier
    xor rsi, rsi                ; Offset 0
    xor rdx, rdx                ; SEEK_SET
    syscall
    
    ; Vérifier si le repositionnement a réussi
    test rax, rax
    js error_file
    
    ; Écrire le contenu modifié
    mov rax, 1                  ; sys_write
    mov rdi, r12                ; Descripteur de fichier
    mov rsi, buffer             ; Contenu modifié
    mov rdx, [file_size]        ; Taille du fichier
    syscall
    
    ; Vérifier si l'écriture a réussi
    test rax, rax
    js error_file
    
    ; Fermer le fichier
    mov rax, 3                  ; sys_close
    mov rdi, r12                ; Descripteur de fichier
    syscall
    
    ; Sortir avec succès
    mov rax, 60                 ; sys_exit
    xor rdi, rdi                ; Code 0 (succès)
    syscall
    
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
