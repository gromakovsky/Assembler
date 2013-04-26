%define MATRIX_HEIGHT 1
%define MATRIX_WIDTH 1
%define MATRIX_SIZE 4 * MATRIX_HEIGHT * MATRIX_WIDTH
%define NUMBER_OF_MATRIXES 2
%define OUTPUT_SIZE NUMBER_OF_MATRIXES * MATRIX_HEIGHT * MATRIX_WIDTH
extern printf
extern exit

global main

section .rodata
formatDouble db "%lf ", 0
formatInt db "%d", 10, 0
input dd 1.0, 2.1, 2.1, 2.1, 2.1
two dd 2.
half dd 0.5
four dd 4.


section .data
output resd OUTPUT_SIZE
sqrt2 resd 1

section .text

ret_label:
    ret

_countSqrt2@0: ; stores sqrt(2.) in sqrt2
    fld dword[two]    
    fsqrt
    fstp dword[sqrt2]
    ret

_alpha@4: ; arg == 0 ? sqrt(2) / 4 : 0.5
    push ebp
    mov ebp, esp
    mov eax, [esp + 8]
    test eax, eax
    jz _alpha_label1
    fld dword[half]
    jmp _alpha_label_finish
  _alpha_label1:
    fld dword[sqrt2]
    fdiv dword[four]
  _alpha_label_finish:
    leave
    ret 4

    
_fdct@12:
    ;frame pointer
    push ebp
    mov ebp, esp
    ;
    push edi
    push esi

    mov ecx, [esp + 24]
    mov edi, [esp + 20]
    mov esi, [esp + 16]

  _fdct_label_loop:
    push edi
    push esi
    call _fdctSingle@8
     
    add edi, MATRIX_SIZE
    add esi, MATRIX_SIZE
    dec ecx
    jnz _fdct_label_loop

    pop esi
    pop edi
    leave
    ret 12

_fdctSingle@8:  ; doesn't affect ecx
    ;frame pointer
    push ebp
    mov ebp, esp
    ;
    push edi
    push esi

    mov edi, [esp + 20]
    mov esi, [esp + 16]
    fld dword[esi]
    sub esp, 8
    fstp qword[esp]
    push formatDouble
    mov ebx, ecx
    call printf
    mov ecx, ebx
    add esp, 12

    pop esi
    pop edi
    leave
    ret 8

_idct@12:
    ;frame pointer
    push ebp
    mov ebp, esp
    ;


    leave
    ret 12

main:
    ; frame pointer
    push ebp
    mov ebp, esp
    ;

    call _countSqrt2@0

    push NUMBER_OF_MATRIXES
    push output
    push input
    call _fdct@12

    xor eax, eax
    leave
    ret



