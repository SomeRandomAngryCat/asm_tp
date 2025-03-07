section .bss
    buffer resb 4096            ; Buffer pour entrée/sortie
    shift_value resq 1          ; Valeur de décalage

section .text
    global _start

_start:
    ; Vérifier si on a les bons arguments (programme + décalage)
    pop rcx                     ; Récupérer argc
    cmp rcx, 2                  ; Vérifier qu'on a au moins un argument
    jl error_args               ; Si moins de 2 arguments, erreur
    
    pop rcx                     ; Ignorer argv[0] (nom du programme)
    pop rdi                     ; Récupérer argv[1] (valeur de décalage)
    
    ; Convertir la valeur de décalage en entier
    call atoi
    
    ; Vérifier si la conversion a réussi
    cmp rax, -1
    je error_args
    
    ; Stocker la valeur de décalage
    mov [shift_value], rax
    
    ; Lire l'entrée depuis stdin
    mov rax, 0                  ; sys_read
    mov rdi, 0                  ; stdin
    mov rsi, buffer             ; buffer de destination
    mov rdx, 4096               ; taille maximale
    syscall
    
    ; Vérifier si la lecture a réussi
    test rax, rax
    js error_exit               ; Si erreur (négatif), sortir avec erreur
    
    ; Stocker la longueur lue
    mov r12, rax
    
    ; Appliquer le chiffrement de César
    xor rcx, rcx                ; Initialiser l'index
    
caesar_loop:
    ; Vérifier si on a traité toute l'entrée
    cmp rcx, r12
    jge caesar_done
    
    ; Récupérer le caractère actuel
    mov al, byte [buffer + rcx]
    
    ; Vérifier si c'est une lettre
    call is_alpha
    test rax, rax
    jz next_char                ; Si ce n'est pas une lettre, passer au suivant
    
    ; Déterminer si c'est une majuscule ou minuscule
    mov al, byte [buffer + rcx]
    cmp al, 'A'
    jl next_char
    cmp al, 'Z'
    jle shift_uppercase
    cmp al, 'a'
    jl next_char
    cmp al, 'z'
    jle shift_lowercase
    jmp next_char
    
shift_uppercase:
    ; Appliquer le décalage pour les majuscules (A-Z)
    sub al, 'A'                 ; Transformer en 0-25
    add rax, [shift_value]      ; Ajouter le décalage
    
    ; Assurer que la valeur reste entre 0 et 25
    mov rbx, 26
    xor rdx, rdx                ; Clear rdx pour division
    div rbx                     ; rax = quotient, rdx = reste (0-25)
    mov rax, rdx                ; Utiliser le reste
    
    add rax, 'A'                ; Reconvertir en A-Z
    mov byte [buffer + rcx], al ; Remplacer le caractère
    jmp next_char
    
shift_lowercase:
    ; Appliquer le décalage pour les minuscules (a-z)
    sub al, 'a'                 ; Transformer en 0-25
    add rax, [shift_value]      ; Ajouter le décalage
    
    ; Assurer que la valeur reste entre 0 et 25
    mov rbx, 26
    xor rdx, rdx                ; Clear rdx pour division
    div rbx                     ; rax = quotient, rdx = reste (0-25)
    mov rax, rdx                ; Utiliser le reste
    
    add rax, 'a'                ; Reconvertir en a-z
    mov byte [buffer + rcx], al ; Remplacer le caractère
    
next_char:
    inc rcx                     ; Passer au caractère suivant
    jmp caesar_loop
    
caesar_done:
    ; Afficher le résultat
    mov rax, 1                  ; sys_write
    mov rdi, 1                  ; stdout
    mov rsi, buffer             ; buffer source
    mov rdx, r12                ; longueur
    syscall
    
    ; Sortir avec succès
    mov rax, 60                 ; sys_exit
    xor rdi, rdi                ; code 0 (succès)
    syscall
    
error_args:
    ; Erreur: mauvais arguments
    mov rax, 60                 ; sys_exit
    mov rdi, 1                  ; code 1 (erreur)
    syscall
    
error_exit:
    ; Erreur: problème d'E/S
    mov rax, 60                 ; sys_exit
    mov rdi, 1                  ; code 1 (erreur)
    syscall

; Fonction pour convertir une chaîne en entier
; Entrée: RDI = pointeur vers la chaîne
; Sortie: RAX = entier ou -1 si erreur
atoi:
    push rbx
    push rcx
    push rdx
    
    xor rax, rax                ; Initialiser le résultat
    xor rcx, rcx                ; Initialiser le signe (0 = positif)
    
    ; Vérifier si la chaîne est vide
    mov bl, byte [rdi]
    test bl, bl
    jz .error
    
    ; Vérifier le signe
    cmp bl, '-'
    jne .check_digit
    mov rcx, 1                  ; Signe négatif
    inc rdi                     ; Passer au caractère suivant
    
.check_digit:
    ; Vérifier si on est à la fin de la chaîne
    mov bl, byte [rdi]
    test bl, bl
    jz .finalize
    
    ; Vérifier si c'est un chiffre
    cmp bl, '0'
    jl .error
    cmp bl, '9'
    jg .error
    
    ; Convertir le chiffre
    sub bl, '0'                 ; Convertir ASCII en valeur
    imul rax, 10                ; Multiplier le résultat actuel par 10
    add rax, rbx                ; Ajouter le nouveau chiffre
    
    inc rdi                     ; Passer au caractère suivant
    jmp .check_digit
    
.finalize:
    ; Appliquer le signe
    test rcx, rcx
    jz .done
    neg rax                     ; Nombre négatif
    
.done:
    pop rdx
    pop rcx
    pop rbx
    ret
    
.error:
    mov rax, -1                 ; Valeur d'erreur
    jmp .done

; Fonction pour vérifier si un caractère est alphabétique
; Entrée: AL = caractère
; Sortie: RAX = 1 si alpha, 0 sinon
is_alpha:
    ; Vérifier si c'est une lettre majuscule
    cmp al, 'A'
    jl .not_alpha
    cmp al, 'Z'
    jle .is_alpha
    
    ; Vérifier si c'est une lettre minuscule
    cmp al, 'a'
    jl .not_alpha
    cmp al, 'z'
    jle .is_alpha
    
.not_alpha:
    xor rax, rax                ; Retourner 0 (pas une lettre)
    ret
    
.is_alpha:
    mov rax, 1                  ; Retourner 1 (c'est une lettre)
    ret