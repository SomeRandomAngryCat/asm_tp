section .data
    hex_chars db "0123456789ABCDEF", 0

section .bss
    result resb 65          ; Buffer for result (up to 64 bits + null terminator)

section .text
    global _start

_start:
    ; Get argument count
    pop rcx                 ; Get argc
    cmp rcx, 2              ; Check if there's at least 1 argument
    je decimal_to_binary    ; If exactly 2 args (program + number), convert to binary
    cmp rcx, 3              ; Check if there are 2 arguments
    je check_mode           ; If 3 args (program + flag + number), check mode
    jmp error               ; Otherwise, error

check_mode:
    ; Check if second argument is "-b"
    pop rcx                 ; Skip program name
    pop rdi                 ; Get first argument (potential flag)
    
    ; Check if the argument is "-b"
    cmp byte [rdi], '-'
    jne error
    cmp byte [rdi+1], 'b'
    jne error
    cmp byte [rdi+2], 0     ; Check if string ends after "b"
    jne error
    
    ; Mode is hexadecimal, get the number
    pop rdi                 ; Get the number string
    call atoi               ; Convert to integer
    jmp decimal_to_hex      ; Convert to hexadecimal
    
decimal_to_binary:
    ; Mode is binary, get the number
    pop rcx                 ; Skip program name
    pop rdi                 ; Get number string
    call atoi               ; Convert to integer
    
    ; Check for error
    cmp rax, -1
    je error
    
    ; Convert to binary
    mov rdi, result         ; Output buffer
    mov rsi, rax            ; Number to convert
    call int_to_bin         ; Convert to binary
    
    ; Display the result
    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    mov rsi, result         ; result string
    mov rdx, r10            ; length (from int_to_bin)
    syscall
    
    ; Add newline
    mov byte [result], 10   ; Newline character
    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    mov rsi, result         ; newline
    mov rdx, 1              ; length
    syscall
    
    ; Exit successfully
    mov rax, 60             ; sys_exit
    xor rdi, rdi            ; exit code 0
    syscall
    
decimal_to_hex:
    ; Check for error
    cmp rax, -1
    je error
    
    ; Convert to hexadecimal
    mov rdi, result         ; Output buffer
    mov rsi, rax            ; Number to convert
    call int_to_hex         ; Convert to hexadecimal
    
    ; Display the result
    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    mov rsi, result         ; result string
    mov rdx, r10            ; length (from int_to_hex)
    syscall
    
    ; Add newline
    mov byte [result], 10   ; Newline character
    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    mov rsi, result         ; newline
    mov rdx, 1              ; length
    syscall
    
    ; Exit successfully
    mov rax, 60             ; sys_exit
    xor rdi, rdi            ; exit code 0
    syscall

error:
    ; Exit with error
    mov rax, 60             ; sys_exit
    mov rdi, 1              ; exit code 1
    syscall

; String to integer conversion
; Input: RDI = string address
; Output: RAX = integer or -1 if error
atoi:
    xor rax, rax            ; Initialize result
    xor rcx, rcx            ; Initialize sign flag
    
    ; Skip whitespace
    movzx rdx, byte [rdi]   ; Get current character
    cmp rdx, ' '            ; Check for space
    je .next_char
    
    ; Check for minus sign
    cmp byte [rdi], '-'
    jne .check_plus
    inc rdi                 ; Skip minus
    mov rcx, 1              ; Set sign flag
    jmp .check_first_digit
    
.check_plus:
    ; Check for plus sign (optional)
    cmp byte [rdi], '+'
    jne .check_first_digit
    inc rdi                 ; Skip plus
    
.check_first_digit:
    ; Ensure we have at least one digit
    movzx rdx, byte [rdi]   ; Get current character
    test rdx, rdx           ; Check for end of string
    jz .error               ; Error if empty
    cmp rdx, '0'            ; Check if below '0'
    jl .error
    cmp rdx, '9'            ; Check if above '9'
    jg .error
    
.process_digits:
    movzx rdx, byte [rdi]   ; Get current character
    
    ; Check for end of string
    test rdx, rdx           ; Check for null terminator
    jz .done
    
    ; Check if character is a digit
    cmp rdx, '0'            ; Check if below '0'
    jl .error
    cmp rdx, '9'            ; Check if above '9'
    jg .error
    
    ; Convert digit
    sub rdx, '0'            ; ASCII to number
    imul rax, 10            ; Multiply by 10
    add rax, rdx            ; Add digit
    
    inc rdi                 ; Next character
    jmp .process_digits
    
.next_char:
    inc rdi                 ; Skip whitespace
    jmp atoi                ; Restart
    
.done:
    ; Apply sign
    test rcx, rcx
    jz .exit
    neg rax                 ; Negate if negative
    
.exit:
    ret
    
.error:
    mov rax, -1             ; Return error code
    ret

; Integer to binary string conversion
; Input: RSI = number to convert, RDI = output buffer
; Output: buffer filled with binary string, R10 = length
int_to_bin:
    push rbx                ; Save registers
    push rcx
    push rdx
    
    mov rbx, rdi            ; Save buffer start
    xor rcx, rcx            ; Initialize counter
    
    ; Handle special case for 0
    test rsi, rsi
    jnz .convert
    
    mov byte [rdi], '0'     ; Store '0'
    inc rdi                 ; Move to next position
    inc rcx                 ; Increment counter
    jmp .done
    
.convert:
    mov rax, rsi            ; Copy number
    mov r8, 64              ; 64 bits maximum
    
    ; Skip leading zeros
.find_first_bit:
    test r8, r8             ; Check if we've gone through all bits
    jz .done
    
    bt rax, 63              ; Test the highest bit
    jc .process_bits        ; If set, start processing
    
    shl rax, 1              ; Shift left
    dec r8                  ; Decrement bit counter
    jmp .find_first_bit
    
.process_bits:
    test r8, r8             ; Check if we've gone through all remaining bits
    jz .done
    
    bt rax, 63              ; Test the highest bit
    jc .bit_set
    
    ; Bit is clear
    mov byte [rdi], '0'     ; Store '0'
    jmp .next_bit
    
.bit_set:
    ; Bit is set
    mov byte [rdi], '1'     ; Store '1'
    
.next_bit:
    inc rdi                 ; Move to next position
    inc rcx                 ; Increment counter
    shl rax, 1              ; Shift left
    dec r8                  ; Decrement bit counter
    jmp .process_bits
    
.done:
    mov r10, rcx            ; Return length
    pop rdx                 ; Restore registers
    pop rcx
    pop rbx
    ret

; Integer to hexadecimal string conversion
; Input: RSI = number to convert, RDI = output buffer
; Output: buffer filled with hex string, R10 = length
int_to_hex:
    push rbx                ; Save registers
    push rcx
    push rdx
    
    mov rbx, rdi            ; Save buffer start
    xor rcx, rcx            ; Initialize counter
    
    ; Handle special case for 0
    test rsi, rsi
    jnz .find_first_digit
    
    mov byte [rdi], '0'     ; Store '0'
    inc rdi                 ; Move to next position
    inc rcx                 ; Increment counter
    jmp .done
    
.find_first_digit:
    ; Find first non-zero nibble (4 bits)
    mov rax, rsi            ; Copy number
    mov r8, 16              ; 16 nibbles maximum (64 bits)
    
.find_first_nibble:
    test r8, r8             ; Check if we've gone through all nibbles
    jz .done
    
    mov rdx, rax            ; Copy current state
    shr rdx, 60             ; Get highest 4 bits
    and rdx, 0xF            ; Mask to just those 4 bits
    
    test rdx, rdx           ; Check if nibble is zero
    jnz .process_nibbles    ; If non-zero, start processing
    
    shl rax, 4              ; Shift left by 4 bits
    dec r8                  ; Decrement nibble counter
    jmp .find_first_nibble
    
.process_nibbles:
    test r8, r8             ; Check if we've gone through all remaining nibbles
    jz .done
    
    mov rdx, rax            ; Copy current state
    shr rdx, 60             ; Get highest 4 bits
    and rdx, 0xF            ; Mask to just those 4 bits
    
    ; Convert nibble to hex character
    mov dl, [hex_chars + rdx]   ; Get hex character
    mov [rdi], dl           ; Store hex character
    inc rdi                 ; Move to next position
    inc rcx                 ; Increment counter
    
    shl rax, 4              ; Shift left by 4 bits
    dec r8                  ; Decrement nibble counter
    jmp .process_nibbles
    
.done:
    mov r10, rcx            ; Return length
    pop rdx                 ; Restore registers
    pop rcx
    pop rbx
    ret