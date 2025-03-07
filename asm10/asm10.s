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
    cmp rax, -1             ; Check for conversion error
    je input_error          ; If error, handle it
    mov r12, rax            ; Store first number in r12 (current max)
    
    ; Get second number
    pop rdi                 ; Get second argument string
    call string_to_int      ; Convert to integer
    cmp rax, -1             ; Check for conversion error
    je input_error          ; If error, handle it
    
    ; Compare with current max (r12)
    cmp rax, r12            ; Compare with current max
    jle skip_second         ; If second <= first, skip update
    mov r12, rax            ; Update max
    
skip_second:
    ; Get third number
    pop rdi                 ; Get third argument string
    call string_to_int      ; Convert to integer
    cmp rax, -1             ; Check for conversion error
    je input_error          ; If error, handle it
    
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
; Output: RAX = integer or -1 if error
string_to_int:
    xor rax, rax            ; Clear result
    xor r8, r8              ; Clear sign flag (0 = positive)
    xor rcx, rcx            ; Clear digit counter
    
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
    movzx rdx, byte [rdi]
    cmp rdx, 0              ; Check for end of string
    je .error               ; Error if no digits
    cmp rdx, '0'
    jl .error               ; Error if below '0'
    cmp rdx, '9'
    jg .error               ; Error if above '9'
    
.convert:
    movzx rdx, byte [rdi]   ; Get current character
    cmp rdx, 0              ; Check for end of string
    je .finish
    
    ; Validate digit
    cmp rdx, '0'
    jl .error               ; Error if not a digit
    cmp rdx, '9'
    jg .error
    
    ; Convert digit
    sub rdx, '0'            ; Convert ASCII to digit
    imul rax, 10            ; Multiply current result by 10
    add rax, rdx            ; Add new digit
    
    inc rdi                 ; Move to next character
    inc rcx                 ; Increment digit counter
    jmp .convert
    
.finish:
    ; Apply sign if needed
    cmp r8, 1
    jne .success
    neg rax                 ; Negate result if negative
    
.success:
    ret                     ; Return integer in RAX
    
.error:
    mov rax, -1             ; Return error code
    ret

; Convert integer to string
; Input: RAX = integer, RDI = output buffer
; Output: RAX = length of string
int_to_string:
    push rbx                ; Save registers
    push rcx
    push rdx
    
    mov rcx, rdi            ; Save buffer start
    mov rbx, 10             ; Divisor
    
    ; Handle negative numbers
    cmp rax, 0
    jge .positive
    
    neg rax                 ; Make positive
    mov byte [rdi], '-'     ; Store minus sign
    inc rdi                 ; Move past sign
    
.positive:
    mov r9, 0               ; Digit counter
    
    ; Handle special case for 0
    cmp rax, 0
    jne .convert
    
    mov byte [rdi], '0'     ; Store '0'
    inc rdi                 ; Move to next position
    inc r9                  ; Increment counter
    jmp .done
    
.convert:
    ; Convert each digit in reverse order
    mov r10, rdi            ; Save current position
    
.convert_loop:
    cmp rax, 0
    je .reverse
    
    xor rdx, rdx            ; Clear for division
    div rbx                 ; Divide by 10
    
    add dl, '0'             ; Convert remainder to ASCII
    mov [rdi], dl           ; Store digit
    inc rdi                 ; Move to next position
    inc r9                  ; Increment counter
    
    jmp .convert_loop
    
.reverse:
    ; Number of digits is in r9
    ; If negative, adjust buffer position
    cmp byte [rcx], '-'
    jne .setup_reverse
    
    inc rcx                 ; Skip minus sign
    dec r9                  ; Adjust count
    
.setup_reverse:
    mov rdi, rcx            ; Start position
    mov rsi, rcx
    add rsi, r9
    dec rsi                 ; End position
    
    shr r9, 1               ; Half the count for swapping
    
.reverse_loop:
    cmp r9, 0
    je .restore
    
    mov al, [rdi]           ; Swap characters
    mov bl, [rsi]
    mov [rdi], bl
    mov [rsi], al
    
    inc rdi                 ; Move start forward
    dec rsi                 ; Move end backward
    dec r9                  ; Decrement counter
    jmp .reverse_loop
    
.restore:
    ; Check if the number was negative
    cmp byte [rcx-1], '-'
    jne .compute_length
    dec rcx                 ; Move back to include minus sign
    
.compute_length:
    mov rax, r10            ; Current buffer position
    sub rax, rcx            ; Calculate length
    inc rax                 ; Adjust for current position
    
.done:
    pop rdx                 ; Restore registers
    pop rcx
    pop rbx
    ret