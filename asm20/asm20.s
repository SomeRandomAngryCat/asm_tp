section .data
    ; Messages
    listen_msg db "🦻 Listening on port 4242", 10, 0
    listen_msg_len equ $ - listen_msg - 1
    
    prompt db "Type a command: ", 0
    prompt_len equ $ - prompt - 1
    
    goodbye_msg db "Goodbye!", 10, 0
    goodbye_msg_len equ $ - goodbye_msg - 1
    
    pong_msg db "PONG", 10, 0
    pong_msg_len equ $ - pong_msg - 1
    
    ; Commandes
    cmd_ping db "PING", 0
    cmd_ping_len equ $ - cmd_ping - 1
    
    cmd_exit db "EXIT", 0
    cmd_exit_len equ $ - cmd_exit - 1
    
    cmd_reverse db "REVERSE ", 0
    cmd_reverse_len equ $ - cmd_reverse - 1
    
    cmd_echo db "ECHO ", 0
    cmd_echo_len equ $ - cmd_echo - 1
    
    ; Structure sockaddr_in pour l'adresse d'écoute (0.0.0.0:4242)
    server_addr:
        server_family    dw 2         ; AF_INET
        server_port      dw 0x9210    ; Port 4242 en big-endian (10 92)
        server_ip        dd 0         ; 0.0.0.0 (toutes les interfaces)
        server_zero      times 8 db 0 ; Padding

section .bss
    buffer resb 2048            ; Buffer pour stocker les commandes reçues
    reverse_buffer resb 2048    ; Buffer pour stocker les chaînes inversées
    client_addr resb 16         ; Buffer pour l'adresse client
    client_addr_len resd 1      ; Longueur de l'adresse client
    socket_fd resq 1            ; Descripteur de fichier du socket serveur
    client_fd resq 1            ; Descripteur de fichier du socket client

section .text
    global _start

_start:
    ; Créer un socket TCP
    mov rax, 41                 ; sys_socket
    mov rdi, 2                  ; AF_INET
    mov rsi, 1                  ; SOCK_STREAM (TCP)
    mov rdx, 0                  ; Protocol: 0 (IP)
    syscall
    
    ; Vérifier si la création du socket a réussi
    test rax, rax
    js socket_error
    
    ; Sauvegarder le descripteur de socket
    mov [socket_fd], rax
    
    ; Activer la réutilisation de l'adresse
    mov rdi, rax                ; socket fd
    mov rsi, 1                  ; SOL_SOCKET
    mov rdx, 2                  ; SO_REUSEADDR
    lea r10, [rsp-4]            ; Pointer vers un entier sur la pile
    mov dword [r10], 1          ; valeur = 1
    mov r8, 4                   ; sizeof(int)
    mov rax, 54                 ; sys_setsockopt
    syscall
    
    ; Lier le socket au port 4242 (toutes les interfaces)
    mov rax, 49                 ; sys_bind
    mov rdi, [socket_fd]        ; socket fd
    mov rsi, server_addr        ; struct sockaddr
    mov rdx, 16                 ; addrlen
    syscall
    
    ; Vérifier si bind a réussi
    test rax, rax
    js socket_error
    
    ; Mettre le socket en mode écoute
    mov rax, 50                 ; sys_listen
    mov rdi, [socket_fd]        ; socket fd
    mov rsi, 5                  ; backlog (nombre max de connexions en attente)
    syscall
    
    ; Vérifier si listen a réussi
    test rax, rax
    js socket_error
    
    ; Afficher le message d'écoute
    mov rax, 1                  ; sys_write
    mov rdi, 1                  ; stdout
    mov rsi, listen_msg         ; message
    mov rdx, listen_msg_len     ; longueur
    syscall
    
    ; Boucle principale: accepter les connexions
accept_loop:
    ; Accepter une connexion
    mov rax, 43                 ; sys_accept
    mov rdi, [socket_fd]        ; socket fd
    mov rsi, client_addr        ; client address
    lea rdx, [client_addr_len]  ; addrlen pointer
    syscall
    
    ; Vérifier si accept a réussi
    test rax, rax
    js socket_error
    
    ; Sauvegarder le descripteur de socket client
    mov [client_fd], rax
    
    ; Créer un processus fils pour gérer cette connexion
    mov rax, 57                 ; sys_fork
    syscall
    
    ; Vérifier le résultat de fork
    test rax, rax
    js socket_error             ; Erreur
    jz handle_client            ; Processus fils (rax = 0)
    
    ; Processus parent: fermer le socket client et continuer à accepter
    mov rax, 3                  ; sys_close
    mov rdi, [client_fd]        ; client fd
    syscall
    
    ; Continuer à accepter des connexions
    jmp accept_loop

handle_client:
    ; Le processus fils gère le client
client_loop:
    ; Envoyer le prompt au client
    mov rax, 1                  ; sys_write
    mov rdi, [client_fd]        ; client fd
    mov rsi, prompt             ; message
    mov rdx, prompt_len         ; longueur
    syscall
    
    ; Recevoir la commande du client
    mov rax, 0                  ; sys_read
    mov rdi, [client_fd]        ; client fd
    mov rsi, buffer             ; buffer
    mov rdx, 2048               ; buffer size
    syscall
    
    ; Vérifier si read a réussi
    test rax, rax
    jle client_disconnect       ; Si erreur ou 0 octets (client déconnecté)
    
    ; Ajouter un zéro à la fin pour terminer la chaîne
    mov byte [buffer + rax - 1], 0  ; Remplacer le saut de ligne par un 0
    
    ; Vérifier si c'est la commande PING
    mov rdi, buffer
    mov rsi, cmd_ping
    call strcmp
    test rax, rax
    jz handle_ping
    
    ; Vérifier si c'est la commande EXIT
    mov rdi, buffer
    mov rsi, cmd_exit
    call strcmp
    test rax, rax
    jz handle_exit
    
    ; Vérifier si c'est la commande REVERSE
    mov rdi, buffer
    mov rsi, cmd_reverse
    mov rdx, cmd_reverse_len
    call strncmp
    test rax, rax
    jz handle_reverse
    
    ; Vérifier si c'est la commande ECHO
    mov rdi, buffer
    mov rsi, cmd_echo
    mov rdx, cmd_echo_len
    call strncmp
    test rax, rax
    jz handle_echo
    
    ; Commande inconnue, ignorer et continuer
    jmp client_loop

handle_ping:
    ; Répondre avec PONG
    mov rax, 1                  ; sys_write
    mov rdi, [client_fd]        ; client fd
    mov rsi, pong_msg           ; message
    mov rdx, pong_msg_len       ; longueur
    syscall
    
    jmp client_loop

handle_exit:
    ; Répondre avec Goodbye!
    mov rax, 1                  ; sys_write
    mov rdi, [client_fd]        ; client fd
    mov rsi, goodbye_msg        ; message
    mov rdx, goodbye_msg_len    ; longueur
    syscall
    
    ; Fermer la connexion et terminer le processus fils
    jmp client_disconnect

handle_reverse:
    ; Extraire la chaîne à inverser (après "REVERSE ")
    mov rdi, buffer
    add rdi, cmd_reverse_len    ; Pointer après "REVERSE "
    
    ; Calculer la longueur de la chaîne
    mov rcx, 0                  ; Compteur
strlen_loop:
    mov al, [rdi + rcx]         ; Récupérer le caractère
    test al, al                 ; Vérifier si c'est la fin de la chaîne
    jz strlen_done
    inc rcx                     ; Incrémenter le compteur
    jmp strlen_loop
strlen_done:
    
    ; Inverser la chaîne
    lea rsi, [reverse_buffer]   ; Destination (buffer inversé)
    lea rdi, [buffer + cmd_reverse_len] ; Source (après "REVERSE ")
    mov rdx, rcx                ; Longueur
    call reverse_string
    
    ; Ajouter un saut de ligne
    mov byte [reverse_buffer + rcx], 10    ; Newline
    inc rcx                     ; Augmenter la longueur
    
    ; Envoyer la chaîne inversée
    mov rax, 1                  ; sys_write
    mov rdi, [client_fd]        ; client fd
    mov rsi, reverse_buffer     ; buffer
    mov rdx, rcx                ; longueur
    syscall
    
    jmp client_loop

handle_echo:
    ; Extraire la chaîne à renvoyer (après "ECHO ")
    mov rdi, buffer
    add rdi, cmd_echo_len       ; Pointer après "ECHO "
    
    ; Calculer la longueur de la chaîne
    mov rcx, 0                  ; Compteur
echo_strlen_loop:
    mov al, [rdi + rcx]         ; Récupérer le caractère
    test al, al                 ; Vérifier si c'est la fin de la chaîne
    jz echo_strlen_done
    inc rcx                     ; Incrémenter le compteur
    jmp echo_strlen_loop
echo_strlen_done:
    
    ; Ajouter un saut de ligne à la fin
    mov byte [rdi + rcx], 10    ; Newline
    inc rcx                     ; Augmenter la longueur
    
    ; Envoyer la chaîne telle quelle
    mov rax, 1                  ; sys_write
    mov rdi, [client_fd]        ; client fd
    mov rsi, buffer
    add rsi, cmd_echo_len       ; Pointer après "ECHO "
    mov rdx, rcx                ; longueur
    syscall
    
    jmp client_loop

client_disconnect:
    ; Fermer le socket client
    mov rax, 3                  ; sys_close
    mov rdi, [client_fd]        ; client fd
    syscall
    
    ; Terminer le processus fils
    mov rax, 60                 ; sys_exit
    xor rdi, rdi                ; exit code 0
    syscall

socket_error:
    ; Fermer le socket serveur si ouvert
    cmp qword [socket_fd], 0
    jz exit_error
    
    mov rax, 3                  ; sys_close
    mov rdi, [socket_fd]        ; socket fd
    syscall
    
exit_error:
    ; Sortir avec erreur
    mov rax, 60                 ; sys_exit
    mov rdi, 1                  ; error code
    syscall

; Fonction: comparer deux chaînes
; Entrée:  RDI = chaîne 1, RSI = chaîne 2
; Sortie:  RAX = 0 si égales, différent de 0 sinon
strcmp:
    push rcx                    ; Sauvegarder les registres
    push rsi
    push rdi
    
strcmp_loop:
    mov cl, [rdi]               ; Charger le caractère de chaîne 1
    cmp cl, [rsi]               ; Comparer avec chaîne 2
    jne strcmp_not_equal        ; Si différents, sortir
    
    test cl, cl                 ; Vérifier si c'est la fin de la chaîne
    jz strcmp_equal             ; Si oui, les chaînes sont égales
    
    inc rdi                     ; Passer au caractère suivant
    inc rsi
    jmp strcmp_loop
    
strcmp_equal:
    xor rax, rax                ; RAX = 0 (chaînes égales)
    jmp strcmp_done
    
strcmp_not_equal:
    mov rax, 1                  ; RAX != 0 (chaînes différentes)
    
strcmp_done:
    pop rdi                     ; Restaurer les registres
    pop rsi
    pop rcx
    ret

; Fonction: comparer les n premiers caractères de deux chaînes
; Entrée:  RDI = chaîne 1, RSI = chaîne 2, RDX = nombre de caractères
; Sortie:  RAX = 0 si les n premiers caractères sont égaux, différent de 0 sinon
strncmp:
    push rcx                    ; Sauvegarder les registres
    push rsi
    push rdi
    push rdx
    
    test rdx, rdx               ; Vérifier si n = 0
    jz strncmp_equal            ; Si oui, les chaînes sont considérées égales
    
strncmp_loop:
    mov cl, [rdi]               ; Charger le caractère de chaîne 1
    cmp cl, [rsi]               ; Comparer avec chaîne 2
    jne strncmp_not_equal       ; Si différents, sortir
    
    test cl, cl                 ; Vérifier si c'est la fin de la chaîne
    jz strncmp_equal            ; Si oui, les chaînes sont égales
    
    inc rdi                     ; Passer au caractère suivant
    inc rsi
    dec rdx                     ; Décrémenter le compteur
    jnz strncmp_loop            ; Continuer si pas encore atteint n
    
strncmp_equal:
    xor rax, rax                ; RAX = 0 (chaînes égales)
    jmp strncmp_done
    
strncmp_not_equal:
    mov rax, 1                  ; RAX != 0 (chaînes différentes)
    
strncmp_done:
    pop rdx                     ; Restaurer les registres
    pop rdi
    pop rsi
    pop rcx
    ret

; Fonction: inverser une chaîne
; Entrée:  RDI = chaîne source, RSI = chaîne destination, RDX = longueur
; Sortie:  Chaîne inversée dans RSI
reverse_string:
    push rcx                    ; Sauvegarder les registres
    push rdi
    push rsi
    push rdx
    
    add rdi, rdx                ; Pointer à la fin de la chaîne source
    dec rdi                     ; Ajuster pour pointer au dernier caractère
    
    xor rcx, rcx                ; Index dans la chaîne destination
    
reverse_loop:
    cmp rcx, rdx                ; Vérifier si on a copié tous les caractères
    jge reverse_done
    
    mov al, [rdi]               ; Récupérer le caractère (de la fin)
    mov [rsi + rcx], al         ; Stocker dans la destination (au début)
    
    dec rdi                     ; Décrémenter la source (de la fin vers le début)
    inc rcx                     ; Incrémenter la destination
    jmp reverse_loop
    
reverse_done:
    mov byte [rsi + rdx], 0     ; Ajouter le caractère nul de fin
    
    pop rdx                     ; Restaurer les registres
    pop rsi
    pop rdi
    pop rcx
    ret
