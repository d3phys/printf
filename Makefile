#
# print() makefile
# d3phys (C) 2022
#

OBJS  = main.o print.o
EXE   = print

make: $(OBJS)
	ld $(OBJS) /lib64/crt1.o -I/lib64/ld-linux-x86-64.so.2 /lib64/libc.so.6 -o print

main.o:	 main.c
	gcc -c $< -o $@

print.o: print.s
	nasm -f elf64 $< -o $@	

clean:
	rm -f *.o
	rm -f *.lst
	rm -f $(EXE)
