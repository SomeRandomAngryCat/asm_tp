section .text
    global _start

_start:
    ; Récupérer le nombre d'arguments
    pop rdi             ; rdi = argc (nombre d'arguments)
    cmp rdi, 2          ; Vérifier s'il y a au moins 2 arguments (nom du programme + paramètre)
    jl exit             ; S'il n'y a pas assez d'arguments, sortir
    
    ; Ignorer le nom du programme (premier argument)
    pop rsi             ; Ignorer argv[0] (nom du programme)
    
    ; Récupérer le paramètre à afficher
    pop rsi             ; rsi = argv[1] (le paramètre à afficher)
    
    ; Calculer la longueur de la chaîne
    mov rdx, 0          ; Compteur de longueur
count_loop:
    cmp byte [rsi + rdx], 0  ; Vérifier si on a atteint la fin de la chaîne
    je print            ; Si oui, passer à l'affichage
    inc rdx             ; Sinon, incrémenter le compteur
    jmp count_loop      ; Continuer à compter
    
print:
    ; Afficher la chaîne
    mov rax, 1          ; syscall write
    mov rdi, 1          ; stdout
    ; rsi contient déjà l'adresse de la chaîne
    ; rdx contient déjà la longueur de la chaîne
    syscall
    
exit:
    ; Sortir avec le code de retour 0
    mov rax, 60         ; syscall exit
    mov rdi, 0          ; code de retour 0
    syscall