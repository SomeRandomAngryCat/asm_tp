section .bss
    buffer resb 32          ; Buffer for reading input
    result resb 32          ; Buffer for storing result string

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
    
    ; Calculate sum of integers below the given number
    call sum_below
    
    ; Convert result to string for display
    mov rdi, result         ; Output buffer
    call itoa               ; Convert to string
    mov r14, rax            ; Save length
    
    ; Display the result
    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    mov rsi, result         ; result string
    mov rdx, r14            ; length
    syscall
    
    ; Add newline
    mov byte [result], 10   ; Newline character
    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    mov rsi, result         ; newline string
    mov rdx, 1              ; length
    syscall
    
    ; Exit with code 0
    mov rax, 60             ; sys_exit
    xor rdi, rdi            ; exit code 0
    syscall

input_error:
    ; Exit with error code 1 (read error)
    mov rax, 60             ; sys_exit
    mov rdi, 1              ; error code 1
    syscall

invalid_input:
    ; Exit with error code 1 (invalid number)
    mov rax, 60             ; sys_exit
    mov rdi, 1              ; error code 1
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
    ; Validate number is positive
    test rax, rax
    js .error
    ret
    
.error:
    mov rax, -1             ; Return error code
    ret

; Calculate sum of integers below a given number
; Input: R12 = number
; Output: RAX = sum
sum_below:
    ; Check if number is 0 or 1
    cmp r12, 1
    jle .zero_result
    
    ; Formula: sum = (n-1) * n / 2
    mov rax, r12
    dec rax                 ; n-1
    mul r12                 ; (n-1) * n
    mov rcx, 2
    div rcx                 ; (n-1) * n / 2
    ret
    
.zero_result:
    xor rax, rax            ; Return 0
    ret

; Convert integer to string
; Input: RAX = integer, RDI = output buffer
; Output: RAX = length of string
itoa:
    push rdi                ; Save buffer address
    push rbx                ; Save registers
    push rcx
    push rdx
    push r8
    
    ; Handle 0 specially
    test rax, rax
    jnz .not_zero
    
    mov byte [rdi], '0'     ; Store '0'
    mov rax, 1              ; Length = 1
    jmp .done
    
.not_zero:
    mov rbx, 10             ; Divisor
    xor rcx, rcx            ; Digit counter
    mov r8, rdi             ; Save start of buffer
    
    ; Convert digits in reverse order
.convert_loop:
    test rax, rax
    jz .reverse
    
    xor rdx, rdx            ; Clear remainder
    div rbx                 ; Divide by 10
    
    add dl, '0'             ; Convert to ASCII
    mov [rdi], dl           ; Store digit
    inc rdi                 ; Move to next position
    inc rcx                 ; Increment counter
    
    jmp .convert_loop
    
.reverse:
    mov rax, rcx            ; Save length
    dec rdi                 ; Point to last digit
    
    ; r8 = start, rdi = end
    mov rdx, rcx
    shr rdx, 1              ; Half the count
    
.reverse_loop:
    test rdx, rdx
    jz .done
    
    mov bl, [r8]            ; Swap digits
    mov cl, [rdi]
    mov [r8], cl
    mov [rdi], bl
    
    inc r8                  ; Move start forward
    dec rdi                 ; Move end backward
    dec rdx                 ; Decrement counter
    jmp .reverse_loop
    
.done:
    pop r8                  ; Restore registers
    pop rdx
    pop rcx
    pop rbx
    pop rdi
    ret