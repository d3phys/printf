;------------------------------------------------
; Example of different calling conventions usage 
;
; "And God said, Let there be light: 
;  and there was light."
;                                  (Genesis 1:3)
;
; Written 2022 by Denis Dedkov
;------------------------------------------------

extern cdecl_print
extern printf

global _start

section .text        
_start:
        mov rdi, fmt            ; Call libc printf() function.
        mov rsi, 'G'            ; 
        mov rdx, ref            ; stdcall calling convention in which the   
        mov rcx, [chapter]      ; callee is responsible for cleaning up 
        mov r8,  [verse]        ; the stack, but the parameters are pushed 
        xor rax, rax            ; onto the stack in right-to-left order, 
        call printf             ; as in the cdecl calling convention.

        mov rax, [verse]        ; Call own print() 
        push rax                ; 
        mov rax, [chapter]      ; cdecl (which stands for C declaration) is a 
        push rax                ; calling convention in which subroutine arguments 
        push ref                ; are passed on the stack.
        push 'G'                ; And again callee is responsible for cleaning up.
        push fmt                ;
        call cdecl_print        ;
        
	mov eax, 60             ; Syscall exit
	xor rdi, rdi            ; 
	syscall      

section .data

fmt     db `And %cod said, Let there be light: and there was light.\n`
        db `                                         (%s %d:%d)    \n` 
        db                                                        `\n\0`                                                       
        
ref     db "Genesis", 0x0

chapter dq 1
verse   dq 0x3

