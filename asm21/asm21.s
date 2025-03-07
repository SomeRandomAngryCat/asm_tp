section .bss
    shellcode resb 4096         ; Buffer pour stocker le shellcode décodé

section .text
    global _start

_start:
    ; Vérifier si un paramètre a été fourni
    pop rcx                 ; Récupérer argc
    cmp rcx, 2              ; Vérifier qu'on a au moins un argument
    jl error_args           ; Si moins de 2 arguments, erreur
    
    pop rcx                 ; Ignorer argv[0] (nom du programme)
    pop rdi                 ; Récupérer argv[1] (shellcode hexadécimal)
    
    ; Convertir le shellcode hexadécimal en code binaire
    mov rsi, shellcode      ; Destination pour le code décodé
    call hex_to_bin         ; Appeler la fonction de décodage
    
    ; Vérifier si la conversion a réussi
    test rax, rax
    jz error_shellcode      ; Si erreur, shellcode invalide
    
    ; Rendre la mémoire du shellcode exécutable
    mov rax, 10             ; sys_mprotect
    mov rdi, shellcode      ; adresse du shellcode
    mov rsi, 4096           ; taille (page entière)
    mov rdx, 7              ; PROT_READ | PROT_WRITE | PROT_EXEC
    syscall
    
    ; Vérifier si mprotect a réussi
    test rax, rax
    jnz error_shellcode     ; Si erreur, shellcode invalide
    
    ; Exécuter le shellcode
    call shellcode
    
    ; Si le shellcode retourne, sortir normalement
    mov rax, 60             ; sys_exit
    xor rdi, rdi            ; code 0 (succès)
    syscall
    
error_args:
    ; Erreur: paramètre manquant
    mov rax, 60             ; sys_exit
    mov rdi, 1              ; code 1 (erreur)
    syscall
    
error_shellcode:
    ; Erreur: shellcode invalide
    mov rax, 60             ; sys_exit
    mov rdi, 1              ; code 1 (erreur)
    syscall

; Fonction pour convertir une chaîne hexadécimale en binaire
; Entrée: RDI = chaîne source (format hex), RSI = destination (buffer binaire)
; Sortie: RAX = longueur du shellcode décodé, ou 0 si erreur
hex_to_bin:
    push rbx                ; Sauvegarder les registres
    push rcx
    push rdx
    push r8
    push r9
    
    xor r8, r8              ; Compteur de caractères hex
    xor r9, r9              ; Compteur d'octets binaires
    
hex_loop:
    ; Récupérer le caractère actuel
    movzx rax, byte [rdi + r8]
    test rax, rax           ; Vérifier fin de chaîne
    jz hex_done
    
    ; Ignorer les backslashes et les 'x'
    cmp al, '\\'
    je skip_char
    cmp al, 'x'
    je skip_char
    
    ; Vérifier si c'est un caractère hexadécimal valide
    call is_hex
    test rax, rax
    jz hex_error            ; Si ce n'est pas un caractère hex, erreur
    
    ; Convertir le premier caractère d'un octet
    movzx rcx, byte [rdi + r8]
    call hex_to_val         ; Convertir en valeur
    shl al, 4               ; Décaler de 4 bits (première moitié d'octet)
    mov bl, al              ; Sauvegarder dans bl
    
    ; Passer au caractère suivant
    inc r8
    
    ; Vérifier qu'il reste un caractère (deuxième moitié d'octet)
    movzx rax, byte [rdi + r8]
    test rax, rax
    jz hex_error            ; Si fin de chaîne prématurée, erreur
    
    ; Vérifier si c'est un caractère hexadécimal valide
    call is_hex
    test rax, rax
    jz hex_error            ; Si ce n'est pas un caractère hex, erreur
    
    ; Convertir le deuxième caractère d'un octet
    movzx rcx, byte [rdi + r8]
    call hex_to_val         ; Convertir en valeur
    or bl, al               ; Combiner avec la première moitié
    
    ; Stocker l'octet décodé
    mov [rsi + r9], bl
    inc r9                  ; Incrémenter le compteur d'octets binaires
    jmp next_char
    
skip_char:
    ; Passer ce caractère
    inc r8
    jmp hex_loop
    
next_char:
    ; Passer au caractère suivant
    inc r8
    jmp hex_loop
    
hex_error:
    ; Erreur de décodage
    xor rax, rax            ; RAX = 0 (erreur)
    jmp hex_exit
    
hex_done:
    ; Décodage terminé
    mov rax, r9             ; Retourner la longueur
    
hex_exit:
    pop r9                  ; Restaurer les registres
    pop r8
    pop rdx
    pop rcx
    pop rbx
    ret

; Fonction pour vérifier si un caractère est hexadécimal
; Entrée: AL = caractère
; Sortie: RAX = 1 si hex, 0 sinon
is_hex:
    ; Vérifier si c'est un chiffre (0-9)
    cmp al, '0'
    jl not_hex
    cmp al, '9'
    jle is_hex_digit
    
    ; Vérifier si c'est une lettre majuscule (A-F)
    cmp al, 'A'
    jl not_hex
    cmp al, 'F'
    jle is_hex_digit
    
    ; Vérifier si c'est une lettre minuscule (a-f)
    cmp al, 'a'
    jl not_hex
    cmp al, 'f'
    jle is_hex_digit
    
not_hex:
    xor rax, rax            ; RAX = 0 (pas hex)
    ret
    
is_hex_digit:
    mov rax, 1              ; RAX = 1 (c'est hex)
    ret

; Fonction pour convertir un caractère hex en valeur
; Entrée: CL = caractère hex
; Sortie: AL = valeur (0-15)
hex_to_val:
    ; Vérifier si c'est un chiffre (0-9)
    cmp cl, '0'
    jl hex_error_val
    cmp cl, '9'
    jle hex_digit
    
    ; Vérifier si c'est une lettre majuscule (A-F)
    cmp cl, 'A'
    jl hex_error_val
    cmp cl, 'F'
    jle hex_upper
    
    ; Vérifier si c'est une lettre minuscule (a-f)
    cmp cl, 'a'
    jl hex_error_val
    cmp cl, 'f'
    jle hex_lower
    
hex_error_val:
    xor rax, rax            ; RAX = 0 (erreur)
    ret
    
hex_digit:
    movzx rax, cl
    sub rax, '0'            ; Convertir ASCII à valeur
    ret
    
hex_upper:
    movzx rax, cl
    sub rax, 'A'            ; Convertir ASCII à valeur
    add rax, 10             ; Ajouter 10 (A=10, B=11, etc.)
    ret
    
hex_lower:
    movzx rax, cl
    sub rax, 'a'            ; Convertir ASCII à valeur
    add rax, 10             ; Ajouter 10 (a=10, b=11, etc.)
    ret