section .bss
    buffer resb 1024         ; Buffer pour stocker l'entrée
    output resb 1024         ; Buffer pour stocker le résultat

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
    jz empty_input           ; Si zéro octet lu, traiter comme entrée vide
    
    ; Garder la longueur dans r12
    mov r12, rax
    
    ; Chercher la fin de ligne pour s'assurer qu'on ne l'inverse pas
    mov rcx, rax             ; Copier la longueur dans rcx
    dec rcx                  ; Ajuster pour index zéro
    mov al, byte [buffer + rcx]
    cmp al, 10               ; Comparer avec '\n'
    jne no_newline
    
    ; Nous avons une nouvelle ligne à la fin, réduire la longueur
    dec r12
    
no_newline:
    ; Inverser la chaîne (r12 contient la longueur sans newline)
    xor rcx, rcx             ; rcx = index destination (0)
    mov rdx, r12             ; rdx = index source (longueur)
    dec rdx                  ; Ajuster pour commencer à la fin
    
    ; Si la chaîne est vide après avoir retiré newline
    test r12, r12
    jz empty_input
    
reverse_loop:
    ; Vérifier si nous avons terminé
    cmp rdx, -1
    je reverse_done
    
    ; Copier le caractère de la fin vers le début
    mov al, byte [buffer + rdx]  ; Lire de la fin
    mov byte [output + rcx], al  ; Écrire au début
    
    ; Avancer destination, reculer source
    inc rcx
    dec rdx
    jmp reverse_loop
    
reverse_done:
    ; Ajouter un retour à la ligne à la fin
    mov byte [output + r12], 10  ; '\n'
    inc r12                      ; Ajuster la longueur pour inclure newline
    
    ; Afficher la chaîne inversée
    mov rax, 1                   ; sys_write
    mov rdi, 1                   ; stdout
    mov rsi, output              ; buffer de sortie
    mov rdx, r12                 ; longueur (avec newline)
    syscall
    
    ; Sortir avec succès
    mov rax, 60                  ; sys_exit
    xor rdi, rdi                 ; code 0
    syscall
    
empty_input:
    ; Cas d'entrée vide - juste afficher une nouvelle ligne
    mov byte [output], 10        ; '\n'
    
    mov rax, 1                   ; sys_write
    mov rdi, 1                   ; stdout
    mov rsi, output              ; juste newline
    mov rdx, 1                   ; longueur 1
    syscall
    
    ; Sortir avec succès
    mov rax, 60                  ; sys_exit
    xor rdi, rdi                 ; code 0
    syscall
    
error_exit:
    ; Sortir avec code d'erreur
    mov rax, 60                  ; sys_exit
    mov rdi, 1                   ; code 1
    syscall
