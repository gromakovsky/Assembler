	%define BITS 128
	%define BYTES BITS/8
	%define MAX_ANS_LENGTH 50
	extern printf
	section .text
	global main

main: 
	mov edi, [esp + 8]  ;edi = argv
	mov esi, [edi + 4]  ;esi = argv[1]
	xor bl, bl  ;bl: ?? +-0ms //undefined, flags, sign, MSB
	xor bh, bh  ;bh is length
	jmp processFormat 
		
processFormat:	;sets flags from esi to bl 
	mov al, [esi]
	test al, al       ;
	jz toNumber  ;check if 0-byte
	cmp al, '0'  ;
	jg toLength  ;check if length-segment and if 0-flag
	LAHF  
	and ah, 01000000b
	shr ah, 4
	or bl, ah
	cmp al, '-'  ;check if '-'-flag
	LAHF
	and ah, 01000000b
	shr ah, 3
	or bl, ah
	cmp al, '+'  ;check if '+'-flag
	LAHF
	and ah, 01000000b
	shr ah, 2
	or bl, ah
	cmp al, ' '  ;check if ' '-flag
	LAHF
	and ah, 01000000b
	shr ah, 1
	or bl, ah
	inc esi
	jmp processFormat


toLength:
	xor al, al  ;al is a temporary storage for length
	xor cx, cx
	jmp processLength

processLength:  ;sets length from esi to bh
	mov cl, [esi]
	inc esi
	test cl, cl       ;
	jz toNumber  ;check if 0-byte
	sub cl, '0'
	mov ah, 10 
	mul ah
	add al, cl
	mov bh, al
	jmp processLength


toNumber:
	mov esi, [edi + 8]  ;esi = argv[2]
	mov ch, 1
	mov ebp, answer + MAX_ANS_LENGTH - 1  ;current position in ans
	call setSign
	xor dh, dh
	mov dl, bl
	and dl, 1
	add si, dx
	call setMSB
	mov esi, [edi + 8]  ;esi = argv[2]
	mov dl, bl
	and dl, 1
	add si, dx
	int3
	jmp processNumber

setSign:
	mov al, [esi]
	cmp al, '-'  
	LAHF
	and ah, 01000000b
	shr ah, 6
	or bl, ah
	ret

setMSB:
	mov al, [esi]
	call convert
	cmp al, 10000000b
	jl retLabel
	xor ah, ah
	call countNumberLength
	cmp ah, BYTES
	jl retLabel
	or bl, 00000010b
	ret
	
countNumberLength:  ;count length of the number from esi, increasing ah
	mov al, [esi]
	sub al, 0
	je retLabel
	inc ah
	inc esi
	jmp countNumberLength


retLabel:
	ret

processNumber:  ;curent answer length is ch, number length is cl
	mov al, [esi]
	inc esi
	test al, al       ;
	jz endOfNumber  ;check if 0-byte
	je processNumber
	call convert 

convert:  ;to convert from 'A' to 10 in al
	or al, 0x20
	sub al, '0'
	cmp al, 10 
	jl retLabel
	sub al, 39
	ret


increaseAns:  ;answer++


doubleAns:  ;answer += answer;


endOfNumber:
	int3
	
	section .rodata
format 	db "%d", 0
answer	resb MAX_ANS_LENGTH
	end
