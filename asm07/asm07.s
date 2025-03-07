section .data
    error_msg db "Erreur: entrée invalide", 10    ; Message d'erreur
    error_len equ $ - error_msg                   ; Longueur du message d'erreur

section .bss
    buffer resb 16                                ; Buffer pour stocker l'entrée

section .text
    global _start

_start:
    ; Lire l'entrée depuis stdin
    mov rax, 0              ; syscall read
    mov rdi, 0              ; stdin
    mov rsi, buffer         ; buffer où stocker l'entrée
    mov rdx, 16             ; taille maximale à lire
    syscall

    ; Vérifier qu'on a bien lu des données
    cmp rax, 0              ; Si on n'a rien lu (EOF)
    jle error               ; Afficher une erreur

    ; Convertir la chaîne en nombre
    mov rdi, buffer         ; Adresse du buffer contenant la chaîne
    mov rsi, rax            ; Longueur de la chaîne lue
    call str_to_int         ; Convertir la chaîne en entier
    jc error                ; Si erreur de conversion, afficher message

    ; Vérifier si le nombre est premier
    mov rdi, rax            ; Mettre le nombre dans rdi
    call is_prime           ; Vérifier si le nombre est premier

    ; Si le nombre est premier, rax=1, sinon rax=0
    test rax, rax           ; Test si rax est 0
    jz exit_not_prime       ; Si rax=0, le nombre n'est pas premier

exit_prime:
    ; Retourner 0 (nombre premier)
    mov rax, 60             ; syscall exit
    mov rdi, 0              ; code de retour 0 (nombre premier)
    syscall

exit_not_prime:
    ; Retourner 1 (nombre non premier)
    mov rax, 60             ; syscall exit
    mov rdi, 1              ; code de retour 1 (nombre non premier)
    syscall

error:
    ; Afficher le message d'erreur
    mov rax, 1              ; syscall write
    mov rdi, 1              ; stdout
    mov rsi, error_msg      ; message d'erreur
    mov rdx, error_len      ; longueur du message
    syscall

    ; Sortir avec code d'erreur 1
    mov rax, 60             ; syscall exit
    mov rdi, 1              ; code de retour 1
    syscall

; Fonction pour convertir une chaîne en entier
; Entrée: rdi = adresse de la chaîne, rsi = longueur de la chaîne
; Sortie: rax = valeur entière, CF = drapeau d'erreur
str_to_int:
    xor rax, rax            ; Initialiser le résultat à 0
    xor rcx, rcx            ; Initialiser le compteur de caractères

str_to_int_loop:
    cmp rcx, rsi            ; Vérifier si on a atteint la fin de la chaîne
    jge str_to_int_done     ; Si oui, terminer

    movzx rbx, byte [rdi + rcx] ; Charger le caractère courant

    ; Ignorer le caractère de nouvelle ligne à la fin
    cmp rbx, 10             ; Vérifier si c'est un caractère de nouvelle ligne
    je str_to_int_done      ; Si oui, terminer

    cmp rbx, '0'            ; Vérifier si le caractère est < '0'
    jl error_invalid        ; Si oui, c'est une erreur
    cmp rbx, '9'            ; Vérifier si le caractère est > '9'
    jg error_invalid        ; Si oui, c'est une erreur

    ; Convertir le caractère en chiffre
    sub rbx, '0'            ; Convertir ASCII en valeur numérique

    ; Multiplier le résultat actuel par 10 et ajouter le nouveau chiffre
    imul rax, 10            ; rax = rax * 10
    add rax, rbx            ; rax = rax + rbx

    inc rcx                 ; Passer au caractère suivant
    jmp str_to_int_loop     ; Continuer la boucle

error_invalid:
    stc                     ; Mettre le drapeau de retenue (CF) à 1 pour signaler une erreur
    ret

str_to_int_done:
    ; Vérifier qu'on a lu au moins un chiffre
    test rcx, rcx           ; Si rcx=0, aucun chiffre n'a été lu
    jz error_invalid        ; Si oui, c'est une erreur

    clc                     ; Effacer le drapeau de retenue (CF) pour signaler le succès
    ret

; Fonction pour vérifier si un nombre est premier
; Entrée: rdi = nombre à vérifier
; Sortie: rax = 1 si le nombre est premier, 0 sinon
is_prime:
    ; Cas spéciaux
    cmp rdi, 1              ; Les nombres inférieurs à 2 ne sont pas premiers
    jle not_prime
    cmp rdi, 2              ; 2 est premier
    je prime
    
    ; Vérifier si le nombre est pair (divisible par 2)
    test rdi, 1             ; Les nombres pairs ont le bit LSB = 0
    jz not_prime            ; Si le nombre est pair et > 2, il n'est pas premier

    ; Vérifier les diviseurs impairs jusqu'à la racine carrée
    mov rcx, 3              ; Commencer avec le diviseur 3
check_divisors:
    mov rax, rcx            ; rax = diviseur
    mul rax                 ; rax = diviseur * diviseur
    cmp rax, rdi            ; Comparer diviseur² avec le nombre
    jg prime                ; Si diviseur² > nombre, c'est un nombre premier

    mov rax, rdi            ; rax = nombre
    xor rdx, rdx            ; Effacer rdx pour la division
    div rcx                 ; rax = nombre / diviseur, rdx = nombre % diviseur
    
    test rdx, rdx           ; Vérifier si le reste est 0
    jz not_prime            ; Si le reste est 0, le nombre n'est pas premier

    add rcx, 2              ; Passer au prochain nombre impair
    jmp check_divisors      ; Continuer la vérification

prime:
    mov rax, 1              ; Retourner 1 (nombre premier)
    ret

not_prime:
    mov rax, 0              ; Retourner 0 (nombre non premier)
    ret