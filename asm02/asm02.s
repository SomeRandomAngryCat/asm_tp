section .data
    message db "1337", 10    ; The message to display with newline character
    messageLen equ $ - message
    inputBuffer db 3          ; Buffer to hold input (2 chars for "42" + null terminator)
    correctInput db "42", 0   ; The expected input string

section .text
    global _start

_start:
    ; Read input from stdin
    mov rax, 0              ; syscall number for sys_read
    mov rdi, 0              ; file descriptor 0 is stdin
    mov rsi, inputBuffer    ; buffer to read into
    mov rdx, 3              ; read up to 3 bytes (2 for "42" + 1 for potential newline)
    syscall

    ; Check if input starts with "42"
    mov rsi, inputBuffer
    mov rdi, correctInput
    mov rcx, 2              ; Compare the first 2 bytes
    repe cmpsb              ; Compare string byte by byte
    jne incorrect_input     ; Jump if not equal

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
