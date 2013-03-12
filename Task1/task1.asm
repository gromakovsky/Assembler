	%define BITS 128
	%define BYTES BITS/8
	%define MAX_ANS_LENGTH 50
	extern printf
	section .text
	global main

main: 
	mov edi, [esp + 8]  ;edi = argv
	mov esi, [edi + 4]  ;esi = argv[1]
	xor bl, bl  ;bl for flags: ???s +-0         s is sign
	xor bh, bh  ;bh for length
	jmp processFormat 
		
processFormat:	;sets flags from esi to bl 
	mov al, [esi]
	inc esi
	test al, al       ;
	jz toNumber  ;check if 0-byte
	cmp al, '0'  ;
	jg toLength  ;check if length-segment and if 0-flag
	LAHF  
	and ah, 01000000b
	shr ah, 6
	or bl, ah
	cmp al, '-'  ;check if '-'-flag
	LAHF
	and ah, 01000000b
	shr ah, 5
	or bl, ah
	cmp al, '+'  ;check if '+'-flag
	LAHF
	and ah, 01000000b
	shr ah, 4
	or bl, ah
	cmp al, ' '  ;check if ' '-flag
	LAHF
	and ah, 01000000b
	shr ah, 3
	or bl, ah
	jmp processFormat


toLength:
	xor ax, ax  ;ax is a temporary storage for length
	xor cx, cx
	jmp processLength

processLength:  ;sets length from esi to bh
	mov cl, [esi]
	inc esi
	test cl, cl       ;
	jz toNumber  ;check if 0-byte
	sub cl, '0'
	mov ah, MAX_ANS_LENGTH
	mul ah
	add al, cl
	mov bh, al
	jmp processLength


toNumber:
	mov esi, [edi + 8]  ;esi = argv[2]
	mov ch, 1
	mov ebp, answer + MAX_ANS_LENGTH - 1  ;current position in ans
	jmp processNumber

processNumber:  ;curent answer length is ch
	mov al, [esi]
	inc esi
	test al, al       ;
	jz endOfNumber  ;check if 0-byte
	cmp al, '-'  ;check sign
	pushf
	LAHF
	and ah, 01000000b
	shr ah, 2
	or bl, ah
	popf
	je processNumber
	or al, 0x20
	sub al, '0'
	cmp al, 10 
	jl decAl
	sub al, 39
skip:	



increaseAns:  ;answer++



endOfNumber:
	int3
	
	section .rodata
format 	db "%d", 0
answer	resb MAX_ANS_LENGTH
	end
