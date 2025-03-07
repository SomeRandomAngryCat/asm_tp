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
    mov rdx, 0644o              ; Mode
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
    
    ; Parcourir tout le fichier et chercher toutes les occurrences possibles
    mov r13, 0                  ; Index de recherche
    mov r14, 0                  ; Compteur de remplacements
    
search_loop:
    ; Vérifier si nous avons atteint la fin du fichier
    cmp r13, [file_size]
    jge search_done
    
    ; Vérifier s'il reste assez d'octets (au moins 4)
    mov rax, [file_size]
    sub rax, r13
    cmp rax, 4
    jl next_byte
    
    ; Chercher toutes les possibles combinaisons de caractères qui ressemblent à "1337"
    ; Format 1: ASCII "1337"
    cmp byte [buffer + r13], '1'
    jne try_format2
    cmp byte [buffer + r13 + 1], '3'
    jne try_format2
    cmp byte [buffer + r13 + 2], '3'
    jne try_format2
    cmp byte [buffer + r13 + 3], '7'
    jne try_format2
    
    ; Remplacer par "H4CK"
    mov byte [buffer + r13], 'H'
    mov byte [buffer + r13 + 1], '4'
    mov byte [buffer + r13 + 2], 'C'
    mov byte [buffer + r13 + 3], 'K'
    inc r14                     ; Incrémenter compteur de remplacements
    add r13, 4                  ; Sauter ces 4 octets
    jmp search_loop
    
try_format2:
    ; Format 2: Octets 0x31 0x33 0x33 0x37 (représentation hexadécimale de "1337")
    cmp byte [buffer + r13], 0x31
    jne try_format3
    cmp byte [buffer + r13 + 1], 0x33
    jne try_format3
    cmp byte [buffer + r13 + 2], 0x33
    jne try_format3
    cmp byte [buffer + r13 + 3], 0x37
    jne try_format3
    
    ; Remplacer par "H4CK" en hexa
    mov byte [buffer + r13], 0x48
    mov byte [buffer + r13 + 1], 0x34
    mov byte [buffer + r13 + 2], 0x43
    mov byte [buffer + r13 + 3], 0x4B
    inc r14                     ; Incrémenter compteur de remplacements
    add r13, 4                  ; Sauter ces 4 octets
    jmp search_loop
    
try_format3:
    ; Format 3: Chercher toute séquence de 4 octets qui pourrait former "1337"
    ; Premier octet = '1' (0x31)
    cmp byte [buffer + r13], 0x31
    je check_for_337
    
    ; Premier octet différent, passer au suivant
    jmp next_byte
    
check_for_337:
    ; Chercher les 3 octets suivants formant "337" dans les 20 prochains octets
    mov r15, 1                  ; Offset depuis la position actuelle
    mov rbx, 20                 ; Limiter la recherche aux 20 prochains octets
    
check_337_loop:
    ; Vérifier si on a dépassé la limite
    cmp r15, rbx
    jge next_byte
    
    ; Vérifier si on a dépassé la fin du fichier
    mov rax, r13
    add rax, r15
    add rax, 2                  ; Besoin de 3 octets pour "337"
    cmp rax, [file_size]
    jge next_byte
    
    ; Vérifier si on trouve "337"
    cmp byte [buffer + r13 + r15], '3'
    jne next_337_offset
    cmp byte [buffer + r13 + r15 + 1], '3'
    jne next_337_offset
    cmp byte [buffer + r13 + r15 + 2], '7'
    jne next_337_offset
    
    ; Trouvé! Remplacer "1" par "H" et "337" par "4CK"
    mov byte [buffer + r13], 'H'
    mov byte [buffer + r13 + r15], '4'
    mov byte [buffer + r13 + r15 + 1], 'C'
    mov byte [buffer + r13 + r15 + 2], 'K'
    inc r14                     ; Incrémenter compteur de remplacements
    add r13, r15
    add r13, 3
    jmp search_loop
    
next_337_offset:
    inc r15
    jmp check_337_loop
    
next_byte:
    inc r13
    jmp search_loop
    
search_done:
    ; Si aucun remplacement n'a été fait, c'est une erreur
    test r14, r14
    jz not_found
    
    ; Repositionner le curseur au début du fichier
    mov rax, 8                  ; sys_lseek
    mov rdi, r12                ; Descripteur de fichier
    xor rsi, rsi                ; Offset 0
    xor rdx, rdx                ; SEEK_SET (depuis le début)
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
    cmp rax, [file_size]
    jne error_file
    
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
    
    ; Pattern non trouvé, sortir avec erreur
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
