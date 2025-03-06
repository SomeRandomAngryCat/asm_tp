section .bss
    buffer resb 16         ; Buffer pour stocker l'entrée

section .text
    global _start

_start:
    ; Lire l'entrée depuis stdin
    mov rax, 0          ; syscall read
    mov rdi, 0          ; stdin
    mov rsi, buffer     ; buffer où stocker l'entrée
    mov rdx, 16         ; taille maximale à lire
    syscall

    ; Convertir le caractère ASCII en nombre
    movzx rbx, byte [buffer]
    sub rbx, '0'        ; Convertir ASCII en valeur numérique

    ; Vérifier si le nombre est pair
    test rbx, 1         ; Vérifier le bit le moins significatif
    jnz exit_odd        ; Si le bit est 1, le nombre est impair

exit_even:
    ; Retourner 0 (nombre pair)
    mov rax, 60         ; syscall exit
    mov rdi, 0          ; code de retour 0 (pair)
    syscall

exit_odd:
    ; Retourner 1 (nombre impair)
    mov rax, 60         ; syscall exit
    mov rdi, 1          ; code de retour 1 (impair)
    syscall