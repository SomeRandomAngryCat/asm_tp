section .data
    message db "1337", 10    ; The message to display with newline character
    messageLen equ $ - message
    
section .bss
    inputBuffer resb 16     ; Buffer to hold input (increased size for safety)

section .text
    global _start

_start:
    ; Read input from stdin
    mov rax, 0              ; syscall number for sys_read
    mov rdi, 0              ; file descriptor 0 is stdin
    mov rsi, inputBuffer    ; buffer to read into
    mov rdx, 16             ; read up to 16 bytes
    syscall
    
    ; Check if input length is at least 2 bytes (for "42" + possible newline)
    cmp rax, 2
    jl incorrect_input
    
    ; Check if first character is '4'
    cmp byte [inputBuffer], '4'
    jne incorrect_input
    
    ; Check if second character is '2'
    cmp byte [inputBuffer + 1], '2'
    jne incorrect_input
    
    ; Check if third character is newline or null (to ensure it's exactly "42")
    cmp byte [inputBuffer + 2], 10  ; Newline character
    je correct_input
    cmp byte [inputBuffer + 2], 0   ; Null terminator
    je correct_input
    jmp incorrect_input             ; If third character is neither newline nor null
    
correct_input:
    ; If input is "42", display "1337" and return 0
    mov rax, 1              ; syscall number for sys_write
    mov rdi, 1              ; file descriptor 1 is stdout
    mov rsi, message        ; message to write
    mov rdx, messageLen     ; message length
    syscall

    ; Exit with status code 0
    mov rax, 60             ; syscall number for sys_exit
    mov rdi, 0              ; exit with status code 0
    syscall

incorrect_input:
    ; Exit with status code 1
    mov rax, 60             ; syscall number for sys_exit
    mov rdi, 1              ; exit with status code 1
    syscall
