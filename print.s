;------------------------------------------------
; printf() function implementation.
; Copywhat (C) 2022 Denis Dedkov

global print

;------------------------------------------------
; print stdcall to cdecl adapter
;------------------------------------------------
print:
        pop rax         ; Get return address

        push r9         ; Push first stdcall arguments
        push r8         ;        
        push rcx        ;
        push rdx        ;
        push rsi        ;
        push rdi        ;

        mov r10, rax    ; Save return address
        call __print    

        push r10
        ret 6 * 8
;------------------------------------------------
;------------------------------------------------

;------------------------------------------------
; __print(fmt, ...)
;------------------------------------------------
; Loads the data from the given locations, converts 
; them to character string equivalents and writes 
; the results to the output stream 1.
;
; Calling convention: cdecl
;
; Parameters:
;
;   fmt - pointer to a null-terminated multibyte string 
;	  specifying how to interpret the data 
;
;   ... - arguments specifying data to print. 
;
;
; Following conversion specifiers supported:
;
;   +===+============================+
;   | % | 	Explanation          |
;   +===+============================+
;   | c | single character           |
;   +---+----------------------------+
;   | s | character string           |
;   +---+----------------------------+
;   | d | decimal representation     |
;   +---+----------------------------+
;   | x | hexadecimal representation |
;   +---+----------------------------+
;   | o | octal representation       |
;   +---+----------------------------+
;   | b | binary representation      |
;   +---+----------------------------+
;
; IMPORTANT! Internal buffer overflow 
; is undefined behaviour!
;

%define write  0x1
%define stdout 0x1
%define arg(id) [rbp + 16 + 8 * id]

section .text
__print:
        cld
        push rbp
        mov rbp, rsp

        xor r8, r8		; Initialize args counter.
        mov rsi, arg(0)		; Get fmt string.
        mov rdi, prbuf		; Set dest to printf buffer.
        
.copy:	
        lodsb			; Read character from fmt string
        cmp al, '%'		; and check if it is a format keyword.
        je .format		; Copy character otherwise.
        stosb			; 
        
        test al, al		; Leave if the character copied was
        jnz .copy		; a null terminator.
                                
        mov rdx, rdi		; Calculate prbuf length being used. 
        sub rdx, prbuf		; 
        
        mov rsi, prbuf		; Call system 64bit write syscall.
        mov rdi, stdout         ; 	       
        mov rax, write          ;        
        syscall                 ;	        		

        mov rax, r8		; Return number of processed arguments	
        pop rbp			
        ret			
                                
.format:				
        xor rax, rax		; Get format specifier.
        lodsb			; Make sure that it is not '%'. 
        cmp al, '%'		; 
        je .pct			;
        
        lea rdx, [rax - 'b']	; Normalize format to use jump table
        cmp rdx, 'x' - 'b'	; later. Jump to default label in   
        ja .def 		; case of overflow.

        inc r8			; Get next argument and call 
        mov rax, arg(r8)	; suitable function by jump table.
        jmp [.jmptab + 8 * rdx] ;
        

;------------------------------------------------
; Jump table handlers:
; Note! rax - function parameter. 

.pct:	
.chr:
        stosb			
        jmp .copy	
.dec:
        call itoa10
        jmp .copy
.hex:
        mov cl,  0x4		; Shift: 16 = 2^4.
        mov rbx, 0xf		; Mask:  00001111.
        call itoa2x		; 
        jmp .copy
.oct:
        mov cl,  0x3		; Shift:  8 = 2^3.
        mov rbx, 0x7		; Mask:  00000111.
        call itoa2x		;
        jmp .copy
.bin:
        mov cl,  0x1		; Shift:  2 = 2^1. 
        mov rbx, 0x1		; Mask:  00000001.
        call itoa2x		;	
        jmp .copy
.str:	
        push rsi		
        mov rsi, rax
        call strcpy
        pop rsi
        jmp .copy
.def:
        mov rcx, 0xdead		; TODO: error handling.
        jmp .copy		; 	

%define dup(from, to) times (to - from - 1)	
section .data
.jmptab:
                dq .bin
                dq .chr
                 dq .dec
dup('d', 'o') 	dq .def
                dq .oct
dup('o', 's')	dq .def
                dq .str
dup('s', 'x')	dq .def
                dq .hex	
%undef dup
section .bss
prbuf 	resb 1024
section .text

%undef arg
%undef write
%undef stdout
;------------------------------------------------
;------------------------------------------------


;------------------------------------------------
; strcpy()
;------------------------------------------------
; Copies null-terminated string from one buffer
; to another.
;
; Expect: rsi - null terminated string copy from
;	  rdi - buffer copy to
;
; Return: rdi - address of the character 
;		following the symbol
;
; Destrs: rax rsi rdi
;
; Important! Null-terminator is not copied. 
;------------------------------------------------
section .text
strcpy:
        cld
        xor rax, rax		
.copy:	
        lodsb		
        test al, al
        jz .stop
                        
        stosb	
        jmp .copy
        
.stop:
        ret
;------------------------------------------------
;------------------------------------------------


;------------------------------------------------
; itoa10()
;------------------------------------------------
; Converts an integer value to a string using 
; the base of 10.
;
; Expect: rax - integer to convert
;	  rdi - buffer to store string
;
; Return: rdi - address of the character 
;		following the last digit
;
; Destrs: rax rbx rdx rdi  
;------------------------------------------------
section .text
itoa10:
        cld
        push rsi
                                
        test rax, rax			; Take into account the first
        jns .init 			; sign bit. Place '-' character
        neg rax				; if value is negative and make
        mov byte [rdi], '-'		; it positive.
        inc rdi				;
        
.init:
        mov rsi, rdi			; Save write initial position.	
        mov rbx, 10			; Set base	
        
.savedgt:	
        xor rdx, rdx			; Save remainder to the print
         div rbx				; buffer.
        add rdx, '0'			;
         mov byte [rdi], dl		;
        inc rdi				;
         
         test rax, rax
        jnz .savedgt	

        mov rbx, rdi			; Can't use rdi, due it is being
        dec rbx				; returned.
        
.reverse:
        mov al, byte [rsi]		; Reverse digits in memory.
        xchg byte [rbx], al 		; 
        mov byte [rsi], al		;
        dec rbx				;
        inc rsi				;
        
        cmp rbx, rsi
        ja .reverse
                
        pop rsi	
        ret
;------------------------------------------------
;------------------------------------------------


;------------------------------------------------
; itoa2x()
;------------------------------------------------
; Converts an integer value to a string using 
; the base of the power of 2.
;
; Expect: rax - integer to convert
;	   cl - base (power of 2)
;	  rbx - mask 
;	  rdi - buffer to store string
;
; Return: rdi - address of the character 
;		following the last digit. 
;
; Destrs: rax rbx rdx rdi  
;------------------------------------------------
section .text
itoa2x:
        cld
        push rsi
        mov rdx, rax			; Move to make similar to itoa10.
        mov rsi, rdi			; Save write initial position.
        
.savedgt:	 
        mov rax, rdx			; Save remainder to the print 	
         and rax, rbx			; buffer.
        mov al, byte [xlattab + rax]	;
         shr rdx, cl 			;
         stosb				;
         
         test rdx, rdx			; Leave when all digits are 
        jnz .savedgt			; saved.

        mov rbx, rdi			; Can't use rdi, due it is being
        dec rbx				; returned.
        
.reverse:
        mov al, byte [rsi]		; Reverse digits in memory.
        xchg byte [rbx], al 		; 
        mov byte [rsi], al		;
        dec rbx				;
        inc rsi				;
        
        cmp rbx, rsi
        ja .reverse
        
        pop rsi	
        ret

section .data
xlattab db '0123456789abcdef'
section .text
;------------------------------------------------
;------------------------------------------------

