#
# print() makefile
# d3phys (C) 2022
#

ld   = /lib64/ld-linux-x86-64.so.2
crt  = /lib64/crt1.o
libc = /lib64/libc.so.6

EXE   = print asmcall

test: main.o print.o
	ld $^ $(crt) $(libc) -I$(ld) -o print
	./print

asmcall: asmcall.o print.o
	ld $^ $(libc) -I$(ld) -o asmcall
	./asmcall

print.o: print.s
	nasm -f elf64 $< -o $@	

asmcall.o: asmcall.s
	nasm -f elf64 $< -o $@	
	
%.o: %.c
	gcc -c $< -o $@

clean:
	rm -f *.o
	rm -f *.lst
	rm -f $(EXE)

