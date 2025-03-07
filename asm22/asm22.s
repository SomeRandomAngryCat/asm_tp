section .data
    ; Messages et noms de fichiers
    input_name db 0               ; Nom du binaire d'entrée (fourni en paramètre)
    output_name db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    output_suffix db "_packed", 0  ; Suffixe pour le nom du binaire de sortie
    
    ; Début du code pour le loader qui sera injecté dans le binaire de sortie
    loader_start:
        ; Code du loader (stub) qui déchiffrera et exécutera le binaire original
        ; Ce code sera copié au début du binaire packé
        
        ; Prologue: sauvegarder l'état
        push rbp
        mov rbp, rsp
        push rbx
        push rcx
        push rdx
        push rsi
        push rdi
        push r8
        push r9
        push r10
        push r11
        push r12
        push r13
        push r14
        push r15
        
        ; Allouer de la mémoire pour le programme déchiffré avec mmap
        mov rax, 9                 ; sys_mmap
        mov rdi, 0                 ; addr = NULL (laissez le noyau choisir)
        mov rsi, original_size     ; length = taille du programme original
        mov rdx, 7                 ; prot = PROT_READ|PROT_WRITE|PROT_EXEC
        mov r10, 0x22              ; flags = MAP_PRIVATE|MAP_ANONYMOUS
        mov r8, -1                 ; fd = -1
        mov r9, 0                  ; offset = 0
        syscall
        
        ; Vérifier si mmap a réussi
        test rax, rax
        js exit_loader
        
        ; Stocker l'adresse de la mémoire allouée
        mov r12, rax               ; r12 = adresse mémoire pour programme déchiffré
        
        ; Déchiffrer le programme original
        lea rsi, [rel encrypted_data] ; Source: données chiffrées
        mov rdi, r12               ; Destination: mémoire allouée
        mov rcx, original_size     ; Compteur: taille du programme
        
    decrypt_loop:
        mov al, byte [rsi]         ; Lire l'octet chiffré
        xor al, 0xAA               ; Déchiffrer avec XOR (clé simple)
        mov byte [rdi], al         ; Écrire l'octet déchiffré
        inc rsi                    ; Avancer dans la source
        inc rdi                    ; Avancer dans la destination
        dec rcx                    ; Décrémenter le compteur
        jnz decrypt_loop           ; Continuer jusqu'à ce que tout soit déchiffré
        
        ; Exécuter le programme déchiffré
        call r12                   ; Appeler le programme déchiffré
        
        ; Libérer la mémoire
        mov rax, 11                ; sys_munmap
        mov rdi, r12               ; addr = adresse de la mémoire allouée
        mov rsi, original_size     ; length = taille du programme original
        syscall
        
    exit_loader:
        ; Épilogue: restaurer l'état
        pop r15
        pop r14
        pop r13
        pop r12
        pop r11
        pop r10
        pop r9
        pop r8
        pop rdi
        pop rsi
        pop rdx
        pop rcx
        pop rbx
        pop rbp
        
        ; Terminer normalement
        mov rax, 60                ; sys_exit
        xor rdi, rdi               ; code 0 (succès)
        syscall
        
    ; Placeholders pour les métadonnées (seront remplacés lors du packing)
    original_size: dq 0            ; Taille du binaire original
    encrypted_data:                ; Début des données chiffrées
    loader_end:

    ; Calculer la taille du loader
    loader_size equ loader_end - loader_start
    
section .bss
    input_fd resq 1              ; Descripteur de fichier d'entrée
    output_fd resq 1             ; Descripteur de fichier de sortie
    stat_buffer resb 144         ; Buffer pour stat
    input_buffer resb 10485760   ; Buffer pour le contenu du fichier d'entrée (10Mo max)
    output_buffer resb 10485760  ; Buffer pour le contenu du fichier de sortie

section .text
    global _start

_start:
    ; Vérifier si un paramètre a été fourni
    pop rcx                     ; Récupérer argc
    cmp rcx, 2                  ; Vérifier qu'on a au moins un argument
    jl error_args               ; Si moins de 2 arguments, erreur
    
    pop rcx                     ; Ignorer argv[0] (nom du programme)
    pop rdi                     ; Récupérer argv[1] (nom du binaire d'entrée)
    
    ; Stocker le nom du binaire d'entrée
    mov [input_name], rdi
    
    ; Créer le nom du binaire de sortie (input_name + "_packed")
    mov rsi, rdi                ; Source: nom du binaire d'entrée
    mov rdi, output_name        ; Destination: buffer pour le nom de sortie
    
copy_input_name:
    mov al, byte [rsi]          ; Lire caractère du nom d'entrée
    test al, al                 ; Vérifier fin de chaîne
    jz end_copy_name
    mov byte [rdi], al          ; Copier le caractère
    inc rsi                     ; Avancer dans la source
    inc rdi                     ; Avancer dans la destination
    jmp copy_input_name
    
end_copy_name:
    ; Ajouter le suffixe "_packed"
    mov rsi, output_suffix      ; Source: suffixe
    
copy_suffix:
    mov al, byte [rsi]          ; Lire caractère du suffixe
    mov byte [rdi], al          ; Copier le caractère
    test al, al                 ; Vérifier fin de chaîne
    jz end_copy_suffix
    inc rsi                     ; Avancer dans la source
    inc rdi                     ; Avancer dans la destination
    jmp copy_suffix
    
end_copy_suffix:
    ; Ouvrir le fichier d'entrée en lecture
    mov rax, 2                  ; sys_open
    mov rdi, [input_name]       ; nom du fichier
    mov rsi, 0                  ; O_RDONLY
    xor rdx, rdx                ; mode (non utilisé pour O_RDONLY)
    syscall
    
    ; Vérifier si l'ouverture a réussi
    test rax, rax
    js error_file
    
    ; Stocker le descripteur de fichier
    mov [input_fd], rax
    
    ; Obtenir la taille du fichier avec stat
    mov rax, 4                  ; sys_stat
    mov rdi, [input_name]       ; nom du fichier
    mov rsi, stat_buffer        ; buffer pour les infos
    syscall
    
    ; Vérifier si stat a réussi
    test rax, rax
    js error_file
    
    ; La taille du fichier est à l'offset 48 (st_size) dans le buffer stat
    mov r12, [stat_buffer + 48] ; r12 = taille du fichier d'entrée
    
    ; Lire le contenu du fichier d'entrée
    mov rax, 0                  ; sys_read
    mov rdi, [input_fd]         ; descripteur du fichier d'entrée
    mov rsi, input_buffer       ; buffer de destination
    mov rdx, r12                ; nombre d'octets à lire
    syscall
    
    ; Vérifier si la lecture a réussi
    cmp rax, r12
    jne error_file
    
    ; Fermer le fichier d'entrée
    mov rax, 3                  ; sys_close
    mov rdi, [input_fd]         ; descripteur du fichier
    syscall
    
    ; Chiffrer le contenu du fichier d'entrée
    mov rsi, input_buffer       ; Source: contenu original
    mov rdi, output_buffer + loader_size ; Destination: après le loader dans le buffer de sortie
    mov rcx, r12                ; Compteur: taille du fichier
    
encrypt_loop:
    mov al, byte [rsi]          ; Lire l'octet original
    xor al, 0xAA                ; Chiffrer avec XOR (clé simple)
    mov byte [rdi], al          ; Écrire l'octet chiffré
    inc rsi                     ; Avancer dans la source
    inc rdi                     ; Avancer dans la destination
    dec rcx                     ; Décrémenter le compteur
    jnz encrypt_loop            ; Continuer jusqu'à ce que tout soit chiffré
    
    ; Copier le loader dans le buffer de sortie
    mov rsi, loader_start       ; Source: code du loader
    mov rdi, output_buffer      ; Destination: début du buffer de sortie
    mov rcx, loader_size        ; Compteur: taille du loader
    
copy_loader:
    mov al, byte [rsi]          ; Lire l'octet du loader
    mov byte [rdi], al          ; Copier dans le buffer de sortie
    inc rsi                     ; Avancer dans la source
    inc rdi                     ; Avancer dans la destination
    dec rcx                     ; Décrémenter le compteur
    jnz copy_loader             ; Continuer jusqu'à ce que tout soit copié
    
    ; Mettre à jour le placeholder pour la taille originale
    mov [output_buffer + loader_start - loader_end + original_size], r12
    
    ; Ouvrir le fichier de sortie en écriture
    mov rax, 2                  ; sys_open
    mov rdi, output_name        ; nom du fichier
    mov rsi, 0102o              ; O_CREAT | O_WRONLY
    mov rdx, 0755o              ; mode: rwxr-xr-x
    syscall
    
    ; Vérifier si l'ouverture a réussi
    test rax, rax
    js error_file
    
    ; Stocker le descripteur de fichier
    mov [output_fd], rax
    
    ; Écrire le contenu dans le fichier de sortie
    mov rax, 1                  ; sys_write
    mov rdi, [output_fd]        ; descripteur du fichier de sortie
    mov rsi, output_buffer      ; buffer source
    mov rdx, loader_size        ; taille du loader
    add rdx, r12                ; plus taille du contenu chiffré
    syscall
    
    ; Vérifier si l'écriture a réussi
    cmp rax, rdx
    jne error_file
    
    ; Fermer le fichier de sortie
    mov rax, 3                  ; sys_close
    mov rdi, [output_fd]        ; descripteur du fichier
    syscall
    
    ; Terminer avec succès
    mov rax, 60                 ; sys_exit
    xor rdi, rdi                ; code 0 (succès)
    syscall
    
error_args:
    ; Erreur: paramètre manquant
    mov rax, 60                 ; sys_exit
    mov rdi, 1                  ; code 1 (erreur)
    syscall
    
error_file:
    ; Erreur: problème avec les fichiers
    mov rax, 60                 ; sys_exit
    mov rdi, 1                  ; code 1 (erreur)
    syscall