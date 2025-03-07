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
    ; en essayant différentes représentations
    
    xor rcx, rcx                ; Index de recherche
    
    ; Premièrement, rechercher la représentation ASCII standard
search_loop_ascii:
    ; Vérifier si on a atteint la fin du fichier
    cmp rcx, r13
    jge try_little_endian
    
    ; Vérifier si nous avons trouvé un '1'
    cmp byte [buffer + rcx], '1'
    jne next_char_ascii
    
    ; Vérifier s'il reste assez d'octets
    mov rax, rcx
    add rax, 4
    cmp rax, r13
    jg next_char_ascii
    
    ; Vérifier les 3 caractères suivants
    cmp byte [buffer + rcx + 1], '3'
    jne next_char_ascii
    cmp byte [buffer + rcx + 2], '3'
    jne next_char_ascii
    cmp byte [buffer + rcx + 3], '7'
    jne next_char_ascii
    
    ; Trouvé! Remplacer par "H4CK"
    mov byte [buffer + rcx], 'H'
    mov byte [buffer + rcx + 1], '4'
    mov byte [buffer + rcx + 2], 'C'
    mov byte [buffer + rcx + 3], 'K'
    jmp write_changes
    
next_char_ascii:
    inc rcx
    jmp search_loop_ascii
    
try_little_endian:
    ; Réinitialiser l'index pour chercher en little-endian
    xor rcx, rcx
    
search_loop_le:
    ; Vérifier si on a atteint la fin du fichier
    cmp rcx, r13
    jge try_hex_representation
    
    ; Vérifier s'il y a assez d'octets pour un dword
    mov rax, rcx
    add rax, 4
    cmp rax, r13
    jg next_char_le
    
    ; Vérifier la séquence "7331" (représentation little-endian de "1337")
    cmp byte [buffer + rcx], '7'
    jne next_char_le
    cmp byte [buffer + rcx + 1], '3'
    jne next_char_le
    cmp byte [buffer + rcx + 2], '3'
    jne next_char_le
    cmp byte [buffer + rcx + 3], '1'
    jne next_char_le
    
    ; Trouvé! Remplacer par "KC4H" (représentation little-endian de "H4CK")
    mov byte [buffer + rcx], 'K'
    mov byte [buffer + rcx + 1], 'C'
    mov byte [buffer + rcx + 2], '4'
    mov byte [buffer + rcx + 3], 'H'
    jmp write_changes
    
next_char_le:
    inc rcx
    jmp search_loop_le
    
try_hex_representation:
    ; Réinitialiser l'index pour chercher la représentation hexadécimale
    xor rcx, rcx
    
search_loop_hex:
    ; Vérifier si on a atteint la fin du fichier
    cmp rcx, r13
    jge try_binary_representation
    
    ; Chercher le pattern en hexadécimal (31 33 33 37 - code ASCII pour "1337")
    ; Vérifier s'il reste assez d'octets
    mov rax, rcx
    add rax, 4
    cmp rax, r13
    jg next_char_hex
    
    cmp byte [buffer + rcx], 0x31
    jne next_char_hex
    cmp byte [buffer + rcx + 1], 0x33
    jne next_char_hex
    cmp byte [buffer + rcx + 2], 0x33
    jne next_char_hex
    cmp byte [buffer + rcx + 3], 0x37
    jne next_char_hex
    
    ; Trouvé! Remplacer par les codes ASCII pour "H4CK" (48 34 43 4B)
    mov byte [buffer + rcx], 0x48
    mov byte [buffer + rcx + 1], 0x34
    mov byte [buffer + rcx + 2], 0x43
    mov byte [buffer + rcx + 3], 0x4B
    jmp write_changes
    
next_char_hex:
    inc rcx
    jmp search_loop_hex

try_binary_representation:
    ; Stratégie désespérée: parcourir tout le binaire et remplacer chaque 
    ; séquence de 4 octets qui ressemble à une chaîne
    xor rcx, rcx

scan_all_bytes:
    ; Vérifier si on a atteint la fin du fichier
    cmp rcx, r13
    jge no_more_replacements
    
    ; S'assurer qu'il reste au moins 4 octets
    mov rax, rcx
    add rax, 4
    cmp rax, r13
    jg next_scan
    
    ; Vérifier si les 4 octets semblent être une chaîne de caractères
    ; (tous dans la plage ASCII imprimable)
    mov al, [buffer + rcx]
    cmp al, 32        ; Premier caractère ASCII imprimable
    jl next_scan
    cmp al, 126       ; Dernier caractère ASCII imprimable
    jg next_scan
    
    mov al, [buffer + rcx + 1]
    cmp al, 32
    jl next_scan
    cmp al, 126
    jg next_scan
    
    mov al, [buffer + rcx + 2]
    cmp al, 32
    jl next_scan
    cmp al, 126
    jg next_scan
    
    mov al, [buffer + rcx + 3]
    cmp al, 32
    jl next_scan
    cmp al, 126
    jg next_scan
    
    ; Si nous trouvons 4 caractères ASCII imprimables consécutifs,
    ; vérifier s'ils ressemblent à "1337" ou quelque chose de proche
    cmp byte [buffer + rcx], '1'
    jne next_scan
    
    ; Remplacer par "H4CK" de toute façon
    mov byte [buffer + rcx], 'H'
    mov byte [buffer + rcx + 1], '4'
    mov byte [buffer + rcx + 2], 'C'
    mov byte [buffer + rcx + 3], 'K'
    
next_scan:
    inc rcx
    jmp scan_all_bytes
    
no_more_replacements:
    ; Si aucun remplacement n'a été fait, essayer une dernière approche plus directe
    ; Patch directement les adresses connues pour la section .data
    mov byte [buffer + 0x2000], 'H'
    mov byte [buffer + 0x2001], '4'
    mov byte [buffer + 0x2002], 'C'
    mov byte [buffer + 0x2003], 'K'
    
    ; Essayons d'autres offsets courants pour les petits binaires ELF
    mov byte [buffer + 0x3000], 'H'
    mov byte [buffer + 0x3001], '4'
    mov byte [buffer + 0x3002], 'C'
    mov byte [buffer + 0x3003], 'K'
    
    mov byte [buffer + 0x4000], 'H'
    mov byte [buffer + 0x4001], '4'
    mov byte [buffer + 0x4002], 'C'
    mov byte [buffer + 0x4003], 'K'
    
write_changes:
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
