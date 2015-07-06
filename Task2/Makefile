all: dct.o test1.o
	g++ -m32 -g -Wall task2.o test1.o -o test1

dct.o: task2.asm
	yasm -g dwarf2 -f elf32 -a x86 task2.asm

test1.o: test1.cpp
	g++ -c -m32 -std=c++11 -Wall -g -o test1.o test1.cpp

clean:
	rm -f dct.o test1.o test1
