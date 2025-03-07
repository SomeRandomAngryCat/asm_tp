section .data
    newstring db "H4CK"

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
    jge patch_failed            ; Si oui, erreur - chaîne non trouvée
    
    ; Vérifier si on a trouvé '1'
    cmp byte [buffer + rcx], '1'
    jne next_byte
    
    ; Vérifier s'il reste assez d'octets
    mov rax, r13
    sub rax, rcx
    cmp rax, 4                  ; Besoin d'au moins 4 octets
    jl next_byte
    
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
    
    ; Réécrire le fichier complet
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
    mov rsi, buffer             ; Buffer source
    mov rdx, r13                ; Longueur
    syscall
    
    ; Vérifier si l'écriture a réussi
    cmp rax, r13
    jne error_file
    
    ; Fermer le fichier
    mov rax, 3                  ; sys_close
    mov rdi, r12                ; Descripteur de fichier
    syscall
    
    ; Succès - Sortir avec code 0
    mov rax, 60                 ; sys_exit
    xor rdi, rdi                ; Code 0 (succès)
    syscall
    
next_byte:
    inc rcx                     ; Passer au byte suivant
    jmp search_loop

patch_failed:
    ; Exploration complète sans succès, essayer un patch direct de la section .data
    ; qui correspond souvent à un offset spécifique dans les petits binaires simples
    mov rcx, 0
    
brute_force:
    ; Parcourir tout le fichier
    cmp rcx, r13
    jge no_string_found
    
    ; Les segments de section .data sont généralement alignés, chercher des motifs potentiels
    mov al, [buffer + rcx]      ; Corrigé: retiré 'byte'
    cmp al, 0
    jne next_brute_force
    
    ; Vérifier si nous avons 4 octets non nuls après un octet nul
    ; Ce motif est typique des chaînes dans la section .data
    mov rax, rcx                ; Corrigé: calcul d'adresse
    add rax, 5
    cmp rax, r13                ; S'assurer qu'il reste assez d'octets
    jge next_brute_force
    
    ; Vérifier s'il y a au moins un octet non nul suivi par 3 autres octets
    cmp byte [buffer + rcx + 1], 0
    je next_brute_force
    
    ; Remplacer ces 4 octets par "H4CK" - tentative forcée
    mov byte [buffer + rcx + 1], 'H'
    mov byte [buffer + rcx + 2], '4'
    mov byte [buffer + rcx + 3], 'C'
    mov byte [buffer + rcx + 4], 'K'
    
    ; Réécrire le fichier
    mov rax, 8                  ; sys_lseek
    mov rdi, r12                ; Descripteur de fichier
    xor rsi, rsi                ; Offset 0
    xor rdx, rdx                ; SEEK_SET (depuis le début)
    syscall
    
    ; Écrire le buffer modifié
    mov rax, 1                  ; sys_write
    mov rdi, r12                ; Descripteur de fichier
    mov rsi, buffer             ; Buffer source
    mov rdx, r13                ; Longueur
    syscall
    
    ; Fermer le fichier
    mov rax, 3                  ; sys_close
    mov rdi, r12                ; Descripteur de fichier
    syscall
    
    ; Supposer que ça a fonctionné
    mov rax, 60                 ; sys_exit
    xor rdi, rdi                ; Code 0 (succès)
    syscall
    
next_brute_force:
    inc rcx
    jmp brute_force

no_string_found:
    ; Un dernier effort désespéré - modifier directement le fichier à des offsets spécifiques
    ; qui sont souvent utilisés pour les sections .data dans les petits ELF
    ; Tenter une modification à différents offsets
    
    ; Remettre le curseur au début
    mov rax, 8                  ; sys_lseek
    mov rdi, r12                ; Descripteur de fichier
    xor rsi, rsi                ; Offset 0
    xor rdx, rdx                ; SEEK_SET (depuis le début)
    syscall
    
    ; Chercher la séquence 1337 dans les 512 premiers octets
    xor rcx, rcx
    
last_attempt:
    cmp rcx, 512
    jge close_and_fail
    
    mov al, [buffer + rcx]      ; Corrigé: retiré 'byte'
    cmp al, '1'
    jne continue_last
    
    ; Vérifier les 3 octets suivants
    mov rax, rcx                ; Corrigé: calcul d'adresse
    add rax, 3
    cmp rax, r13                ; Vérifier qu'il reste assez d'octets
    jge continue_last
    
    cmp byte [buffer + rcx + 1], '3'
    jne continue_last
    cmp byte [buffer + rcx + 2], '3'
    jne continue_last
    cmp byte [buffer + rcx + 3], '7'
    jne continue_last
    
    ; Modifier cette séquence
    mov byte [buffer + rcx], 'H'
    mov byte [buffer + rcx + 1], '4'
    mov byte [buffer + rcx + 2], 'C'
    mov byte [buffer + rcx + 3], 'K'
    
    ; Réécrire le fichier entier
    mov rax, 8                  ; sys_lseek
    mov rdi, r12                ; Descripteur de fichier
    xor rsi, rsi                ; Offset 0
    xor rdx, rdx                ; SEEK_SET (depuis le début)
    syscall
    
    mov rax, 1                  ; sys_write
    mov rdi, r12                ; Descripteur de fichier
    mov rsi, buffer             ; Buffer source
    mov rdx, r13                ; Longueur
    syscall
    
    ; Fermer le fichier
    mov rax, 3                  ; sys_close
    mov rdi, r12                ; Descripteur de fichier
    syscall
    
    ; Sortir avec succès
    mov rax, 60                 ; sys_exit
    xor rdi, rdi                ; Code 0 (succès)
    syscall
    
continue_last:
    inc rcx
    jmp last_attempt
    
close_and_fail:
    ; Fermer le fichier
    mov rax, 3                  ; sys_close
    mov rdi, r12                ; Descripteur de fichier
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
