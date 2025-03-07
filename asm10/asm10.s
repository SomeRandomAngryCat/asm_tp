section .bss
    buffer resb 32          ; Buffer for result string

section .text
    global _start

_start:
    ; Check argument count
    pop rcx                 ; Get argc
    cmp rcx, 4              ; Program name + 3 parameters = 4
    jne argument_error      ; If not 4, handle error
    
    pop rcx                 ; Skip program name
    
    ; Get first number
    pop rdi                 ; Get first argument
    call atoi
    mov r12, rax            ; Store first number as current max
    
    ; Get second number
    pop rdi                 ; Get second argument
    call atoi
    
    ; Compare with current max
    cmp rax, r12
    jle check_third         ; If second <= max, skip update
    mov r12, rax            ; Update max
    
check_third:
    ; Get third number
    pop rdi                 ; Get third argument
    call atoi
    
    ; Compare with current max
    cmp rax, r12
    jle print_result        ; If third <= max, skip update
    mov r12, rax            ; Update max
    
print_result:
    ; Convert max to string for display
    mov rax, r12
    mov rdi, buffer
    call itoa
    
    ; Display result
    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    mov rsi, buffer         ; string buffer
    mov rdx, rcx            ; length from itoa
    syscall
    
    ; Display newline
    mov byte [buffer], 10   ; newline character
    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    mov rsi, buffer         ; buffer with newline
    mov rdx, 1              ; length 1
    syscall
    
    ; Exit with success
    mov rax, 60             ; sys_exit
    xor rdi, rdi            ; exit code 0
    syscall

argument_error:
    ; Exit with error code 1 (wrong number of arguments)
    mov rax, 60             ; sys_exit
    mov rdi, 1              ; exit code 1
    syscall

; Simple string to integer conversion
; Input: RDI = string pointer
; Output: RAX = integer value
atoi:
    xor rax, rax            ; Clear result
    xor rbx, rbx            ; Clear sign flag
    
    ; Check for minus sign
    cmp byte [rdi], '-'
    jne .check_plus
    mov rbx, 1              ; Set negative flag
    inc rdi                 ; Skip minus sign
    jmp .process_digits
    
.check_plus:
    cmp byte [rdi], '+'
    jne .process_digits
    inc rdi                 ; Skip plus sign
    
.process_digits:
    xor rcx, rcx            ; Clear digit
    mov cl, byte [rdi]      ; Get current character
    test cl, cl             ; Check for end of string
    jz .apply_sign
    
    sub cl, '0'             ; Convert ASCII to number
    imul rax, 10            ; Multiply current total by 10
    add rax, rcx            ; Add new digit
    
    inc rdi                 ; Move to next character
    jmp .process_digits
    
.apply_sign:
    test rbx, rbx
    jz .done
    neg rax                 ; Negate if negative
    
.done:
    ret

; Integer to string conversion
; Input: RAX = integer, RDI = output buffer
; Output: RCX = string length
itoa:
    push r8
    push r9
    
    mov r8, rdi             ; Save buffer start
    xor rcx, rcx            ; Initialize counter
    
    ; Handle negative numbers
    test rax, rax
    jns .positive
    neg rax                 ; Make positive
    mov byte [rdi], '-'     ; Place minus sign
    inc rdi                 ; Move past sign
    inc rcx                 ; Count the sign
    
.positive:
    ; Special case for 0
    test rax, rax
    jnz .convert
    mov byte [rdi], '0'     ; Store "0"
    inc rdi                 ; Move buffer position
    inc rcx                 ; Increment length
    jmp .done
    
.convert:
    mov r9, rdi             ; Save digit area start
    
    ; Convert digits in reverse order
.loop:
    test rax, rax
    jz .reverse
    
    xor rdx, rdx            ; Clear for division
    mov rbx, 10
    div rbx                 ; Divide by 10
    
    add dl, '0'             ; Convert to ASCII
    mov [rdi], dl           ; Store digit
    inc rdi                 ; Move buffer position
    inc rcx                 ; Increment length counter
    jmp .loop
    
.reverse:
    ; r9 = start of digits (after sign if any)
    ; rdi = one past last digit
    ; Need to reverse digits (not including sign)
    
    dec rdi                 ; Point to last digit
    
.reverse_loop:
    cmp r9, rdi             ; Check if we're done
    jae .done               ; If start >= end, we're done
    
    mov al, [r9]            ; Swap characters
    mov bl, [rdi]
    mov [r9], bl
    mov [rdi], al
    
    inc r9                  ; Move start forward
    dec rdi                 ; Move end backward
    jmp .reverse_loop
    
.done:
    pop r9
    pop r8
    ret
