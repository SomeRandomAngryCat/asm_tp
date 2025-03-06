section .data
    error_msg db "Erreur: paramètres invalides", 10  ; Message d'erreur
    error_len equ $ - error_msg                      ; Longueur du message d'erreur
    newline db 10                                    ; Caractère de nouvelle ligne

section .bss
    buffer resb 20                                   ; Buffer pour stocker le résultat en ASCII

section .text
    global _start

_start:
    ; Vérifier le nombre d'arguments
    pop rcx                 ; rcx = argc (nombre d'arguments)
    cmp rcx, 3              ; Vérifier s'il y a exactement 3 arguments (programme + 2 nombres)
    jne error               ; Si non, afficher une erreur

    ; Ignorer le nom du programme (premier argument)
    pop rdi                 ; Ignorer argv[0] (nom du programme)

    ; Récupérer le premier nombre
    pop rdi                 ; rdi = argv[1] (premier nombre)
    call str_to_int         ; Convertir la chaîne en entier
    mov r12, rax            ; Sauvegarder le premier nombre dans r12
    jc error                ; Si erreur de conversion, afficher message

    ; Récupérer le deuxième nombre
    pop rdi                 ; rdi = argv[2] (deuxième nombre)
    call str_to_int         ; Convertir la chaîne en entier
    mov r13, rax            ; Sauvegarder le deuxième nombre dans r13
    jc error                ; Si erreur de conversion, afficher message

    ; Additionner les deux nombres
    add r12, r13            ; r12 = r12 + r13

    ; Convertir le résultat en chaîne et l'afficher
    mov rax, r12            ; rax = résultat de l'addition
    mov rdi, buffer         ; rdi = buffer où stocker la chaîne résultat
    call int_to_str         ; Convertir l'entier en chaîne
    mov r14, rax            ; r14 = longueur de la chaîne résultat

    ; Afficher le résultat
    mov rax, 1              ; syscall write
    mov rdi, 1              ; stdout
    mov rsi, buffer         ; chaîne à afficher
    mov rdx, r14            ; longueur de la chaîne
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
    clc                      ; Effacer le drapeau de retenue (CF) pour signaler le succès
    ret

; Fonction pour convertir un entier en chaîne
; Entrée: rax = entier à convertir, rdi = adresse du buffer
; Sortie: rax = longueur de la chaîne résultante
int_to_str:
    push rbp                 ; Sauvegarder rbp
    mov rbp, rsp             ; Établir un nouveau frame pointer
    push rbx                 ; Sauvegarder rbx
    push rdi                 ; Sauvegarder rdi

    mov rbx, 10              ; Base 10 pour la division
    xor rcx, rcx             ; Compteur de chiffres

    ; Gérer le cas spécial de 0
    test rax, rax
    jnz int_to_str_loop
    mov byte [rdi], '0'      ; Stocker '0' dans le buffer
    inc rdi                  ; Incrémenter le pointeur du buffer
    inc rcx                  ; Incrémenter le compteur
    jmp int_to_str_reverse

int_to_str_loop:
    test rax, rax            ; Vérifier si rax est 0
    jz int_to_str_reverse    ; Si oui, terminer la boucle

    xor rdx, rdx             ; Effacer rdx pour la division
    div rbx                  ; rax = rax / 10, rdx = rax % 10

    add dl, '0'              ; Convertir le reste en caractère ASCII
    mov [rdi], dl            ; Stocker le caractère dans le buffer
    inc rdi                  ; Incrémenter le pointeur du buffer
    inc rcx                  ; Incrémenter le compteur
    jmp int_to_str_loop      ; Continuer la boucle

int_to_str_reverse:
    ; Ajouter le caractère nul de fin de chaîne
    mov byte [rdi], 0        ; Terminer la chaîne par un caractère nul

    ; Récupérer l'adresse de début du buffer
    pop rdi                  ; Restaurer rdi (adresse du buffer)

    ; Inverser la chaîne (car elle est actuellement à l'envers)
    mov rax, rcx             ; rax = longueur de la chaîne
    cmp rax, 1               ; Si la longueur est 1, pas besoin d'inverser
    jle int_to_str_done

    dec rax                  ; rax = index du dernier caractère
    mov rbx, 0               ; rbx = index du premier caractère

reverse_loop:
    cmp rbx, rax             ; Vérifier si on a parcouru toute la chaîne
    jge int_to_str_done      ; Si oui, terminer

    ; Échanger les caractères
    mov dl, [rdi + rbx]      ; dl = caractère au début
    mov dh, [rdi + rax]      ; dh = caractère à la fin
    mov [rdi + rbx], dh      ; Mettre le caractère de la fin au début
    mov [rdi + rax], dl      ; Mettre le caractère du début à la fin

    inc rbx                  ; Incrémenter l'index du début
    dec rax                  ; Décrémenter l'index de la fin
    jmp reverse_loop         ; Continuer la boucle

int_to_str_done:
    mov rax, rcx             ; Retourner la longueur de la chaîne
    pop rbx                  ; Restaurer rbx
    pop rbp                  ; Restaurer rbp
    ret