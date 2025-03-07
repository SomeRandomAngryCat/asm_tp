section .bss
    buffer resb 32          ; Buffer for input

section .text
    global _start

_start:
    ; Read input number
    mov rax, 0              ; sys_read
    mov rdi, 0              ; stdin
    mov rsi, buffer         ; buffer address
    mov rdx, 32             ; buffer size
    syscall
    
    ; Check if read was successful
    test rax, rax
    jle input_error         ; Error or EOF
    
    ; Convert string to integer
    mov rdi, buffer         ; Set buffer address
    call atoi               ; Convert to integer
    
    ; Check for conversion error
    cmp rax, -1             ; Check error code
    je invalid_input
    
    ; Store number in r12
    mov r12, rax
    
    ; Check if number is prime
    call is_prime
    
    ; Exit with appropriate code (0 if prime, 1 if not prime)
    mov rdi, rax            ; Set exit code
    mov rax, 60             ; sys_exit
    syscall

input_error:
    ; Exit with error code 2 (read error)
    mov rax, 60             ; sys_exit
    mov rdi, 2              ; error code 2
    syscall

invalid_input:
    ; Exit with error code 2 (invalid number)
    mov rax, 60             ; sys_exit
    mov rdi, 2              ; error code 2
    syscall

; Convert string to integer
; Input: RDI = string address
; Output: RAX = integer or -1 if error
atoi:
    xor rax, rax            ; Initialize result
    xor rcx, rcx            ; Initialize sign flag
    
    ; Skip whitespace
.skip_whitespace:
    movzx rdx, byte [rdi]   ; Get current character
    cmp rdx, ' '            ; Check for space
    je .next_whitespace
    cmp rdx, 9              ; Check for tab
    je .next_whitespace
    cmp rdx, 10             ; Check for newline
    je .next_whitespace
    cmp rdx, 13             ; Check for carriage return
    je .next_whitespace
    jmp .check_sign
    
.next_whitespace:
    inc rdi                 ; Next character
    jmp .skip_whitespace
    
.check_sign:
    ; Check for minus sign
    cmp byte [rdi], '-'
    jne .check_plus
    inc rdi                 ; Skip minus
    mov rcx, 1              ; Set sign flag
    jmp .check_digits
    
.check_plus:
    ; Check for plus sign (optional)
    cmp byte [rdi], '+'
    jne .check_digits
    inc rdi                 ; Skip plus
    
.check_digits:
    ; Ensure we have at least one digit
    movzx rdx, byte [rdi]   ; Get current character
    cmp rdx, '0'            ; Check if below '0'
    jl .error
    cmp rdx, '9'            ; Check if above '9'
    jg .error
    
.digits:
    movzx rdx, byte [rdi]   ; Get current character
    
    ; Check for end of string or non-digit
    cmp rdx, 0              ; Check for null terminator
    je .done
    cmp rdx, 10             ; Check for newline
    je .done
    cmp rdx, 13             ; Check for carriage return
    je .done
    
    ; Validate digit
    cmp rdx, '0'            ; Check if below '0'
    jl .error
    cmp rdx, '9'            ; Check if above '9'
    jg .error
    
    ; Convert digit
    sub rdx, '0'            ; ASCII to number
    imul rax, 10            ; Multiply by 10
    add rax, rdx            ; Add digit
    
    inc rdi                 ; Next character
    jmp .digits
    
.done:
    ; Check for more characters after end of number
    cmp byte [rdi], 0       ; Check for null
    je .apply_sign
    cmp byte [rdi], 10      ; Check for newline
    je .apply_sign
    cmp byte [rdi], 13      ; Check for carriage return
    je .apply_sign
    
    ; If there are any non-whitespace characters, it's an error
    movzx rdx, byte [rdi]   ; Get current character
    cmp rdx, ' '            ; Check for space
    je .next_trailing
    cmp rdx, 9              ; Check for tab
    je .next_trailing
    jmp .error
    
.next_trailing:
    inc rdi                 ; Next character
    jmp .done
    
.apply_sign:
    ; Handle sign
    test rcx, rcx
    jz .validate
    neg rax                 ; Negate if negative
    
.validate:
    ; Check for valid prime number (>=2)
    cmp rax, 2
    jl .error
    ret
    
.error:
    mov rax, -1             ; Return error code
    ret

; Check if number is prime
; Input: R12 = number to check
; Output: RAX = 0 if prime, 1 if not prime
is_prime:
    ; Handle special cases
    cmp r12, 2              ; 2 is prime
    je .is_prime
    cmp r12, 3              ; 3 is prime
    je .is_prime
    
    ; Check if number is even
    test r12, 1             ; Test least significant bit
    jz .not_prime           ; If even (except 2), not prime
    
    ; Check divisibility from 3 to sqrt(number)
    mov rcx, 3              ; Start testing from 3
    
.check_loop:
    ; Check if we've gone beyond sqrt(number)
    mov rax, rcx
    mul rax                 ; rax = rcx * rcx
    cmp rax, r12            ; Compare with number
    jg .is_prime            ; If rcx > sqrt(number), it's prime
    
    ; Check divisibility
    mov rax, r12
    xor rdx, rdx            ; Clear dividend high part
    div rcx                 ; Divide number by current divisor
    test rdx, rdx           ; Check remainder
    jz .not_prime           ; If divisible, not prime
    
    ; Try next odd number
    add rcx, 2
    jmp .check_loop
    
.is_prime:
    ; Number is prime
    xor rax, rax            ; Return 0
    ret
    
.not_prime:
    ; Number is not prime
    mov rax, 1              ; Return 1
    ret
