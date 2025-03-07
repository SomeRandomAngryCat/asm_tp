section .text
    global _start

_start:
    ; Get argument count from stack
    pop rdi                 ; Get argc (number of arguments)
    cmp rdi, 2              ; Check if we have exactly 2 arguments (program name + parameter)
    jne no_parameter        ; If not 2 arguments, handle error case
    
    pop rsi                 ; Skip argv[0] (program name)
    pop rsi                 ; Get argv[1] (the string parameter)
    
    ; Calculate string length
    mov rdx, rsi            ; Copy string address to rdx
    mov rbx, rsi            ; Save original string address

find_length:
    cmp byte [rdx], 0       ; Check for null terminator
    je display_string       ; If found, we have the length
    inc rdx                 ; Move to next character
    jmp find_length         ; Continue loop
    
display_string:
    sub rdx, rbx            ; Calculate string length (current address - start address)
    
    ; Display the string
    mov rax, 1              ; syscall number for sys_write
    mov rdi, 1              ; file descriptor 1 is stdout
    mov rsi, rbx            ; string to write (our parameter)
                            ; rdx already contains the length
    syscall
    
    ; Exit with code 0 on success
    mov rax, 60             ; syscall number for sys_exit
    mov rdi, 0              ; exit with status code 0
    syscall

no_parameter:
    ; Exit with code 1 if no parameter is provided
    mov rax, 60             ; syscall number for sys_exit
    mov rdi, 1              ; exit with status code 1
    syscall