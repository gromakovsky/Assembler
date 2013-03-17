	%define BITS 128
	%define MAX_NUMBER_LENGTH BITS/4
	%define MAX_ANS_LENGTH 50
	%define MAX_LENGTH 50
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
	and dl, 2
	shr dl, 1
	add si, dx
	call setMSB
	mov esi, [edi + 8]  ;esi = argv[2]
	mov dl, bl
	and dl, 2 
	shr dl, 1
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
	cmp al, 00001000b
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
	je l1         ; if (dh == 0) and (ch != 0) ret
	cmp ch, 0     ;
	je l1	      ;
	jmp retLabel  ;
l1:	mov dl, [ebp]
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
	;if msb, then answer++
	mov cl, bl
	and cl, 1
	xor dh, dh
	xor ch, ch
	mov ebp, answer + MAX_ANS_LENGTH - 1
	call increaseAns
	;convert 0 to '0', etc.
	mov ch, ah
	mov esi, answer + MAX_ANS_LENGTH - 1
	call convertAns
	;make MSB mean sign and sign mean nothing
	mov dl, bl
	and dl, 2
	shr dl, 1
	xor bl, dl
	;count extra spaces/zeroes
	mov al, bh
	sub al, ah	
	mov dl, bl
	and dl, 00110000b
	cmp dl, 0
	call decAlNE  ;decrease, if ' '-flag or '+'-flag
	mov dh, bl
	and dh, 1
	or dl, dh
	cmp dl, 1  ;if dl == 1, decrease
	call decAlE  ;decrease, if answer < 0 and not decreased yet
	;push_forward '0' al times, if '0'-flag, also decreases al
	mov bh, bl
	and bh, 00000100b
	cmp bh, 0
	je l2
	call push0
l2:	;push -, if answer < 0
	mov bh, bl
	and bh, 1
	cmp bh, 0
	je l3
	mov [esi], byte('-')
	dec esi
	jmp l5
l3:	;here we know, that answer >= 0, need to look at ' '- and '+'-flag
	mov bh, bl
	and bh, 00010000b
	cmp bh, 0
	je l4
	mov [esi], byte('+')
	dec esi
l4:	mov bh, bl
	and bh, 00110000b
	cmp bh, 00100000b
	jne l5
	mov [esi], byte(' ')
	dec esi
l5:	;
	mov bh, bl
	and bh, 00001000b
	cmp bh, 0
	je l6
	mov edi, answer + MAX_ANS_LENGTH
	call push_back
	inc esi
	push esi
	call printf
	add esp, 4
	ret
l6:	call push_forward
	inc esi
	push esi
	call printf
	add esp, 4
	ret

decAlNE:  ;decreases al, if not equal
	je retLabel
	dec al
	ret

decAlE:  ;decrease al, if equal
	jne retLabel
	dec al
	ret

push0:  ;push_forward '0' al times
	cmp al, 1
	jl retLabel
	mov [esi], byte('0')
	dec al
	dec esi
	jmp push0

convertAns:
	cmp ch, 0
	je retLabel
	mov cl, [esi]
	add cl, '0'
	mov [esi], cl
	dec esi
	dec ch
	jmp convertAns

push_forward:  ;pushes al spaces before answer(starts from esi)
	cmp al, 1
	jl retLabel
	mov [esi], byte(' ')
	dec al
	dec esi
	jmp push_forward

push_back:  ;pushes al spaces after answer(starts from edi)
	cmp al, 1
	jl retLabel
	mov [edi], byte(' ')
	dec al
	inc edi
	jmp push_back

	
	section .data
format 	db "%c", 0
answer	times MAX_ANS_LENGTH + MAX_LENGTH db 0  ;+ MAX_LENGTH when flag '-'
	end
