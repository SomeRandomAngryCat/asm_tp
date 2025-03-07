
global _start
section .bss
    buffer resb 4096    ; Buffer pour stocker le fichier lu
section .data
    error_msg db "Erreur: impossible de trouver ou modifier le fichier", 10
    error_len equ $ - error_msg
    success_msg db "Patching réussi", 10
    success_len equ $ - success_msg
    new_str db "H4CK"    ; Nouvelle chaîne pour remplacer "1337"
    target_str db "1337" ; Chaîne à rechercher

section .text
_start:
    pop rax             ; Nombre d'arguments (argc)
    cmp rax, 2          ; Doit être 2 (programme + fichier)
    jne error_exit      ; Sinon, erreur

    pop rdi             ; Ignorer le nom du programme
    pop rdi             ; Charger le nom du fichier (argv[1])


    mov rax, 2          ; sys_open
    mov rsi, 2          ; O_RDWR (lecture + écriture)
    mov rdx, 0666o      ; Permissions (lecture + écriture)
    syscall


    test rax, rax
    js error_exit       ; Si erreur, afficher message et quitter
    mov r15, rax        ; Sauvegarder le descripteur de fichier


    mov rax, 0          ; sys_read
    mov rdi, r15        ; Descripteur de fichier
    mov rsi, buffer     ; Stocker le contenu dans buffer
    mov rdx, 4096       ; Lire max 4096 octets
    syscall


    test rax, rax
    js close_and_error  ; Si erreur, fermer et quitter

    mov r14, rax        ; Taille du fichier lue
    mov r12, 0          ; Position dans le buffer

search_loop:

    cmp r12, r14
    jge close_and_error  ; Si on a atteint la fin sans trouver, erreur

    ; Comparer avec "1337"
    lea rsi, [buffer + r12]  ; Position actuelle dans le buffer
    cmp dword [rsi], 0x37333331  ; "1337" en little-endian
    jne next_byte

    ; Remplacer par "H4CK"
    mov dword [rsi], 0x4B434834  ; "H4CK" en little-endian

    ; Repositionner au début du fichier
    mov rax, 8          ; sys_lseek
    mov rdi, r15        ; Descripteur de fichier
    mov rsi, 0          ; Offset au début
    mov rdx, 0          ; SEEK_SET
    syscall

    ; Vérifier si le positionnement a réussi
    test rax, rax
    js close_and_error  ; Si erreur, fermer et sortir

    ; Écrire le buffer modifié
    mov rax, 1          ; sys_write
    mov rdi, r15        ; Descripteur de fichier
    mov rsi, buffer     ; Contenu modifié
    mov rdx, r14        ; Taille du fichier
    syscall

    ; Afficher le message de succès
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    mov rsi, success_msg
    mov rdx, success_len
    syscall

    jmp close_and_exit  ; Tout s'est bien passé

next_byte:
    inc r12             ; Passer au prochain octet
    jmp search_loop     ; Continuer la recherche

error_exit:
    ; Afficher un message d'erreur
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    mov rsi, error_msg
    mov rdx, error_len
    syscall

    ; Quitter avec erreur
    mov rax, 60         ; sys_exit
    mov rdi, 1          ; Code de sortie 1 (erreur)
    syscall

close_and_error:
    ; Fermer le fichier avant de quitter en erreur
    mov rax, 3          ; sys_close
    mov rdi, r15
    syscall

    jmp error_exit

close_and_exit:
    ; Fermer le fichier avant de quitter proprement
    mov rax, 3          ; sys_close
    mov rdi, r15
    syscall

    ; Quitter avec succès
    mov rax, 60         ; sys_exit
    xor rdi, rdi        ; Code de sortie 0 (succès)
    syscall
