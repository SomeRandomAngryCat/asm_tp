section .bss
    buffer resb 64          ; Buffer pour lire l'en-tête ELF

section .text
    global _start

_start:
    ; Vérifier si un nom de fichier a été fourni
    pop rcx                 ; Récupérer argc
    cmp rcx, 2              ; Vérifier qu'on a au moins un argument (programme + fichier)
    jl error_args           ; Si moins de 2 arguments, erreur
    
    pop rdi                 ; Ignorer argv[0] (nom du programme)
    pop rdi                 ; Récupérer argv[1] (nom du fichier)
    
    ; Ouvrir le fichier
    mov rax, 2              ; sys_open
    ; rdi contient déjà le nom du fichier
    mov rsi, 0              ; O_RDONLY
    xor rdx, rdx            ; Mode (non utilisé pour O_RDONLY)
    syscall
    
    ; Vérifier si l'ouverture a réussi
    test rax, rax
    js error_file           ; Si erreur (négatif), sortir avec erreur
    
    ; Sauvegarder le descripteur de fichier
    mov r12, rax
    
    ; Lire les premiers octets du fichier (en-tête ELF)
    mov rax, 0              ; sys_read
    mov rdi, r12            ; Descripteur de fichier
    mov rsi, buffer         ; Buffer de destination
    mov rdx, 64             ; Nombre d'octets à lire (suffisant pour l'en-tête ELF)
    syscall
    
    ; Vérifier si la lecture a réussi
    cmp rax, 64             ; On a besoin d'au moins 64 octets pour vérifier l'en-tête
    jl not_elf              ; Si on a lu moins, ce n'est pas un ELF valide
    
    ; Fermer le fichier (on n'en a plus besoin)
    mov rax, 3              ; sys_close
    mov rdi, r12            ; Descripteur de fichier
    syscall
    
    ; Vérifier le magic number ELF (premiers 4 octets)
    cmp dword [buffer], 0x464C457F  ; 0x7F 'E' 'L' 'F' en little-endian
    jne not_elf
    
    ; Vérifier si c'est un ELF 64 bits (octet 4)
    cmp byte [buffer+4], 2  ; 2 = 64 bits
    jne not_elf
    
    ; Vérifier l'endianness (octet 5)
    cmp byte [buffer+5], 1  ; 1 = little endian
    jne not_elf
    
    ; Vérifier la version ELF (octet 6)
    cmp byte [buffer+6], 1  ; Version ELF doit être 1
    jne not_elf
    
    ; Vérifier le type de fichier ELF (octets 16-17)
    cmp word [buffer+16], 2  ; 2 = exécutable, 3 = shared object
    je is_elf                ; Si c'est un exécutable, c'est bon
    cmp word [buffer+16], 3  ; Vérifier si c'est un shared object
    jne not_elf
    
is_elf:
    ; C'est un fichier ELF x64 valide
    mov rax, 60             ; sys_exit
    xor rdi, rdi            ; code 0 (succès)
    syscall
    
not_elf:
    ; Ce n'est pas un fichier ELF x64 valide
    mov rax, 60             ; sys_exit
    mov rdi, 1              ; code 1 (pas un ELF x64)
    syscall
    
error_file:
    ; Erreur lors de l'ouverture/lecture du fichier
    mov rax, 60             ; sys_exit
    mov rdi, 1              ; code 1 (erreur)
    syscall
    
error_args:
    ; Erreur: aucun nom de fichier fourni
    mov rax, 60             ; sys_exit
    mov rdi, 1              ; code 1 (erreur)
    syscall