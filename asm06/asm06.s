section .bss
    result_buffer resb 20   ; Buffer for result string

section .text
    global _start

_start:
    ; Check if we have exactly 2 parameters
    pop rcx                 ; Get argc
    cmp rcx, 3              ; Program name + 2 parameters = 3
    jne error_exit          ; If not 3, exit with error
    
    pop rcx                 ; Skip program name (argv[0])
    
    ; Get first number
    pop rcx                 ; Get argv[1] (first number string)
    call string_to_int
    push rax                ; Save first number
    
    ; Get second number
    pop rcx                 ; Get argv[2] (second number string)
    call string_to_int
    pop rbx                 ; Retrieve first number
    
    ; Add the numbers
    add rax, rbx
    
    ; Convert result to string
    mov rsi, result_buffer
    call int_to_string
    
    ; Display the result
    mov rax, 1              ; sys_write syscall number
    mov rdi, 1              ; stdout file descriptor
    mov rsi, result_buffer  ; string to write
    mov rdx, rcx            ; string length
    syscall
    
    ; Add newline
    mov byte [result_buffer], 10   ; Newline character
    mov rax, 1              ; sys_write syscall number
    mov rdi, 1              ; stdout file descriptor
    mov rsi, result_buffer  ; string with newline
    mov rdx, 1              ; length 1
    syscall
    
    ; Exit with success
    mov rax, 60             ; sys_exit syscall number
    xor rdi, rdi            ; exit code 0
    syscall

error_exit:
    ; Exit with error
    mov rax, 60             ; sys_exit syscall number
    mov rdi, 1              ; exit code 1
    syscall

; Convert string to integer
; Input: RCX = string address
; Output: RAX = integer value
string_to_int:
    xor rax, rax            ; Clear result
    xor rdx, rdx            ; Clear sign flag (0 = positive)
    
    ; Check if first character is a minus sign
    cmp byte [rcx], '-'
    jne .process_digits
    inc rcx                 ; Skip the minus sign
    mov rdx, 1              ; Set sign flag
    
.process_digits:
    xor rbx, rbx            ; Clear temp
    mov bl, [rcx]           ; Get current character
    test bl, bl             ; Check for null terminator
    jz .finalize
    
    sub bl, '0'             ; Convert from ASCII to numeric value
    imul rax, 10            ; Multiply current result by 10
    add rax, rbx            ; Add new digit
    
    inc rcx                 ; Move to next character
    jmp .process_digits
    
.finalize:
    ; Apply sign if needed
    test rdx, rdx
    jz .done
    neg rax                 ; Negate if negative
    
.done:
    ret

; Convert integer to string
; Input: RAX = integer, RSI = buffer
; Output: RCX = string length
int_to_string:
    push rbx
    push rsi
    
    xor rcx, rcx            ; Clear length counter
    
    ; Handle negative sign
    test rax, rax
    jns .positive
    neg rax                 ; Make positive
    mov byte [rsi], '-'     ; Add minus sign
    inc rsi                 ; Move buffer position
    inc rcx                 ; Increment length
    
.positive:
    mov rbx, 10             ; Divisor
    
    ; Special case for 0
    test rax, rax
    jnz .convert
    mov byte [rsi], '0'     ; Store '0'
    inc rsi                 ; Move buffer position
    inc rcx                 ; Increment length
    jmp .done
    
.convert:
    ; We'll build the string in reverse and then flip it
    mov r8, rsi             ; Save start position
    
.convert_loop:
    test rax, rax
    jz .reverse
    
    xor rdx, rdx
    div rbx                 ; Divide by 10
    add dl, '0'             ; Convert remainder to ASCII
    mov [rsi], dl           ; Store digit
    inc rsi                 ; Move buffer position
    inc rcx                 ; Increment length
    jmp .convert_loop
    
.reverse:
    mov r9, rcx             ; Save original length
    mov r10, r8             ; Start of digits
    
    ; Check for minus sign
    cmp byte [r10], '-'
    jne .start_reverse
    inc r10                 ; Skip minus sign
    dec r9                  ; Adjust length for reversal
    
.start_reverse:
    dec rsi                 ; Last digit position
    shr r9, 1               ; Half the length for swap count
    
.reverse_loop:
    test r9, r9
    jz .done
    
    mov dl, [r10]           ; Swap characters
    mov bl, [rsi]
    mov [r10], bl
    mov [rsi], dl
    
    inc r10                 ; Move start forward
    dec rsi                 ; Move end backward
    dec r9                  ; Decrement counter
    jmp .reverse_loop
    
.done:
    pop rsi                 ; Restore original buffer address
    pop rbx
    ret
