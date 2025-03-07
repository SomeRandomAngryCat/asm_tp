section .data
    patch db "H4CK"

section .text
    global _start

_start:
    mov rax, [rsp]          ; argc
    cmp rax, 2              ; Vérifie qu'on a bien exactement 1 argument
    jne exit_fail

    mov rdi, [rsp + 16]     ; argv[1] (nom du fichier)

    ; Ouvre le fichier (sys_open)
    mov rax, 2              ; sys_open
    mov rsi, 2              ; flags (O_RDWR)
    xor rdx, rdx            ; mode = 0
    syscall
    cmp rax, 0
    jl exit_fail            ; erreur ouverture

    mov rdi, rax            ; sauvegarde fd dans rdi

    ; Remet explicitement offset à 0 (début du fichier)
    mov rax, 8              ; sys_lseek
    xor rsi, rsi            ; offset 0
    xor rdx, rdx            ; SEEK_SET
    syscall

    ; Lire le fichier entier
    mov rax, 0              ; sys_read
    mov rsi, rsp            ; buffer temporaire
    mov rdx, 8192           ; lecture de 8K max (suffisant pour ELF standard)
    syscall

    mov rcx, rax            ; taille lue dans rcx
    mov rsi, rsp            ; pointeur vers buffer
    xor rbx, rbx

find_loop:
    cmp rcx, 4
    jl close_file
    mov eax, [rsi + rbx]
    cmp eax, 0x37333331     ; "1337" en little endian
    je patch_found
    inc rbx
    dec rcx
    jmp find_loop

patch_found:
    ; Déplace à nouveau offset exactement sur la chaîne trouvée
    mov rax, 8              ; sys_lseek
    mov rsi, rbx            ; offset trouvé
    mov rdx, 0              ; SEEK_SET
    syscall

    ; Écriture du patch ("H4CK")
    mov rax, 1              ; sys_write
    mov rsi, patch          ; données à écrire
    mov rdx, 4              ; 4 octets
    syscall

close_file:
    mov rax, 3              ; sys_close
    syscall

exit_ok:
    mov rax, 60
    xor rdi, rdi
    syscall

exit_fail:
    mov rax, 60
    mov rdi, 1
    syscall
