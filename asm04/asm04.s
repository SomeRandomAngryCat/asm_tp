section .bss
    buffer resb 32          ; Buffer to store input string

section .text
    global _start

_start:
    ; Read input number
    mov rax, 0              ; syscall number for sys_read
    mov rdi, 0              ; file descriptor 0 is stdin
    mov rsi, buffer         ; buffer to read into
    mov rdx, 32             ; read up to 32 bytes
    syscall
    
    ; Convert ASCII to integer
    xor rcx, rcx            ; Clear RCX (will use as our number)
    xor rbx, rbx            ; Clear RBX (will use as index)
    
convert_loop:
    movzx rdx, byte [buffer + rbx]  ; Load current character
    
    ; Check for termination (newline or null)
    cmp rdx, 10             ; Check for newline
    je check_parity
    cmp rdx, 0              ; Check for null terminator
    je check_parity
    
    ; Check if character is a digit
    cmp rdx, '0'
    jl invalid_input
    cmp rdx, '9'
    jg invalid_input
    
    ; Convert character to digit and add to number
    sub rdx, '0'            ; Convert ASCII to digit value
    imul rcx, 10            ; Multiply current number by 10
    add rcx, rdx            ; Add new digit to number
    
    inc rbx                 ; Move to next character
    jmp convert_loop
    
check_parity:
    ; Check if number is even (test bit 0)
    test rcx, 1             ; Test least significant bit
    jz even_number          ; If bit 0 is 0, number is even
    
    ; Odd number - return 1
    mov rax, 60             ; syscall number for sys_exit
    mov rdi, 1              ; exit with status code 1
    syscall
    
even_number:
    ; Even number - return 0
    mov rax, 60             ; syscall number for sys_exit
    mov rdi, 0              ; exit with status code 0
    syscall
    
invalid_input:
    ; Invalid input - return 2 (changed from 1 to match requirements)
    mov rax, 60             ; syscall number for sys_exit
    mov rdi, 2              ; exit with status code 2
    syscall
