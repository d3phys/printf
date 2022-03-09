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


puts:	
	mov     rdi, 1                 
	mov     rax, 1                  
	syscall                         		
	ret

printf:
	push 	rbp
	mov 	rbp, rsp

	mov rsi, message
	mov rdi, printf_buf
	
	mov rax, 13
	mov cl, 1
	mov rbx, 1
	
	call itoa2x	
	
	mov 	rdi, [rbp + 16]
	xor 	rax, rax

.copy:	
	movzx	rdx, byte [rdi + rax]
	
	cmp	dl, '%'
	je 	.format

	mov 	byte [printf_buf + rax], dl
	inc 	rax

	test 	dl, dl
	jnz 	.copy

	mov 	rsi, printf_buf
	mov 	rdx, rax
	call 	puts

	pop 	rbp
	ret 	1 * 0x8

	
.format:
	inc	rax
	movzx	rdx, byte [rdi + rax]
	
	cmp	dl,  '%'
	je 	.pct

	
	lea 	rdx, [rdx - 'b']
	cmp	rdx, 'x' - 'b'
	ja 	.dflt

	jmp 	[.jmp_table + 8 * rdx]

.hex:
	mov rcx, 1
	jmp .copy
.dec:
	mov rcx, 2
	jmp .copy
.oct:
	mov rcx, 3
	jmp .copy
.str:
	mov rcx, 4
	jmp .copy
.chr:
	mov rcx, 5
	jmp .copy
.bin:
	mov rcx, 6
	jmp .copy
.pct:	
	mov rcx, 7
	jmp .copy
.dflt:
	mov rcx, 666
	jmp .copy

	
section .data
.jmp_table:
	dq .bin
	dq .chr
	dq .dec
	dq .dflt
	dq .dflt
	dq .dflt
	dq .dflt
	dq .dflt
	dq .dflt
	dq .dflt
	dq .dflt
	dq .dflt
	dq .dflt
	dq .oct
	dq .dflt
	dq .dflt
	dq .dflt
	dq .str
	dq .dflt
	dq .dflt
	dq .dflt
	dq .dflt
	dq .hex

printf_buf times 30 db 'a' 


section .text
_start:
	push 	message
	call 	printf

	mov     eax, 60                 ; system call 60 is exit
	xor     rdi, rdi                ; exit code 0
	syscall

section .data
message db      "%c%%%gH%e%%ll%o, World", 0xa, 0x0      ; note the newline at the end
	
msg_len equ $ - message         
