section .data
    vowels db "aeiouAEIOU", 0    ; Liste des voyelles

section .bss
    buffer resb 1024             ; Buffer pour stocker l'entrée
    result resb 32               ; Buffer pour le résultat

section .text
    global _start

_start:
    ; Lire l'entrée depuis stdin
    mov rax, 0                   ; sys_read
    mov rdi, 0                   ; stdin
    mov rsi, buffer              ; buffer
    mov rdx, 1024                ; taille maximale
    syscall
    
    ; Vérifier si la lecture a réussi
    test rax, rax
    jle exit_success             ; Si pas d'entrée, retourner 0 voyelles
    
    ; Stocker la longueur lue
    mov r12, rax
    
    ; Initialiser le compteur de voyelles
    xor r13, r13                 ; r13 = compteur de voyelles
    
    ; Initialiser l'index de caractère
    xor r14, r14                 ; r14 = index du caractère actuel
    
scan_loop:
    ; Vérifier si on a atteint la fin de la chaîne
    cmp r14, r12
    jge print_result
    
    ; Récupérer le caractère actuel
    mov al, byte [buffer + r14]
    
    ; Vérifier si c'est une voyelle
    call is_vowel
    test rax, rax
    jz next_char
    
    ; Si c'est une voyelle, incrémenter le compteur
    inc r13
    
next_char:
    ; Passer au caractère suivant
    inc r14
    jmp scan_loop
    
print_result:
    ; Convertir le compteur en chaîne
    mov rax, r13
    mov rdi, result
    call itoa
    mov r15, rax                 ; Longueur de la chaîne de résultat
    
    ; Afficher le résultat
    mov rax, 1                   ; sys_write
    mov rdi, 1                   ; stdout
    mov rsi, result              ; chaîne à afficher
    mov rdx, r15                 ; longueur
    syscall
    
    ; Ajouter un saut de ligne
    mov byte [result], 10        ; caractère de nouvelle ligne
    mov rax, 1                   ; sys_write
    mov rdi, 1                   ; stdout
    mov rsi, result              ; chaîne à afficher
    mov rdx, 1                   ; longueur
    syscall
    
exit_success:
    ; Quitter avec le code 0
    mov rax, 60                  ; sys_exit
    xor rdi, rdi                 ; code 0
    syscall

; Fonction pour vérifier si un caractère est une voyelle
; Entrée: AL = caractère
; Sortie: RAX = 1 si voyelle, 0 sinon
is_vowel:
    push rbx                     ; Sauvegarder rbx
    push rdi                     ; Sauvegarder rdi
    
    ; Initialiser l'index pour la recherche
    xor rbx, rbx
    
vowel_loop:
    ; Récupérer la voyelle actuelle
    mov dil, byte [vowels + rbx]
    
    ; Vérifier si on a atteint la fin de la liste
    test dil, dil
    jz not_vowel
    
    ; Comparer avec le caractère
    cmp al, dil
    je found_vowel
    
    ; Passer à la voyelle suivante
    inc rbx
    jmp vowel_loop
    
found_vowel:
    mov rax, 1                   ; C'est une voyelle
    jmp vowel_done
    
not_vowel:
    xor rax, rax                 ; Ce n'est pas une voyelle
    
vowel_done:
    pop rdi                      ; Restaurer rdi
    pop rbx                      ; Restaurer rbx
    ret

; Fonction pour convertir un entier en chaîne
; Entrée: RAX = nombre, RDI = buffer de destination
; Sortie: RAX = longueur de la chaîne
itoa:
    push rbx                     ; Sauvegarder les registres
    push rcx
    push rdx
    push rdi
    
    ; Cas spécial pour 0
    test rax, rax
    jnz .not_zero
    
    mov byte [rdi], '0'          ; Stocker '0'
    mov rax, 1                   ; Longueur = 1
    jmp .done
    
.not_zero:
    mov rcx, 10                  ; Diviseur
    xor rbx, rbx                 ; Compteur de chiffres
    
.divide_loop:
    ; Diviser par 10
    xor rdx, rdx                 ; Nettoyer reste
    div rcx                      ; RAX = quotient, RDX = reste
    
    ; Convertir le reste en ASCII et stocker
    add dl, '0'                  ; Convertir en ASCII
    mov [rdi + rbx], dl          ; Stocker le chiffre
    inc rbx                      ; Incrémenter le compteur
    
    ; Continuer tant que le quotient n'est pas 0
    test rax, rax
    jnz .divide_loop
    
    ; rbx contient le nombre de chiffres
    mov rax, rbx                 ; Longueur = nombre de chiffres
    
    ; Inverser la chaîne (elle est actuellement dans l'ordre inverse)
    mov rcx, rax
    shr rcx, 1                   ; Diviser par 2 (nombre de swaps)
    
    dec rax                      ; Dernier index = longueur - 1
    
.reverse_loop:
    test rcx, rcx
    jz .done
    
    ; Échanger les caractères
    mov dl, [rdi]                ; Premier caractère
    mov bl, [rdi + rax]          ; Dernier caractère
    mov [rdi], bl                ; Swap
    mov [rdi + rax], dl
    
    ; Avancer vers le centre
    inc rdi
    dec rax
    dec rcx
    jmp .reverse_loop
    
.done:
    pop rdi                      ; Restaurer les registres
    pop rdx
    pop rcx
    pop rbx
    ret