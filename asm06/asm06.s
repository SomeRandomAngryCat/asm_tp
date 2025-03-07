section .data
    usage_msg db "Usage: ./prog <int1> <int2>", 10, 0
    error_msg db "Erreur: paramètres invalides.", 10, 0
    result_msg db "Résultat: %d", 10, 0

section .text
    global main
    extern printf
    extern atoi

main:
    push rbp
    mov rbp, rsp

    ; Vérification du nombre d'arguments
    cmp rdi, 3                ; argc doit être exactement 3 (nom du prog + 2 args)
    jne print_usage

    ; Conversion du premier argument
    mov rsi, [rsi + 8]        ; argv[1]
    mov rdi, rsi
    call atoi
    mov rbx, rax              ; Stocke la 1ère valeur dans rbx

    ; Conversion du deuxième argument
    mov rsi, [rsp + 24]       ; argv[2]
    mov rdi, rsi
    call atoi
    mov rcx, rax              ; Stocke la 2ème valeur dans rcx

    ; Addition
    add rbx, rcx

    ; Affichage du résultat
    mov rdi, result_msg
    mov rsi, rbx
    xor rax, rax
    call printf

    mov eax, 0
    leave
    ret

; Gestion du cas où le nombre d'arguments est incorrect
print_usage:
    mov rdi, usage_msg
    xor rax, rax
    call printf
    mov eax, 1
    leave
    ret
