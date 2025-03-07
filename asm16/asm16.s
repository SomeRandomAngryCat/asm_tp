section .data
    patch db "H4CK"

section .bss
    buffer resb 8192

section .text
    global _start

_start:
    mov rax, [rsp]          ; argc
    cmp rax, 2              ; exactement 1 argument attendu
    jne exit_fail

    mov rdi, [rsp + 16]     ; argv[1] (nom du fichier)

    ; ouvrir le fichier
    mov rax, 2              ; sys_open
    mov rsi, 2              ; O_RDWR
    xor rdx, rdx            ; mode = 0
    syscall
    cmp rax, 0
    jl exit_fail

    mov r12, rax            ; stocke fd dans r12

    ; lire tout le fichier depuis le début
    mov rax, 0              ; sys_read
    mov rdi, r12            ; fd
    mov rsi, buffer         ; buffer
    mov rdx, 8192           ; taille
    syscall
    cmp rax, 0
    jle close_file

    mov rcx, rax            ; taille lue
    xor rbx, rbx

search_loop:
    cmp rcx, 4
    jl close_file

    mov eax, [buffer + rbx]
    cmp eax, 0x37333331     ; "1337" en little endian
    je patch_found

    inc rbx
    dec rcx
    jmp search_loop

patch_found:
    ; replacer offset au bon endroit
    mov rax, 8              ; sys_lseek
    mov rdi, r12            ; fd
    mov rsi, rbx            ; offset trouvé
    xor rdx, rdx            ; SEEK_SET
    syscall

    ; écrire le patch
    mov rax, 1              ; sys_write
    mov rdi, r12            ; fd
    mov rsi, patch          ; "H4CK"
    mov rdx, 4              ; 4 octets
    syscall

close_file:
    mov rax, 3              ; sys_close
    mov rdi, r12            ; fd
    syscall

exit_ok:
    mov rax, 60
    xor rdi, rdi
    syscall

exit_fail:
    mov rax, 60
    mov rdi, 1
    syscall
