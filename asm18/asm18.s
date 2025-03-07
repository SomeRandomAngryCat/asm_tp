section .data
    ; Message à envoyer au serveur
    udp_msg db "Hello, server!", 0
    udp_msg_len equ $ - udp_msg - 1  ; Longueur du message (sans le 0 final)
    
    ; Structure sockaddr_in pour l'adresse de destination (127.0.0.1:1337)
    server_addr:
        server_family    dw 2         ; AF_INET
        server_port      dw 0x3905    ; Port 1337 en big-endian (5 39)
        server_ip        dd 0x0100007F ; 127.0.0.1 en little-endian
        server_zero      times 8 db 0 ; Padding
    
    ; Message d'erreur pour le timeout
    timeout_msg db "Timeout: no response from server", 10, 0
    timeout_msg_len equ $ - timeout_msg - 1
    
    ; Message indiquant réponse reçue
    message_prefix db "message: ", 0
    message_prefix_len equ $ - message_prefix - 1

section .bss
    buffer resb 1024            ; Buffer pour stocker la réponse
    socket_fd resq 1            ; Descripteur de fichier du socket

section .text
    global _start

_start:
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
    
    ; Configurer le timeout avec setsockopt
    mov rdi, rax                ; socket fd
    mov rsi, 1                  ; SOL_SOCKET
    mov rdx, 20                 ; SO_RCVTIMEO
    
    ; Préparer la structure timeval sur la pile
    sub rsp, 16                 ; Allouer de l'espace pour struct timeval
    mov qword [rsp], 1          ; tv_sec = 1 (1 seconde)
    mov qword [rsp+8], 0        ; tv_usec = 0
    
    mov r10, rsp                ; struct timeval *
    mov r8, 16                  ; sizeof(struct timeval)
    mov rax, 54                 ; sys_setsockopt
    syscall
    
    ; Retirer la structure timeval de la pile
    add rsp, 16
    
    ; Vérifier si setsockopt a réussi
    test rax, rax
    js socket_error
    
    ; Envoyer le message UDP
    mov rax, 44                 ; sys_sendto
    mov rdi, [socket_fd]        ; socket fd
    mov rsi, udp_msg            ; buffer
    mov rdx, udp_msg_len        ; length
    mov r10, 0                  ; flags
    mov r8, server_addr         ; server address
    mov r9, 16                  ; address length
    syscall
    
    ; Vérifier si sendto a réussi
    test rax, rax
    js socket_error
    
    ; Attendre et recevoir une réponse
    mov rax, 45                 ; sys_recvfrom
    mov rdi, [socket_fd]        ; socket fd
    mov rsi, buffer             ; buffer
    mov rdx, 1024               ; buffer size
    mov r10, 0                  ; flags
    mov r8, 0                   ; Pas besoin de sockaddr pour la source
    mov r9, 0                   ; Pas besoin de sockaddr_len
    syscall
    
    ; Vérifier si recvfrom a réussi
    test rax, rax
    js handle_timeout           ; Si erreur, c'est probablement un timeout
    
    ; Sauvegarder la longueur reçue
    mov r12, rax
    
    ; Afficher le préfixe "message: "
    mov rax, 1                  ; sys_write
    mov rdi, 1                  ; stdout
    mov rsi, message_prefix     ; buffer
    mov rdx, message_prefix_len ; length
    syscall
    
    ; Afficher la réponse reçue
    mov rax, 1                  ; sys_write
    mov rdi, 1                  ; stdout
    mov rsi, buffer             ; buffer
    mov rdx, r12                ; length
    syscall
    
    ; Ajouter un saut de ligne
    mov byte [buffer], 10       ; newline character
    mov rax, 1                  ; sys_write
    mov rdi, 1                  ; stdout
    mov rsi, buffer             ; buffer
    mov rdx, 1                  ; length
    syscall
    
    ; Fermer le socket
    mov rax, 3                  ; sys_close
    mov rdi, [socket_fd]        ; socket fd
    syscall
    
    ; Sortir avec succès
    mov rax, 60                 ; sys_exit
    xor rdi, rdi                ; code 0 (succès)
    syscall
    
handle_timeout:
    ; Afficher le message de timeout
    mov rax, 1                  ; sys_write
    mov rdi, 1                  ; stdout
    mov rsi, timeout_msg        ; buffer
    mov rdx, timeout_msg_len    ; length
    syscall
    
    ; Fermer le socket
    mov rax, 3                  ; sys_close
    mov rdi, [socket_fd]        ; socket fd
    syscall
    
    ; Sortir avec code d'erreur 1 (timeout)
    mov rax, 60                 ; sys_exit
    mov rdi, 1                  ; code 1 (timeout)
    syscall
    
socket_error:
    ; Sortir avec code d'erreur 1 (erreur socket)
    mov rax, 60                 ; sys_exit
    mov rdi, 1                  ; code 1 (erreur)
    syscall