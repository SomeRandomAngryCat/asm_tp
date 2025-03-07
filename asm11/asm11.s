section .data
    vowels db "aeiouAEIOUyY", 0    ; Liste des voyelles (incluant y/Y)

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
    jle empty_input              ; Si pas d'entrée, retourner 0 voyelles
    
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
    movzx rax, byte [buffer + r14]
    
    ; Vérifier si c'est une voyelle
    call is_vowel
    
    ; Si c'est une voyelle, incrémenter le compteur
    add r13, rax
    
    ; Passer au caractère suivant
    inc r14
    jmp scan_loop

empty_input:
    ; Pour l'entrée vide, on affiche 0
    mov r13, 0
    
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
    
    ; Quitter avec le code 0
    mov rax, 60                  ; sys_exit
    xor rdi, rdi                 ; code 0
    syscall

; Fonction pour vérifier si un caractère est une voyelle
; Entrée: RAX = caractère
; Sortie: RAX = 1 si voyelle, 0 sinon
is_vowel:
    push rbx                     ; Sauvegarder rbx
    
    ; Initialiser l'index pour la recherche
    xor rbx, rbx
    
vowel_loop:
    ; Récupérer la voyelle actuelle
    movzx rcx, byte [vowels + rbx]
    
    ; Vérifier si on a atteint la fin de la liste
    test rcx, rcx
    jz not_vowel
    
    ; Comparer avec le caractère
    cmp al, cl
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
    pop rbx                      ; Restaurer rbx
    ret

; Fonction pour convertir un entier en chaîne
; Entrée: RAX = nombre, RDI = buffer de destination
; Sortie: RAX = longueur de la chaîne
itoa:
    push rbx                     ; Sauvegarder les registres
    push rcx
    push rdx
    push rsi
    
    mov rsi, rdi                 ; Sauvegarder le début du buffer
    
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
    push rdx                     ; Stocker temporairement
    inc rbx                      ; Incrémenter le compteur
    
    ; Continuer tant que le quotient n'est pas 0
    test rax, rax
    jnz .divide_loop
    
    ; rbx contient le nombre de chiffres
    mov rcx, rbx                 ; Copier le compteur
    
.store_loop:
    pop rdx                      ; Récupérer un chiffre
    mov [rdi], dl                ; Stocker dans le buffer
    inc rdi                      ; Avancer dans le buffer
    dec rcx                      ; Décrémenter le compteur
    jnz .store_loop              ; Continuer jusqu'à la fin
    
    mov rax, rbx                 ; Retourner la longueur
    
.done:
    pop rsi                      ; Restaurer les registres
    pop rdx
    pop rcx
    pop rbx
    ret
