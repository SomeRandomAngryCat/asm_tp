section .data
    ; Fichier où enregistrer les messages
    filename db "messages", 0
    
    ; Message d'écoute
    listen_msg db "🦻 Listening on port 1337", 10, 0
    listen_msg_len equ $ - listen_msg - 1
    
    ; Structure sockaddr_in pour l'adresse d'écoute (0.0.0.0:1337)
    server_addr:
        server_family    dw 2         ; AF_INET
        server_port      dw 0x3905    ; Port 1337 en big-endian (5 39)
        server_ip        dd 0         ; 0.0.0.0 (toutes les interfaces)
        server_zero      times 8 db 0 ; Padding

section .bss
    buffer resb 2048            ; Buffer pour stocker les messages reçus
    socket_fd resq 1            ; Descripteur de fichier du socket
    file_fd resq 1              ; Descripteur de fichier pour messages

section .text
    global _start

_start:
    ; Ouvrir/créer le fichier messages
    mov rax, 2                  ; sys_open
    mov rdi, filename           ; nom du fichier
    mov rsi, 0102o              ; O_CREAT | O_WRONLY | O_APPEND
    mov rdx, 0666o              ; Permissions: rw-rw-rw-
    syscall
    
    ; Vérifier si l'ouverture du fichier a réussi
    test rax, rax
    js file_error
    
    ; Sauvegarder le descripteur de fichier
    mov [file_fd], rax
    
    ; Créer un socket UDP
    mov rax, 41                 ; sys_socket
    mov rdi, 2                  ; AF_INET
    mov rsi, 2                  ; SOCK_DGRAM (UDP)
    mov rdx, 0                  ; Protocol: 0 (IP)
    syscall
    
    ; Vérifier si la création du socket a réussi
    test rax, rax
    js socket_error
    
    ; Sauvegarder le descripteur de socket
    mov [socket_fd], rax
    
    ; Lier le socket au port 1337 (toutes les interfaces)
    mov rax, 49                 ; sys_bind
    mov rdi, [socket_fd]        ; socket fd
    mov rsi, server_addr        ; struct sockaddr
    mov rdx, 16                 ; addrlen
    syscall
    
    ; Vérifier si bind a réussi
    test rax, rax
    js socket_error
    
    ; Afficher le message d'écoute
    mov rax, 1                  ; sys_write
    mov rdi, 1                  ; stdout
    mov rsi, listen_msg         ; message
    mov rdx, listen_msg_len     ; longueur
    syscall
    
    ; Boucle principale: recevoir et enregistrer les messages
listen_loop:
    ; Recevoir un message UDP
    mov rax, 45                 ; sys_recvfrom
    mov rdi, [socket_fd]        ; socket fd
    mov rsi, buffer             ; buffer
    mov rdx, 2048               ; buffer size
    mov r10, 0                  ; flags
    mov r8, 0                   ; addr (NULL, on n'a pas besoin de l'adresse source)
    mov r9, 0                   ; addrlen
    syscall
    
    ; Vérifier si recvfrom a réussi
    test rax, rax
    js socket_error
    
    ; Sauvegarder la longueur du message
    mov r12, rax
    
    ; Ajouter un saut de ligne à la fin du message
    mov byte [buffer + r12], 10 ; newline
    inc r12                     ; Augmenter la longueur pour inclure newline
    
    ; Écrire le message dans le fichier
    mov rax, 1                  ; sys_write
    mov rdi, [file_fd]          ; file fd
    mov rsi, buffer             ; buffer
    mov rdx, r12                ; length (+1 pour le saut de ligne)
    syscall
    
    ; Vérifier si l'écriture a réussi
    test rax, rax
    js file_error
    
    ; Synchroniser le fichier pour s'assurer que les données sont écrites
    mov rax, 74                 ; sys_fsync
    mov rdi, [file_fd]          ; file fd
    syscall
    
    ; Continuer à écouter
    jmp listen_loop

socket_error:
    ; Fermer le fichier si ouvert
    cmp qword [file_fd], 0
    jz skip_file_close
    
    mov rax, 3                  ; sys_close
    mov rdi, [file_fd]          ; file fd
    syscall
    
skip_file_close:
    ; Fermer le socket si ouvert
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

file_error:
    ; Fermer le socket si ouvert
    cmp qword [socket_fd], 0
    jz exit_error
    
    mov rax, 3                  ; sys_close
    mov rdi, [socket_fd]        ; socket fd
    syscall
    
    ; Sortir avec erreur
    jmp exit_error