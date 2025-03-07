section .bss
    buffer resb 32          ; Buffer for output

section .text
    global _start

_start:
    pop rax                 ; Get argc
    cmp rax, 3              ; Check if we have exactly 3 arguments
    jne error               ; If not, handle error

    pop rax                 ; Skip argv[0] (program name)
    
    ; Get first number
    pop rdi                 ; Get first parameter
    call atoi               ; Convert to integer
    mov r10, rax            ; Store first number in r10
    
    ; Get second number
    pop rdi                 ; Get second parameter
    call atoi               ; Convert to integer
    
    ; Add numbers
    add rax, r10            ; Add the two numbers
    
    ; Convert result to string
    mov rdi, buffer         ; Set buffer address
    call itoa               ; Convert to string
    mov rdx, rax            ; Length of string
    
    ; Print the result
    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    mov rsi, buffer         ; String to print
                            ; rdx already has length
    syscall
    
    ; Print newline
    mov byte [buffer], 10   ; Newline character
    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    mov rsi, buffer         ; String (just newline)
    mov rdx, 1              ; Length of 1
    syscall
    
    ; Exit with code 0
    mov rax, 60             ; sys_exit
    xor rdi, rdi            ; code 0
    syscall

error:
    ; Exit with code 1
    mov rax, 60             ; sys_exit
    mov rdi, 1              ; code 1
    syscall

; Convert string to integer
; Input: RDI = string address
; Output: RAX = integer
atoi:
    xor rax, rax            ; Initialize result
    xor rcx, rcx            ; Initialize sign flag
    
    ; Check for minus sign
    cmp byte [rdi], '-'
    jne .digits
    inc rdi                 ; Skip minus
    mov rcx, 1              ; Set sign flag
    
.digits:
    movzx rdx, byte [rdi]   ; Get current character
    test rdx, rdx           ; Check for null terminator
    jz .done
    
    ; Convert digit
    sub rdx, '0'            ; ASCII to number
    imul rax, 10            ; Multiply by 10
    add rax, rdx            ; Add digit
    
    inc rdi                 ; Next character
    jmp .digits
    
.done:
    ; Handle sign
    test rcx, rcx
    jz .exit
    neg rax                 ; Negate if negative
    
.exit:
    ret

; Convert integer to string
; Input: RAX = integer, RDI = buffer
; Output: RAX = length
itoa:
    push rbx
    push r12
    mov r12, rdi            ; Save buffer address
    
    ; Handle negative
    test rax, rax
    jns .positive
    neg rax                 ; Make positive
    mov byte [r12], '-'     ; Store minus
    inc r12                 ; Increment buffer
    
.positive:
    mov rbx, rax            ; Copy number to rbx
    mov rcx, 10             ; Base 10
    
    ; Count digits by dividing
    xor r8, r8              ; Digit counter
    mov rax, rbx            ; Get number
    
    ; Special case for 0
    test rax, rax
    jnz .count
    mov byte [r12], '0'     ; Store '0'
    inc r12                 ; Move buffer
    inc r8                  ; Count digit
    jmp .done
    
.count:
    test rax, rax
    jz .convert
    xor rdx, rdx            ; Clear for division
    div rcx                 ; Divide by 10
    inc r8                  ; Count digit
    jmp .count
    
.convert:
    ; Convert digit by digit, right to left
    mov rax, rbx            ; Restore number
    add r12, r8             ; Move to end of buffer
    dec r12                 ; Adjust (insert right to left)
    
.convert_loop:
    test rax, rax
    jz .finish
    xor rdx, rdx            ; Clear for division
    div rcx                 ; Divide by 10
    add dl, '0'             ; Convert to ASCII
    mov [r12], dl           ; Store digit
    dec r12                 ; Move left
    jmp .convert_loop
    
.finish:
    ; r8 has the digit count
    ; Check if we had a negative sign
    cmp byte [rdi], '-'
    jne .done
    inc r8                  ; Count the sign
    
.done:
    mov rax, r8             ; Return length
    pop r12
    pop rbx
    ret
