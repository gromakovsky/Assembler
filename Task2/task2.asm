%define MATRIX_HEIGHT 8
%define MATRIX_WIDTH 8
%define MATRIX_SIZE MATRIX_HEIGHT * MATRIX_WIDTH

%macro matrixMultInternal 3 ; %1 - esi, %2 - c^T, %3 - edi
        movaps xmm0, [%1 + ecx * 4] ; xmm0 = esi[0, ecx]
        add ecx, MATRIX_WIDTH / 2
        movaps xmm1, [%1 + ecx * 4] ; xmm1 = esi[4, ecx]
        mulps xmm0, [%2 + eax * 4] ;xmm0 *= transformMatrix[0, eax]
        add eax, MATRIX_WIDTH / 2
        mulps xmm1, [%2 + eax * 4] ;xmm1 *= transformMatrix[4, eax]
        haddps xmm0, xmm1
        haddps xmm0, xmm0
        haddps xmm0, xmm0 ; xmm0 = sum

        movss dword [%3], xmm0 ;edi = sum, tmp[eax, ecx] = esi[ecx] * transformMatrix[eax]
        add %3, 4
        add ecx, MATRIX_WIDTH / 2
        sub eax, MATRIX_WIDTH / 2
%endmacro

%macro matrixMultExternal 3
    xor ecx, ecx
%rep MATRIX_WIDTH
    matrixMultInternal %1, %2, %3
%endrep
    add eax, MATRIX_WIDTH
%endmacro

%macro matrixMult 3
;    xor eax, eax
;%rep MATRIX_WIDTH
;    matrixMultExternal %1, %2, %3
;%endrep

    xor eax, eax
  fdctSingle_loop1: ; (esi * c^T)^T -> edi (esp)
    xor ecx, ecx
      fdctSingle_loop2:
        lea edx, [ecx * MATRIX_WIDTH]
        movaps xmm0, [%1 + edx * 4]
        add edx, 4
        movaps xmm1, [%1 + edx * 4]
        lea edx, [eax * MATRIX_WIDTH]
        mulps xmm0, [%2 + edx * 4]
        add edx, 4
        mulps xmm1, [%2 + edx * 4]
        haddps xmm0, xmm1
        haddps xmm0, xmm0
        haddps xmm0, xmm0

        movss dword [%3], xmm0
        add %3, 4
        inc ecx
        cmp ecx, MATRIX_WIDTH
        jne fdctSingle_loop2
    inc eax
    cmp eax, MATRIX_HEIGHT
    jne fdctSingle_loop1
        
%endmacro

global _fdct
global _idct

section .bss
;align 16
transformMatrix resd MATRIX_SIZE
transformMatrixT resd MATRIX_SIZE
;transformMatrixCalculated db 0
sqrt132 resd 1 ; sqrt132 = sqrt(1/32)

section .text

_fdct: ; void _fdct(float * input, float * output, unsigned int n)
    ;frame pointer
    push ebp
    mov ebp, esp
    ;
    push edi
    push esi
    push ebx

    call _calculateSqrt132
    call _calculateTransformMatrix

    mov ebx, [esp + 28]
    mov edi, [esp + 24]
    mov esi, [esp + 20]

  fdct_loop:
    push edi
    push esi
    call _fdctSingle
    add esp, 8
     
    add edi, MATRIX_SIZE * 4
    add esi, MATRIX_SIZE * 4
    dec ebx
  jnz fdct_loop

    pop ebx
    pop esi
    pop edi
    leave
    ret

_fdctSingle: ; void _fdctSingle(float * input, float * output)
    push edi
    push esi
    ;frame pointer
    push ebp
    mov ebp, esp
    ;

    and esp, -16 ; align stack
    sub esp, MATRIX_SIZE * 4 ; to put temporary matrix here

    mov edi, esp
    mov esi, [ebp + 16]

;    prefetcht0 [transformMatrix]

;    matrixMult esi, transformMatrix, edi

    xor eax, eax
  fdctSingle_loop1: ; (esi * c^T)^T -> edi (esp)
    xor ecx, ecx
      fdctSingle_loop2:
        lea edx, [ecx * MATRIX_WIDTH]
        movaps xmm0, [esi + edx * 4]
        add edx, 4
        movaps xmm1, [esi + edx * 4]
        lea edx, [eax * MATRIX_WIDTH]
        mulps xmm0, [transformMatrix + edx * 4]
        add edx, 4
        mulps xmm1, [transformMatrix + edx * 4]
        haddps xmm0, xmm1
        haddps xmm0, xmm0
        haddps xmm0, xmm0

        movss dword [edi], xmm0
        add edi, 4
        inc ecx
        cmp ecx, MATRIX_WIDTH
        jne fdctSingle_loop2
    inc eax
    cmp eax, MATRIX_HEIGHT
    jne fdctSingle_loop1
        
;    jmp exit
        
    mov edi, [ebp + 20]
    mov esi, transformMatrix

    xor eax, eax
  fdctSingle_loop3: ; (c * (edi * c^T (from esp))) -> edi (output)
    xor ecx, ecx
      fdctSingle_loop4:
        lea edx, [eax * MATRIX_WIDTH]
        movaps xmm0, [esi + edx * 4]
        add edx, 4
        movaps xmm1, [esi + edx * 4]
        lea edx, [ecx * MATRIX_WIDTH]
        mulps xmm0, [esp + edx * 4] 
        add edx, 4
        mulps xmm1, [esp + edx * 4] 
        haddps xmm0, xmm1
        haddps xmm0, xmm0
        haddps xmm0, xmm0

        movss dword [edi], xmm0
        inc ecx
        add edi, 4
        cmp ecx, MATRIX_WIDTH
      jne fdctSingle_loop4
    inc eax
    cmp eax, MATRIX_HEIGHT
  jne fdctSingle_loop3

exit:
    leave
    pop esi
    pop edi
    ret

_idct: ; void _idct(float * input, float * output, unsigned int n)
    ;frame pointer
    push ebp
    mov ebp, esp
    ;
    push edi
    push esi
    push ebx

    call _calculateSqrt132
    call _calculateTransformMatrix

    mov ebx, [esp + 28]
    mov edi, [esp + 24]
    mov esi, [esp + 20]

  idct_loop:
    push edi
    push esi
    call _idctSingle
    add esp, 8
     
    add edi, MATRIX_SIZE * 4
    add esi, MATRIX_SIZE * 4
    dec ebx
    jnz idct_loop

    pop ebx
    pop esi
    pop edi
    leave
    ret

_idctSingle: ; void _idctSingle(float * input, float * output)
    push edi
    push esi
    ;frame pointer
    push ebp
    mov ebp, esp
    ;

    and esp, -16 ; align stack
    sub esp, MATRIX_SIZE * 4

    mov edi, esp
    mov esi, [ebp + 16]

    xor eax, eax
  idctSingle_loop1: ; (esi * c)^T -> edi (esp)
    xor ecx, ecx
      idctSingle_loop2:
        lea edx, [ecx * MATRIX_WIDTH]
        movaps xmm0, [esi + edx * 4]
        add edx, 4
        movaps xmm1, [esi + edx * 4]
        lea edx, [eax * MATRIX_WIDTH]
        mulps xmm0, [transformMatrixT + edx * 4] 
        add edx, 4
        mulps xmm1, [transformMatrixT + edx * 4] 
        haddps xmm0, xmm1
        haddps xmm0, xmm0
        haddps xmm0, xmm0

        movss dword [edi], xmm0
        add edi, 4
        inc ecx
        cmp ecx, MATRIX_WIDTH
        jne idctSingle_loop2
    inc eax
    cmp eax, MATRIX_HEIGHT
    jne idctSingle_loop1
        
    mov edi, [ebp + 20]
    mov esi, transformMatrixT

    xor eax, eax
  idctSingle_loop3: ; (c^T * (esi * c)) -> edi (output)
    xor ecx, ecx
      idctSingle_loop4:
        lea edx, [eax * MATRIX_WIDTH]
        movaps xmm0, [esi + edx * 4]
        add edx, 4
        movaps xmm1, [esi + edx * 4]
        lea edx, [ecx * MATRIX_WIDTH]
        mulps xmm0, [esp + edx * 4] 
        add edx, 4
        mulps xmm1, [esp + edx * 4] 
        haddps xmm0, xmm1
        haddps xmm0, xmm0
        haddps xmm0, xmm0

        movss dword [edi], xmm0
        add edi, 4
        inc ecx
        cmp ecx, MATRIX_WIDTH
        jne idctSingle_loop4
    inc eax
    cmp eax, MATRIX_HEIGHT
    jne idctSingle_loop3

    leave
    pop esi
    pop edi
    ret



_calculateSqrt132: ; stores sqrt(1/32) in sqrt132
    push dword 0.03125
    fld dword[esp]    
    fsqrt
    fstp dword[sqrt132]
    add esp, 4
    ret

_calculateTransformMatrix: ;calculates transformMatrix and transformMatrixT
    movzx eax, byte [transformMatrixCalculated]
    test eax, eax
    jz calculateTransformMatrix_calc
    ret

  calculateTransformMatrix_calc:
    mov eax, 1
    mov [transformMatrixCalculated], eax
    xor eax, eax
    
  calculateTransformMatrix_loop1:
    xor ecx, ecx

      calculateTransformMatrix_loop2:
        call _calculateTransformMatrixSingle
        
        inc ecx
        cmp ecx, 8
        jne calculateTransformMatrix_loop2

    inc eax
    cmp eax, 8
    jne calculateTransformMatrix_loop1

    ret
    
_calculateTransformMatrixSingle: ; void _calculateTransformMatrixSingle(size_t i, size_t j)
                                ; transformMatrix[i, j] = i == 0 ? 1/8 : 1/sqrt(32) * cos((2 * j + 1) * i * pi / 16)
                                ; transformMatrixT = transformMatrix^T * 8 in this case transformMatrixT is matrix for idct
                                ; args: eax = i, ecx = j
    ;frame pointer
    push ebp
    mov ebp, esp
    ;

    test eax, eax
    jz calculateTransformMatrixSingle_zero

    lea edx, [2 * ecx + 1]
    fldpi
    push eax 
    push edx 
    fimul dword [esp + 4]
    fimul dword [esp]
    add esp, 8
    push dword 16.
    fdiv dword [esp]
    add esp, 4
    fcos
    fmul dword [sqrt132]
    lea edx, [ecx + eax * MATRIX_WIDTH]
    fst dword [edx * 4 + transformMatrix]
    push dword 8.
    fmul dword [esp]
    add esp, 4
    lea edx, [eax + ecx * MATRIX_WIDTH]
    fstp dword [edx * 4 + transformMatrixT]

    leave
    ret

  calculateTransformMatrixSingle_zero:
    mov dword [ecx * 4 + transformMatrix], dword 0.125
    lea edx, [ecx * MATRIX_WIDTH]
    mov dword [edx * 4 + transformMatrixT], dword 1.
    
    leave
    ret

