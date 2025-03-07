section .bss
    buffer resb 1024         ; Buffer pour stocker l'entrée

section .text
    global _start

_start:
    ; Lire l'entrée depuis stdin
    mov rax, 0               ; sys_read
    mov rdi, 0               ; stdin
    mov rsi, buffer          ; buffer d'entrée
    mov rdx, 1024            ; taille maximale
    syscall
    
    ; Vérifier si la lecture a réussi
    test rax, rax
    js error_exit            ; Si erreur (négatif), sortir avec erreur
    jz is_palindrome         ; Si zéro octet lu, c'est un palindrome vide
    
    ; Garder la longueur dans r12
    mov r12, rax
    
    ; Préparer les pointeurs pour la comparaison
    mov r13, 0               ; r13 = index début
    mov r14, r12             ; r14 = index fin
    dec r14                  ; Ajuster pour index zéro
    
    ; Vérifier si le dernier caractère est un saut de ligne
    mov al, byte [buffer + r14]
    cmp al, 10               ; Comparer avec '\n'
    jne skip_newline_check
    
    ; Nous avons une nouvelle ligne à la fin, ne pas la considérer
    dec r14
    dec r12
    
skip_newline_check:
    ; Si la chaîne est vide après avoir retiré newline
    test r12, r12
    jz is_palindrome
    
compare_loop:
    ; Vérifier si nous avons terminé
    cmp r13, r14
    jge is_palindrome        ; Si les indices se croisent, c'est un palindrome
    
    ; Comparer les caractères
    mov al, byte [buffer + r13]  ; Caractère du début
    mov bl, byte [buffer + r14]  ; Caractère de la fin
    
    ; Convertir en minuscules pour une comparaison insensible à la casse
    call to_lower_case       ; Convertir al
    mov cl, al               ; Sauvegarder le résultat
    
    mov al, bl               ; Préparer le second caractère
    call to_lower_case       ; Convertir al
    
    ; Comparer les caractères après conversion
    cmp cl, al
    jne not_palindrome
    
    ; Avancer début, reculer fin
    inc r13
    dec r14
    jmp compare_loop
    
is_palindrome:
    ; Retourner 0 pour palindrome
    mov rax, 60              ; sys_exit
    xor rdi, rdi             ; code 0
    syscall
    
not_palindrome:
    ; Retourner 1 pour non-palindrome
    mov rax, 60              ; sys_exit
    mov rdi, 1               ; code 1
    syscall
    
error_exit:
    ; Sortir avec code d'erreur 2 pour erreur de lecture
    mov rax, 60              ; sys_exit
    mov rdi, 2               ; code 2
    syscall

; Fonction pour convertir un caractère en minuscule
; Entrée: AL = caractère
; Sortie: AL = caractère en minuscule
to_lower_case:
    cmp al, 'A'              ; Vérifier si c'est une majuscule
    jl .done
    cmp al, 'Z'
    jg .done
    
    add al, 32               ; Convertir en minuscule
    
.done:
    ret