section .data
    error_msg db "Erreur: paramètre invalide", 10  ; Message d'erreur
    error_len equ $ - error_msg                    ; Longueur du message d'erreur
    
    bin_prefix db "Binaire: "                      ; Préfixe pour l'affichage binaire
    bin_prefix_len equ $ - bin_prefix              ; Longueur du préfixe binaire
    
    hex_prefix db "Hexadécimal: "                  ; Préfixe pour l'affichage hexadécimal
    hex_prefix_len equ $ - hex_prefix              ; Longueur du préfixe hexadécimal
    
    newline db 10                                  ; Caractère de nouvelle ligne
    
    bin_flag db "-b", 0                           ; Option pour affichage binaire uniquement

section .bss
    buffer resb 100                                ; Buffer pour stocker les résultats
    bin_buffer resb 65                             ; Buffer pour le nombre binaire (64 bits max + '\0')
    hex_buffer resb 17                             ; Buffer pour le nombre hexadécimal (16 chiffres max + '\0')

section .text
    global _start

_start:
    ; Vérifier le nombre d'arguments
    pop rcx                 ; rcx = argc (nombre d'arguments)
    cmp rcx, 2              ; Vérifier s'il y a au moins 2 arguments (programme + 1 nombre)
    jl error                ; Si moins d'arguments, afficher une erreur
    cmp rcx, 3              ; Vérifier s'il y a plus de 3 arguments
    jg error                ; Si plus d'arguments, afficher une erreur

    ; Ignorer le nom du programme (premier argument)
    pop rdi                 ; Ignorer argv[0] (nom du programme)
    
    ; Initialiser le flag de mode binaire à 0 (désactivé)
    xor r15, r15            ; r15 = 0 (mode binaire désactivé)
    
    ; Récupérer le premier argument
    pop rdi                 ; rdi = argv[1]
    
    ; Si on a exactement 3 arguments, vérifier si le premier est "-b"
    cmp rcx, 3
    jne not_bin_option
    
    ; Comparer avec "-b"
    mov rsi, bin_flag       ; rsi = "-b"
    mov r14, 0              ; Initialiser le compteur de caractères
    
check_bin_flag:
    mov r8b, byte [rdi + r14] ; Charger le caractère courant de l'argument
    mov r9b, byte [rsi + r14] ; Charger le caractère courant de "-b"
    
    cmp r8b, 0               ; Vérifier la fin de l'argument
    je check_bin_flag_end
    cmp r9b, 0               ; Vérifier la fin de "-b"
    je check_bin_flag_end
    
    cmp r8b, r9b             ; Comparer les caractères
    jne not_bin_option       ; Si différents, ce n'est pas l'option "-b"
    
    inc r14                 ; Passer au caractère suivant
    jmp check_bin_flag

check_bin_flag_end:
    cmp r8b, 0               ; Les deux chaînes doivent se terminer en même temps
    jne not_bin_option
    cmp r9b, 0
    jne not_bin_option
    
    ; C'est bien l'option "-b"
    mov r15, 1               ; r15 = 1 (mode binaire activé)
    pop rdi                  ; Récupérer le prochain argument (le nombre)
    jmp convert_number

not_bin_option:
    ; Si on a 3 arguments mais que le premier n'est pas "-b", c'est une erreur
    cmp rcx, 3
    je error

convert_number:
    ; Convertir la chaîne en entier
    call str_to_int         ; Convertir la chaîne en entier
    mov r12, rax            ; Sauvegarder le nombre dans r12
    jc error                ; Si erreur de conversion, afficher message

    ; Convertir le nombre en binaire
    mov rax, r12            ; rax = le nombre
    mov rdi, bin_buffer     ; rdi = buffer pour le binaire
    mov rsi, 2              ; rsi = base 2 (binaire)
    call int_to_base        ; Convertir en binaire

    ; Si mode binaire activé, afficher uniquement le binaire sans préfixe
    cmp r15, 1
    je print_bin_only
    
    ; Convertir le nombre en hexadécimal
    mov rax, r12            ; rax = le nombre
    mov rdi, hex_buffer     ; rdi = buffer pour l'hexadécimal
    mov rsi, 16             ; rsi = base 16 (hexadécimal)
    call int_to_base        ; Convertir en hexadécimal

    ; Afficher le résultat hexadécimal
    mov rax, 1              ; syscall write
    mov rdi, 1              ; stdout
    mov rsi, hex_buffer     ; nombre hexadécimal à afficher
    mov rdx, 0              ; initialiser compteur de longueur

count_hex_len:
    cmp byte [rsi + rdx], 0 ; vérifier si on a atteint la fin de la chaîne
    je print_hex            ; si oui, afficher
    inc rdx                 ; sinon, incrémenter le compteur
    jmp count_hex_len       ; et continuer à compter

print_hex:
    syscall
    
    ; Afficher une nouvelle ligne
    mov rax, 1              ; syscall write
    mov rdi, 1              ; stdout
    mov rsi, newline        ; caractère de nouvelle ligne
    mov rdx, 1              ; longueur (1 caractère)
    syscall
    
    jmp exit_success        ; Terminer avec succès

print_bin_only:
    ; Afficher le nombre binaire
    mov rax, 1              ; syscall write
    mov rdi, 1              ; stdout
    mov rsi, bin_buffer     ; nombre binaire à afficher
    mov rdx, 0              ; initialiser compteur de longueur

count_bin_len:
    cmp byte [rsi + rdx], 0 ; vérifier si on a atteint la fin de la chaîne
    je print_bin            ; si oui, afficher
    inc rdx                 ; sinon, incrémenter le compteur
    jmp count_bin_len       ; et continuer à compter

print_bin:
    syscall

    ; Afficher une nouvelle ligne
    mov rax, 1              ; syscall write
    mov rdi, 1              ; stdout
    mov rsi, newline        ; caractère de nouvelle ligne
    mov rdx, 1              ; longueur (1 caractère)
    syscall

    jmp exit_success        ; Terminer avec succès

error:
    ; Afficher le message d'erreur
    mov rax, 1              ; syscall write
    mov rdi, 1              ; stdout
    mov rsi, error_msg      ; message d'erreur
    mov rdx, error_len      ; longueur du message
    syscall

exit_success:
    ; Sortir avec le code de retour 0
    mov rax, 60             ; syscall exit
    mov rdi, 0              ; code de retour 0
    syscall

; Fonction pour convertir une chaîne en entier
; Entrée: rdi = adresse de la chaîne
; Sortie: rax = valeur entière, CF = drapeau d'erreur
str_to_int:
    xor rax, rax            ; Initialiser le résultat à 0
    xor rbx, rbx            ; Initialiser l'accumulateur temporaire
    xor rcx, rcx            ; Initialiser le compteur de caractères
    xor r9, r9              ; Initialiser le drapeau de signe à 0 (positif)

    ; Vérifier si la chaîne commence par un signe
    mov bl, byte [rdi]
    cmp bl, '+'             ; Vérifier si le premier caractère est '+'
    je error_invalid        ; Si oui, c'est une erreur (pas de signes explicites)
    cmp bl, '-'             ; Vérifier si le premier caractère est '-'
    je error_invalid        ; Si oui, c'est une erreur (pas de signes explicites)

str_to_int_loop:
    mov bl, byte [rdi + rcx] ; Charger le caractère courant
    cmp bl, 0                ; Vérifier si c'est la fin de la chaîne
    je str_to_int_done       ; Si oui, terminer

    cmp bl, '0'              ; Vérifier si le caractère est < '0'
    jl error_invalid         ; Si oui, c'est une erreur
    cmp bl, '9'              ; Vérifier si le caractère est > '9'
    jg error_invalid         ; Si oui, c'est une erreur

    ; Convertir le caractère en chiffre
    sub bl, '0'              ; Convertir ASCII en valeur numérique

    ; Multiplier le résultat actuel par 10 et ajouter le nouveau chiffre
    imul rax, 10             ; rax = rax * 10
    add rax, rbx             ; rax = rax + rbx

    inc rcx                  ; Passer au caractère suivant
    jmp str_to_int_loop      ; Continuer la boucle

error_invalid:
    stc                      ; Mettre le drapeau de retenue (CF) à 1 pour signaler une erreur
    ret

str_to_int_done:
    ; Vérifier qu'on a lu au moins un chiffre
    test rcx, rcx            ; Si rcx=0, aucun chiffre n'a été lu
    jz error_invalid         ; Si oui, c'est une erreur

    clc                      ; Effacer le drapeau de retenue (CF) pour signaler le succès
    ret

; Fonction pour convertir un entier en chaîne dans une base donnée
; Entrée: rax = entier à convertir, rdi = adresse du buffer, rsi = base
; Sortie: le buffer contient la chaîne convertie
int_to_base:
    push rbp                 ; Sauvegarder rbp
    mov rbp, rsp             ; Établir un nouveau frame pointer
    push rbx                 ; Sauvegarder rbx
    push r12                 ; Sauvegarder r12
    push r13                 ; Sauvegarder r13
    push r14                 ; Sauvegarder r14
    
    mov rbx, rsi             ; rbx = base
    mov r12, rdi             ; r12 = adresse du buffer
    xor rcx, rcx             ; rcx = index dans le buffer
    mov r13, rax             ; r13 = valeur à convertir
    
    ; Gérer le cas spécial de 0
    test r13, r13
    jnz int_to_base_loop
    mov byte [r12], '0'      ; Stocker '0' dans le buffer
    mov byte [r12 + 1], 0    ; Terminer la chaîne
    jmp int_to_base_done

int_to_base_loop:
    test r13, r13            ; Vérifier si la valeur est 0
    jz int_to_base_reverse   ; Si oui, terminer la boucle

    xor rdx, rdx             ; Effacer rdx pour la division
    mov rax, r13             ; rax = valeur
    div rbx                  ; rax = valeur / base, rdx = valeur % base

    mov r13, rax             ; Mettre à jour la valeur pour la prochaine itération

    ; Convertir le reste en caractère
    cmp rdx, 10              ; Vérifier si le reste est < 10
    jl digit                 ; Si oui, c'est un chiffre
    add rdx, 'A' - 10        ; Sinon, c'est une lettre (A-F)
    jmp store_char

digit:
    add rdx, '0'             ; Convertir en chiffre ASCII

store_char:
    mov [r12 + rcx], dl      ; Stocker le caractère dans le buffer
    inc rcx                  ; Incrémenter l'index
    jmp int_to_base_loop     ; Continuer la boucle

int_to_base_reverse:
    ; Ajouter le caractère nul de fin de chaîne
    mov byte [r12 + rcx], 0  ; Terminer la chaîne

    ; Inverser la chaîne (car elle est actuellement à l'envers)
    mov rax, rcx             ; rax = longueur de la chaîne
    cmp rax, 1               ; Si la longueur est 1, pas besoin d'inverser
    jle int_to_base_done

    dec rax                  ; rax = index du dernier caractère
    xor rbx, rbx             ; rbx = index du premier caractère

reverse_loop:
    cmp rbx, rax             ; Vérifier si on a parcouru toute la chaîne
    jge int_to_base_done     ; Si oui, terminer

    ; Échanger les caractères
    mov dl, [r12 + rbx]      ; dl = caractère au début
    mov r8b, [r12 + rax]     ; r8b = caractère à la fin (utiliser r8b au lieu de dh)
    mov [r12 + rbx], r8b     ; Mettre le caractère de la fin au début
    mov [r12 + rax], dl      ; Mettre le caractère du début à la fin

    inc rbx                  ; Incrémenter l'index du début
    dec rax                  ; Décrémenter l'index de la fin
    jmp reverse_loop         ; Continuer la boucle

int_to_base_done:
    pop r14                  ; Restaurer r14
    pop r13                  ; Restaurer r13
    pop r12                  ; Restaurer r12
    pop rbx                  ; Restaurer rbx
    pop rbp                  ; Restaurer rbp
    ret