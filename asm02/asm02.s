section .bss
    buffer resb 3   

section .data
    msg db "1337", 10  ; 
    msg_len equ $ - msg

section .text
    global _start

_start:

    mov rax, 0         
    mov rdi, 0       
    mov rsi, buffer    
    mov rdx, 3         
    syscall


    mov al, [buffer]    
    cmp al, '4'         
    jne not_42         

    mov al, [buffer+1]  
    cmp al, '2'         
    jne not_42          


    mov rax, 1         
    mov rdi, 1         
    mov rsi, msg       
    mov rdx, msg_len   
    syscall


    mov rax, 60        
    xor rdi, rdi       
    syscall

not_42:

    mov rax, 60        
    mov rdi, 1         
    syscall
