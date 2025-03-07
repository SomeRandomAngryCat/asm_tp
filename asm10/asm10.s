section .bss
    result_buffer resb 32   ; Buffer for storing result as string

section .text
    global _start

_start:
    ; Check if we have exactly 3 arguments
    pop rcx                 ; Get argc
    cmp rcx, 4              ; Program name + 3 parameters = 4
    jne argument_error      ; If not 4, handle error
    
    pop rcx                 ; Skip program name (argv[0])
    
    ; Get first number
    pop rdi                 ; Get first argument string
    call string_to_int      ; Convert to integer
    cmp rdx, 0              ; Check for conversion error
    jne input_error         ; If error, handle it
    mov r12, rax            ; Store first number in r12 (current max)
    
    ; Get second number
    pop rdi                 ; Get second argument string
    call string_to_int      ; Convert to integer
    cmp rdx, 0              ; Check for conversion error
    jne input_error         ; If error, handle it
    
    ; Compare with current max (r12)
    cmp rax, r12            ; Compare with current max
    jle skip_second         ; If second <= first, skip update
    mov r12, rax            ; Update max
    
skip_second:
    ; Get third number
    pop rdi                 ; Get third argument string
    call string_to_int      ; Convert to integer
    cmp rdx, 0              ; Check for conversion error
    jne input_error         ; If error, handle it
    
    ; Compare with current max (r12)
    cmp rax, r12            ; Compare with current max
    jle skip_third          ; If third <= current max, skip update
    mov r12, rax            ; Update max
    
skip_third:
    ; Convert max value to string
    mov rax, r12            ; Put max value in rax for conversion
    mov rdi, result_buffer  ; Output buffer
    call int_to_string      ; Convert to string
    mov r13, rax            ; Save string length
    
    ; Display the result
    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    mov rsi, result_buffer  ; Result string
    mov rdx, r13            ; String length
    syscall
    
    ; Add newline
    mov byte [result_buffer], 10   ; Newline character
    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    mov rsi, result_buffer  ; Newline string
    mov rdx, 1              ; Length 1
    syscall
    
    ; Exit successfully
    mov rax, 60             ; sys_exit
    mov rdi, 0              ; Exit code 0
    syscall

argument_error:
    ; Exit with error code 1 (incorrect number of arguments)
    mov rax, 60             ; sys_exit
    mov rdi, 1              ; Exit code 1
    syscall

input_error:
    ; Exit with error code 2 (invalid input)
    mov rax, 60             ; sys_exit
    mov rdi, 2              ; Exit code 2
    syscall

; Convert string to integer
; Input: RDI = string address
; Output: RAX = integer, RDX = 0 if successful, 1 if error
string_to_int:
    xor rax, rax            ; Clear result
    xor r8, r8              ; Clear sign flag (0 = positive)
    xor rdx, rdx            ; Clear error flag
    
    ; Check for empty string
    cmp byte [rdi], 0
    je .error
    
    ; Check for sign
    cmp byte [rdi], '-'
    jne .check_plus
    mov r8, 1               ; Set sign flag (negative)
    inc rdi                 ; Skip minus sign
    jmp .validate_first
    
.check_plus:
    cmp byte [rdi], '+'
    jne .validate_first
    inc rdi                 ; Skip plus sign
    
.validate_first:
    ; Ensure first character is a digit
    movzx rcx, byte [rdi]
    test rcx, rcx           ; Check for end of string
    jz .error               ; Error if no digits
    cmp rcx, '0'
    jl .error               ; Error if below '0'
    cmp rcx, '9'
    jg .error               ; Error if above '9'
    
.convert:
    movzx rcx, byte [rdi]   ; Get current character
    test rcx, rcx           ; Check for end of string
    jz .finish
    
    ; Validate digit
    cmp rcx, '0'
    jl .error               ; Error if not a digit
    cmp rcx, '9'
    jg .error
    
    ; Convert digit
    sub rcx, '0'            ; Convert ASCII to digit
    imul rax, 10            ; Multiply current result by 10
    add rax, rcx            ; Add new digit
    
    inc rdi                 ; Move to next character
    jmp .convert
    
.finish:
    ; Apply sign if needed
    test r8, r8
    jz .success
    neg rax                 ; Negate result if negative
    
.success:
    xor rdx, rdx            ; No error
    ret                     ; Return integer in RAX
    
.error:
    mov rdx, 1              ; Set error flag
    ret

; Convert integer to string
; Input: RAX = integer, RDI = output buffer
; Output: RAX = length of string
int_to_string:
    push rbx                ; Save registers
    push rcx
    push rdx
    push r8
    push r9
    
    mov r8, rdi             ; Save buffer start
    xor r9, r9              ; Initialize length counter
    
    ; Handle negative numbers
    test rax, rax
    jns .positive
    
    neg rax                 ; Make positive
    mov byte [rdi], '-'     ; Store minus sign
    inc rdi                 ; Move past sign
    inc r9                  ; Include sign in length
    
.positive:
    ; Special case for 0
    test rax, rax
    jnz .convert
    
    mov byte [rdi], '0'     ; Store '0'
    inc rdi                 ; Move buffer position
    inc r9                  ; Increment length
    jmp .done
    
.convert:
    mov rbx, rdi            ; Save start of digit area
    
    ; Convert digits (in reverse order)
.convert_loop:
    test rax, rax
    jz .reverse
    
    xor rdx, rdx            ; Clear for division
    mov rcx, 10             ; Divisor
    div rcx                 ; Divide by 10
    
    add dl, '0'             ; Convert remainder to ASCII
    mov [rdi], dl           ; Store digit
    inc rdi                 ; Next buffer position
    inc r9                  ; Increment length
    
    jmp .convert_loop
    
.reverse:
    ; Now we need to reverse the digits (not including sign)
    mov rcx, rdi            ; End position + 1
    dec rcx                 ; Adjust to end position
    
    ; If we have a negative sign, adjust the start position
    cmp byte [r8], '-'
    jne .reverse_setup
    inc rbx                 ; Skip the sign for reversal
    
.reverse_setup:
    mov rdx, rcx            ; End position
    sub rdx, rbx            ; Calculate number of digits - 1
    shr rdx, 1              ; Divide by 2 (for pairs to swap)
    inc rdx                 ; Adjust count
    
.reverse_loop:
    dec rdx                 ; Decrement counter
    jz .done                ; Done when counter is 0
    
    mov al, [rbx]           ; Get start character
    mov ah, [rcx]           ; Get end character
    mov [rbx], ah           ; Swap characters
    mov [rcx], al
    
    inc rbx                 ; Move start forward
    dec rcx                 ; Move end backward
    jmp .reverse_loop
    
.done:
    mov rax, r9             ; Return length
    
    pop r9                  ; Restore registers
    pop r8
    pop rdx
    pop rcx
    pop rbx
    ret
