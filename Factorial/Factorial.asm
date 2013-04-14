	extern printf
		section .text
		global main

main: 	
	mov esi, [esp + 8]
	mov edi, [esi + 4]
	xor edx, edx
	mov dl, [edi]
	sub edx, '0'
	mov eax, 1
	jmp cycle
		
cycle:	
	mov ecx, edx
	mul edx
	mov edx, ecx
	sub edx, 1
	jz print
	jnz cycle

print:
	mov esi, [esp + 4]	
	push eax
	push format
	call printf
	add esp, 8
		
		section .rodata
format 	db "Result is %d", 10, 13, 0
	end
