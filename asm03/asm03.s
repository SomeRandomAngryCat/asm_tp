section .data
    message db "1337", 10    ; The message to display with newline character
    messageLen equ $ - message
    correctParam db "42", 0   ; The expected parameter

section .text
    global _start

_start:
    ; Get the argument count from the stack
    pop rdi                 ; Get argc (number of arguments)
    cmp rdi, 2              ; Check if we have exactly 2 arguments (program name + 1 parameter)
    jne incorrect_param     ; If not, jump to incorrect_param
    
    pop rsi                 ; Skip argv[0] (program name)
    pop rsi                 ; Get argv[1] (first parameter)
    
    ; Check if first parameter is "42"
    mov rdi, correctParam   ; Load address of correct parameter
    
    ; Compare first character
    mov al, byte [rsi]
    cmp al, byte [rdi]
    jne incorrect_param
    
    ; Compare second character
    mov al, byte [rsi + 1]
    cmp al, byte [rdi + 1]
    jne incorrect_param
    
    ; Check if third character is null (to ensure it's exactly "42")
    cmp byte [rsi + 2], 0
    jne incorrect_param
    
    ; If parameter is "42", display "1337" and return 0
    mov rax, 1              ; syscall number for sys_write
    mov rdi, 1              ; file descriptor 1 is stdout
    mov rsi, message        ; message to write
    mov rdx, messageLen     ; message length
    syscall

    ; Exit with status code 0
    mov rax, 60             ; syscall number for sys_exit
    mov rdi, 0              ; exit with status code 0
    syscall

incorrect_param:
    ; Exit with status code 1
    mov rax, 60             ; syscall number for sys_exit
    mov rdi, 1              ; exit with status code 1
    syscall