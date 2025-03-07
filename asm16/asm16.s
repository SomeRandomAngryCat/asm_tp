; asm16 : Patcher asm01 pour afficher "H4CK" au lieu de "1337"
; Pour Linux x86-64, en utilisant les appels système (syscall)

section .data
    ; La chaîne de remplacement "H4CK" (4 octets)
    patch db "H4CK"
    ; La chaîne recherchée "1337" n'est pas utilisée directement en mémoire,
    ; car nous comparerons sur 4 octets avec la valeur 0x37333131 (little-endian)

section .bss
    ; Tampon de 4 octets pour lire la séquence
    buf resb 4

section .text
global _start
_start:
    ; Récupérer argv[1] depuis la pile.
    ; Lorsqu'on entre dans _start, la pile contient : argc (à [rsp]) puis argv (à [rsp+8]).
    mov rdi, [rsp+8]    ; rdi pointe sur argv
    mov rbx, [rdi+8]    ; rbx = argv[1]
    ; Si aucun argument n'est passé, quitter (code erreur 1)
    test rbx, rbx
    jz exit_error

    ; Ouvrir le fichier en lecture/écriture (flag O_RDWR = 2)
    mov rax, 2          ; syscall open
    mov rdi, rbx        ; chemin du fichier
    mov rsi, 2          ; O_RDWR
    syscall
    ; Si l'ouverture a échoué, quitter
    cmp rax, 0
    jl exit_error
    mov r12, rax        ; sauvegarder le descripteur de fichier dans r12

    ; Lire les 4 premiers octets dans le tampon
    mov rax, 0          ; syscall read
    mov rdi, r12        ; descripteur de fichier
    lea rsi, [buf]      ; adresse du tampon
    mov rdx, 4          ; lire 4 octets
    syscall
    cmp rax, 4
    jne exit_error      ; si on ne lit pas 4 octets, erreur

    ; On considère qu'on se trouve après 4 octets lus.
    mov r13, 4         ; compteur d'octets lus

search_loop:
    ; Comparer les 4 octets du tampon avec "1337"
    ; "1337" en ASCII = 0x31,0x33,0x33,0x37, ce qui correspond en little-endian à 0x37333131.
    mov eax, dword [buf]
    cmp eax, 0x37333131
    je found

    ; Si non trouvé, on décale le tampon d'un octet :
    ; Le contenu de buf[1..3] devient buf[0..2]
    mov al, byte [buf+1]
    mov byte [buf], al
    mov al, byte [buf+2]
    mov byte [buf+1], al
    mov al, byte [buf+3]
    mov byte [buf+2], al

    ; Lire le prochain octet dans buf[3]
    mov rax, 0          ; syscall read
    mov rdi, r12
    lea rsi, [buf+3]
    mov rdx, 1          ; lire 1 octet
    syscall
    cmp rax, 1
    jne not_found_end   ; fin de fichier si lecture < 1
    inc r13             ; incrémenter le compteur d'octets lus
    jmp search_loop

found:
    ; La séquence "1337" a été trouvée ; il faut revenir en arrière de 4 octets.
    ; Ici, r13 contient le nombre total d'octets lus (la position actuelle).
    ; Utilisation de lseek (syscall 8) pour repositionner le curseur.
    mov rax, 8          ; syscall lseek
    mov rdi, r12        ; descripteur
    mov rsi, -4         ; déplacement de -4 octets par rapport de la position courante (SEEK_CUR = 1 par défaut)
    mov rdx, 1          ; indication de SEEK_CUR (1)
    syscall

    ; Écrire "H4CK" dans le fichier (4 octets)
    mov rax, 1          ; syscall write
    mov rdi, r12
    lea rsi, [patch]
    mov rdx, 4
    syscall

    ; Fermer le fichier (syscall close, numéro 3)
    mov rax, 3
    mov rdi, r12
    syscall

    ; Quitter avec le code de retour 0
    mov rax, 60         ; syscall exit
    xor rdi, rdi
    syscall

not_found_end:
    ; Si la séquence n'a pas été trouvée, on ferme le fichier et quitte avec code erreur 1.
    mov rax, 3
    mov rdi, r12
    syscall
exit_error:
    mov rax, 60
    mov rdi, 1
    syscall
