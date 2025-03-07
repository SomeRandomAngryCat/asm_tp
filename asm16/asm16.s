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
    
    ; Chercher "1337" dans le contenu du fichier (en tenant compte des formats possibles)
    xor r13, r13                ; Index de recherche
    mov r14, [file_size]        ; Taille du fichier
    
find_pattern:
    ; Vérifier si on a atteint la fin du fichier
    cmp r13, r14
    jge not_found               ; Si fin du fichier, pattern non trouvé
    
    ; Vérifier si nous avons trouvé la chaîne potentielle
    ; Plusieurs possibilités de stockage: ASCII direct, Unicode, etc.
    
    ; Vérifier le format ASCII direct "1337"
    cmp byte [buffer + r13], '1'
    jne check_next_format1
    cmp byte [buffer + r13 + 1], '3'
    jne check_next_format1
    cmp byte [buffer + r13 + 2], '3'
    jne check_next_format1
    cmp byte [buffer + r13 + 3], '7'
    jne check_next_format1
    
    ; Trouvé en ASCII, remplacer par "H4CK"
    mov byte [buffer + r13], 'H'
    mov byte [buffer + r13 + 1], '4'
    mov byte [buffer + r13 + 2], 'C'
    mov byte [buffer + r13 + 3], 'K'
    jmp pattern_found
    
check_next_format1:
    ; Vérifier le format ASCII avec caractère nul entre chaque caractère (UTF-16LE)
    cmp r13, r14
    ja next_index
    cmp byte [buffer + r13], '1'
    jne check_next_format2
    cmp r13 + 2, r14
    ja next_index
    cmp byte [buffer + r13 + 2], '3'
    jne check_next_format2
    cmp r13 + 4, r14
    ja next_index
    cmp byte [buffer + r13 + 4], '3'
    jne check_next_format2
    cmp r13 + 6, r14
    ja next_index
    cmp byte [buffer + r13 + 6], '7'
    jne check_next_format2
    
    ; Trouvé en UTF-16LE, remplacer par "H4CK"
    mov byte [buffer + r13], 'H'
    mov byte [buffer + r13 + 2], '4'
    mov byte [buffer + r13 + 4], 'C'
    mov byte [buffer + r13 + 6], 'K'
    jmp pattern_found
    
check_next_format2:
    ; Vérifier le format hexadécimal possible (31 33 33 37)
    cmp byte [buffer + r13], 0x31
    jne next_index
    cmp byte [buffer + r13 + 1], 0x33
    jne next_index
    cmp byte [buffer + r13 + 2], 0x33
    jne next_index
    cmp byte [buffer + r13 + 3], 0x37
    jne next_index
    
    ; Trouvé en hexadécimal, remplacer par "H4CK"
    mov byte [buffer + r13], 0x48   ; 'H'
    mov byte [buffer + r13 + 1], 0x34   ; '4'
    mov byte [buffer + r13 + 2], 0x43   ; 'C'
    mov byte [buffer + r13 + 3], 0x4B   ; 'K'
    jmp pattern_found
    
next_index:
    ; Passer au caractère suivant
    inc r13
    jmp find_pattern
    
pattern_found:
    ; Repositionner le curseur au début du fichier
    mov rax, 8                  ; sys_lseek
    mov rdi, r12                ; Descripteur de fichier
    xor rsi, rsi                ; Offset 0
    xor rdx, rdx                ; SEEK_SET (depuis le début)
    syscall
    
    ; Écrire le contenu modifié
    mov rax, 1                  ; sys_write
    mov rdi, r12                ; Descripteur de fichier
    mov rsi, buffer             ; Contenu modifié
    mov rdx, [file_size]        ; Taille du fichier
    syscall
    
    ; Vérifier si l'écriture a réussi
    cmp rax, [file_size]
    jne error_file              ; Si on n'a pas écrit tous les octets, erreur
    
    ; Fermer le fichier
    mov rax, 3                  ; sys_close
    mov rdi, r12                ; Descripteur de fichier
    syscall
    
    ; Succès, sortir avec code 0
    mov rax, 60                 ; sys_exit
    xor rdi, rdi                ; code 0 (succès)
    syscall
    
not_found:
    ; Fermer le fichier si ouvert
    mov rax, 3                  ; sys_close
    mov rdi, r12                ; Descripteur de fichier
    syscall
    
    ; Pattern non trouvé, sortir avec erreur
    mov rax, 60                 ; sys_exit
    mov rdi, 1                  ; code 1 (erreur)
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