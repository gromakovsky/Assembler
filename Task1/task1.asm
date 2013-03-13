	%define BITS 128
	%define MAX_NUMBER_LENGTH BITS/4
	%define MAX_ANS_LENGTH 50
	extern printf
	section .text
	global main

main: 
	mov edi, [esp + 8]  ;edi = argv
	mov esi, [edi + 4]  ;esi = argv[1]
	xor bl, bl  ;bl: ?? +-0sm //undefined, flags, sign, MSB
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
	mov ah, 1
	jmp processNumber

setSign:
	mov al, [esi]
	cmp al, '-'  
	LAHF
	and ah, 01000000b
	shr ah, 5
	or bl, ah
	ret

setMSB:
	mov al, [esi]
	call convert
	cmp al, 10000000b
	jl retLabel
	xor ah, ah
	call countNumberLength
	cmp ah, MAX_NUMBER_LENGTH 
	jl retLabel
	or bl, 1 
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

processNumber:  ;al is current figure, cl is current bit, ah is ans length
	mov al, [esi]
	inc esi
	test al, al   
	jz endOfNumber  ;check if 0-byte
	je processNumber
	call convert 
	mov cl, bl
	and cl, 1
	mov ch, al
	and ch, 1000b
	shr ch, 3
	xor cl, ch
	mov ebp, answer + MAX_ANS_LENGTH - 1  ;current position in ans
	mov ch, 0
	mov dh, 0
	call doubleAns
	mov ebp, answer + MAX_ANS_LENGTH - 1  ;current position in ans
	mov ch, 0
	mov dh, 0
	call increaseAns
	mov cl, bl
	and cl, 1
	mov ch, al
	and ch, 0100b
	shr ch, 2
	xor cl, ch
	mov ebp, answer + MAX_ANS_LENGTH - 1  ;current position in ans
	mov ch, 0
	mov dh, 0
	call doubleAns
	mov ebp, answer + MAX_ANS_LENGTH - 1  ;current position in ans
	mov ch, 0
	mov dh, 0
	call increaseAns
	mov cl, bl
	and cl, 1
	mov ch, al
	and ch, 0010b
	shr ch, 1
	xor cl, ch
	mov ebp, answer + MAX_ANS_LENGTH - 1  ;current position in ans
	mov ch, 0
	mov dh, 0
	call doubleAns
	mov ebp, answer + MAX_ANS_LENGTH - 1  ;current position in ans
	mov ch, 0
	mov dh, 0
	call increaseAns
	mov cl, bl
	and cl, 1
	mov ch, al
	and ch, 0001b
	xor cl, ch
	mov ebp, answer + MAX_ANS_LENGTH - 1  ;current position in ans
	mov ch, 0
	mov dh, 0
	call doubleAns
	mov ebp, answer + MAX_ANS_LENGTH - 1  ;current position in ans
	mov ch, 0
	mov dh, 0
	call increaseAns
	jmp processNumber



convert:  ;to convert from 'A' to 10 in al
	or al, 0x20
	sub al, '0'
	cmp al, 10 
	jl retLabel
	sub al, 39
	ret


increaseAns:  ;answer+= cl
	cmp ch, ah
	call checkCarry
	je retLabel
	cmp dh, 1     ;
	je l          ; if (dh == 0) and (ch != 0) ret
	cmp ch, 0     ;
	je l	      ;
	jmp retLabel  ;
l:	mov dl, [ebp]
	add dl, cl
	add dl, dh
	xor dh, dh
	cmp dl, 10
	call carry
	mov [ebp], dl
	dec ebp
	inc ch
	jmp increaseAns


doubleAns:  ;answer += answer, dh is carry
	cmp ch, ah
	call checkCarry
	je retLabel
	mov dl, [ebp]
	add dl, dl
	add dl, dh
	xor dh, dh
	cmp dl, 10
	call carry
	mov [ebp], dl
	dec ebp
	inc ch
	jmp doubleAns

carry:  ;modifies dh and dl, if dl > 9
	jl retLabel
	inc dh
	sub dl, 10
	ret

checkCarry:
	jne retLabel
	cmp dh, 0
	je retLabel
	mov [ebp], byte(1)
	inc ah
	cmp ah, ah
	ret


endOfNumber:  ;now number is stored in answer, ah is length
	mov cl, bl
	and cl, 1
	xor dh, dh
	xor ch, ch
	call increaseAns
	int3
	
	section .data
format 	db "%d", 0
answer	times MAX_ANS_LENGTH db 0
	end
