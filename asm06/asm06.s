section .bss
    buffer resb 20          ; Buffer for storing the result string

section .data
    error_msg db "Error: Requires exactly two numeric parameters", 10
    error_len equ $ - error_msg

section .text
    global _start

_start:
    ; Check if we have exactly 3 arguments (program name + 2 parameters)
    pop rcx                 ; Get argc
    cmp rcx, 3              ; Check if we have 3 arguments
    jne parameter_error     ; If not, handle error
    
    ; Skip program name
    pop rcx                 ; Skip argv[0]
    
    ; Get first parameter and convert to integer
    pop rcx                 ; Get argv[1]
    call atoi               ; Convert to integer
    push rax                ; Save first number
    
    ; Get second parameter and convert to integer
    pop rcx                 ; Get argv[2]
    call atoi               ; Convert to integer
    pop rbx                 ; Get first number from stack
    
    ; Add the numbers
    add rax, rbx            ; rax = rax + rbx
    
    ; Convert the result to string for displaying
    mov rdi, buffer
    call itoa
    
    ; Display the result
    mov rdx, rax            ; rax contains the length of result string
    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    mov rsi, buffer         ; result string
    syscall
    
    ; Display newline
    mov byte [buffer], 10   ; newline character
    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    mov rsi, buffer         ; string with newline
    mov rdx, 1              ; length 1
    syscall
    
    ; Exit successfully
    mov rax, 60             ; sys_exit
    xor rdi, rdi            ; status 0
    syscall

; Simple error handler
parameter_error:
    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    mov rsi, error_msg      ; error message
    mov rdx, error_len      ; message length
    syscall
    
    mov rax, 60             ; sys_exit
    mov rdi, 1              ; status 1
    syscall

; Convert ASCII string to integer
; Input: RCX = string address
; Output: RAX = integer
atoi:
    push rbx
    push rdx
    push rsi
    mov rsi, rcx            ; Move string pointer to RSI
    xor rax, rax            ; Clear result
    xor rbx, rbx            ; Clear sign flag
    
    ; Check for sign
    mov dl, [rsi]
    cmp dl, '-'
    jne .process_digits
    mov rbx, 1              ; Set sign flag
    inc rsi                 ; Skip sign
    
.process_digits:
    movzx rdx, byte [rsi]   ; Get character
    test rdx, rdx           ; Check for null
    jz .done
    cmp rdx, '0'            ; Check if below '0'
    jl .invalid
    cmp rdx, '9'            ; Check if above '9'
    jg .invalid
    
    sub rdx, '0'            ; Convert to number
    imul rax, 10            ; rax *= 10
    add rax, rdx            ; rax += digit
    
    inc rsi                 ; Next character
    jmp .process_digits
    
.done:
    test rbx, rbx           ; Check sign flag
    jz .exit
    neg rax                 ; Negate if negative
    
.exit:
    pop rsi
    pop rdx
    pop rbx
    ret
    
.invalid:
    mov rax, 60             ; sys_exit
    mov rdi, 2              ; status 2 - invalid number
    syscall

; Convert integer to ASCII string
; Input: RAX = integer, RDI = output buffer
; Output: RAX = length of string
itoa:
    push rbx
    push rcx
    push rdx
    push rdi
    
    mov rcx, rdi            ; Save buffer start
    mov rbx, 10             ; Divisor
    xor r8, r8              ; Length counter
    
    ; Handle negative numbers
    test rax, rax
    jns .convert
    neg rax                 ; Make positive
    mov byte [rdi], '-'     ; Add minus sign
    inc rdi                 ; Move past sign
    inc r8                  ; Increase length
    
.convert:
    ; Special case for 0
    test rax, rax
    jnz .divide_loop
    mov byte [rdi], '0'     ; Store '0'
    inc rdi
    inc r8
    jmp .done
    
.divide_loop:
    test rax, rax
    jz .reverse
    
    xor rdx, rdx            ; Clear for division
    div rbx                 ; Divide by 10
    add dl, '0'             ; Convert to ASCII
    mov [rdi], dl           ; Store digit
    inc rdi                 ; Next position
    inc r8                  ; Increase length
    jmp .divide_loop
    
.reverse:
    mov rdi, rcx            ; Reset to buffer start
    
    ; Check if negative (has minus sign)
    cmp byte [rdi], '-'
    jne .setup_reverse
    inc rdi                 ; Skip minus sign
    
.setup_reverse:
    mov rax, rdi            ; Start position (after minus sign if present)
    mov rcx, r8             ; Total length
    cmp byte [rdi-1], '-'   ; Check for minus sign
    jne .continue_setup
    dec rcx                 ; Adjust length for minus sign
    
.continue_setup:
    add rdi, rcx            ; End position
    dec rdi                 ; Adjust to last character
    shr rcx, 1              ; Number of swaps = length/2
    
.reverse_loop:
    test rcx, rcx
    jz .done
    
    mov bl, [rax]           ; Swap characters
    mov dl, [rdi]
    mov [rax], dl
    mov [rdi], bl
    
    inc rax                 ; Move start forward
    dec rdi                 ; Move end backward
    dec rcx                 ; Counter--
    jmp .reverse_loop
    
.done:
    mov rax, r8             ; Return length
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    ret