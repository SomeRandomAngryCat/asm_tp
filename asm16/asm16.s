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
    xor rdx, rdx
    syscall
    
    ; Vérifier si l'ouverture a réussi
    test rax, rax
    js error_file
    
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
    js error_file
    
    ; Sauvegarder la taille du fichier
    mov r13, rax
    
    ; Remplacer toutes les occurrences de "1337" par "H4CK"
    xor rcx, rcx                ; Index de recherche
    
search_loop:
    ; Vérifier si on a atteint la fin du fichier
    cmp rcx, r13
    jge no_more_replacements
    
    ; Vérifier si nous avons trouvé un '1'
    cmp byte [buffer + rcx], '1'
    jne next_char
    
    ; Vérifier s'il reste assez d'octets pour "337"
    mov rax, rcx
    add rax, 4                  ; 1 (déjà trouvé) + 3 pour "337"
    cmp rax, r13
    jg next_char
    
    ; Vérifier les 3 caractères suivants
    cmp byte [buffer + rcx + 1], '3'
    jne next_char
    cmp byte [buffer + rcx + 2], '3'
    jne next_char
    cmp byte [buffer + rcx + 3], '7'
    jne next_char
    
    ; Trouvé! Remplacer par "H4CK"
    mov byte [buffer + rcx], 'H'
    mov byte [buffer + rcx + 1], '4'
    mov byte [buffer + rcx + 2], 'C'
    mov byte [buffer + rcx + 3], 'K'
    
    ; Passer aux 4 caractères suivants
    add rcx, 4
    jmp search_loop
    
next_char:
    ; Passer au caractère suivant
    inc rcx
    jmp search_loop
    
no_more_replacements:
    ; Repositionner le curseur de fichier au début
    mov rax, 8                  ; sys_lseek
    mov rdi, r12                ; descripteur de fichier
    xor rsi, rsi                ; offset 0
    xor rdx, rdx                ; SEEK_SET (depuis le début)
    syscall
    
    ; Vérifier si lseek a réussi
    test rax, rax
    js error_file
    
    ; Écrire le buffer modifié
    mov rax, 1                  ; sys_write
    mov rdi, r12                ; descripteur de fichier
    mov rsi, buffer             ; buffer source
    mov rdx, r13                ; longueur
    syscall
    
    ; Vérifier si l'écriture a réussi
    cmp rax, r13
    jne error_file
    
    ; Fermer le fichier
    mov rax, 3                  ; sys_close
    mov rdi, r12                ; descripteur de fichier
    syscall
    
    ; Sortir avec succès
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
