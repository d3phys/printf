global  _start

section .text


puts:	
	mov     rdi, 1                 
	mov     rax, 1                  
	syscall                         		
	ret

printf:
	push 	rbp
	mov 	rbp, rsp

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
