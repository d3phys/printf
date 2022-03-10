global  _start

section .text

;------------------------------------------------
; Copies null-terminated string from one buffer
; to another.
;
; Expect: rsi - null terminated string copy from
;	  rdi - buffer copy to
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
; Converts an integer value to a string using 
; the base of 10.
;
; Expect: rax - integer to convert
;	  rdi - buffer to store string
;
; Destrs: rax rbx rdx rdi  
;------------------------------------------------
section .text
itoa10:
	cld
	push rbp
	mov rbp, rsp	
	mov rbx, 10	

.save_dgt:	
	xor rdx, rdx	; Push remainder	
 	div rbx		; to stack
	add rdx, '0'	;
 	push rdx	;
 	
 	test rax, rax
	jnz .save_dgt	
	
.reverse:	
	pop rax		; Store digit characters in	
	stosb		; reversed order
	cmp rbp, rsp	;
	jnz .reverse	;

	pop rbp
	ret
;------------------------------------------------

;------------------------------------------------
; Converts an integer value to a string using 
; the base of the power of 2.
;
; Expect: 
;	  rax - integer to convert
;	   cl - base (power of 2)
;	  rbx - mask 
;	  rdi - buffer to store string
;
; Destrs: rax rbx rdx rdi  
;------------------------------------------------
section .text
itoa2x:
	cld
	push rbp
	mov rbp, rsp	
	
.save_dgt:	 
	mov rdx, rax			; Push remainder to the stack	
 	and rdx, rbx			;
	movzx rdx, byte [xlattab + rdx]	;
 	push rdx			;
 	shr rax, cl 			;
 	
 	test rax, rax
	jnz .save_dgt	
	
.reverse:	
	pop rax				; Store digit characters in	
	stosb				; reversed order
	cmp rbp, rsp			;
	jnz .reverse			;

	pop rbp
	ret

section .data
xlattab db '0123456789abcdef'
section .text
;------------------------------------------------


;------------------------------------------------
; printf(fmt, ...)
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

%define write  0x1
%define stdout 0x1
%define arg(id) [rbp + 16 + 8 * id]

printf:
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
				
	pop rbp			
	ret			
				
.format:				
	xor rax, rax		; Get format specifier.
	lodsb			; Make shure that it is not a '%'. 
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
	mov r10, rsi		; Have to save source format string
	mov rsi, rax		; position in r10.
	call strcpy		;
	mov rsi, r10		;
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

prbuf times 1024 db 'a' 
section .text

%undef arg
%undef write
%undef stdout
;------------------------------------------------
;------------------------------------------------


_start:

	push 321245
	push 131313
	push 123450321
	push submsg
	push 321
	push 'g'
	push 0x32
	push message
	call printf
	times 6 pop rax
	
	mov eax, 60                 ; system call 60 is exit
	xor rdi, rdi                ; exit code 0
	syscall

section .data
submsg 	db "inner msg %s%c%x and", 0x0
message db "he%%ll%x%c%do %s%d %d %d  world", 0xa, 0x0      ; note the newline at the end
	
msg_len equ $ - message         
