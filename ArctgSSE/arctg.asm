extern printf
%define chislo 0.9999

section .text
global main

main:
	;sum(x^(2i + 1) / (2i + 1) * (-1)^i) 
	movupd xmm0, [number1] ;-chislo, chislo
	movupd xmm1, [number]  ;chislo, chislo
	mulsd xmm0, xmm1
	mulsd xmm0, xmm1
	mulpd xmm1, xmm1
	mulpd xmm1, xmm1
	movupd xmm2, [three]
	movupd xmm3, [four]
	xorpd xmm4, xmm4
	mov ecx, 30000000

for:
	movupd xmm5, xmm0
	divpd xmm5, xmm2
 	haddpd xmm5, xmm5	
	addsd xmm4, xmm5
	addpd xmm2, xmm3
	mulpd xmm0, xmm1
	
	dec ecx
	jnz for


myprint:
	sub esp, 16
	movupd [esp], xmm4
	push format
	call printf
	add esp, 20
	xor eax, eax
	ret

section .data
	number1: dq -chislo
	number: dq chislo
	number_: dq chislo
	three: dq 3.0	
	one: dq 1.0
	four: dq 4.0
	four_: dq 4.0
	format: db "%.20lf", 0
