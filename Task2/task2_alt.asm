
section .text

global _fdct
global _idct

; void _fdct (float* data, float* res, int n)
_fdct:  
  
    mov eax, [esp + 4]; data
    mov ebx, [esp + 8]; result
    mov edx, [esp + 12]; count

    _main_loop:
        pusha
            push tmp
            push eax
            push matr1
            call matrix_mul
            add esp, 12
        popa

        pusha
            push ebx
            push matr2 
            push tmp
            call matrix_mul
            add esp, 12
        popa

        add eax, 64 * 4
        add ebx, 64 * 4
        sub edx, 1
        jnz _main_loop

  
ret

; void _idct (float* data, float* res, int n)
_idct:  
    mov eax, [esp + 4]; data
    mov ebx, [esp + 8]; result
    mov ecx, [esp + 16]

    mov edx, [esp + 12]
    _main_loop2:
        pusha
            push tmp
            push eax
            push matr2
            call matrix_mul   
            add esp, 12
        popa

        pusha
            push ebx
            push matr1 
            push tmp
            call matrix_mul
            add esp, 12
        popa

        pusha
            push ebx
            call mul64
            add esp, 4
        popa


        add eax, 64 * 4
        add ebx, 64 * 4
        sub edx, 1
        jnz _main_loop2
  
ret


; void mul64 (float * data) 
mul64:
    mov eax, [esp + 4]
    mov ecx, 16
    push 64.0
    push 64.0
    push 64.0
    push 64.0
    movups xmm0, [esp]
    add esp, 16
    _loop_mul64:
        movaps xmm1, [eax];
        mulps xmm1, xmm0
        movaps [eax], xmm1
        add eax, 16
        sub ecx, 1
        jnz _loop_mul64
ret



; void matrix_mul (float* data1, float * data2, float* res)
matrix_mul:  
    ; xmm7 always equals 0
    push 0.0
    push 0.0
    push 0.0
    push 0.0
    movups xmm7, [esp]
    add esp, 16

    mov eax, [esp + 4]; data1
    mov edx, [esp + 12]; res

    ; matrix mul
    mov cl, 0
    _loop_mul1:
        ; first part
        movaps xmm0, xmm7
        
        mov ebx, [esp + 8]
        mov ch, 0
        _loop_mul2:
            movss xmm1, [eax]
            shufps xmm1, xmm1, 0h
            movaps xmm2, [ebx]
            mulps xmm1, xmm2
            addps xmm0, xmm1

            add eax, 4
            add ebx, 32
            inc ch
            cmp ch, 8
            jne _loop_mul2

        movaps [edx], xmm0

        sub eax, 32
        ; second part
        movaps xmm0, xmm7
        mov ebx, [esp + 8]
        mov ch, 0
        _loop_mul22:
            movss xmm1, [eax]
            shufps xmm1, xmm1, 0h
            movaps xmm2, [ebx + 16]
            mulps xmm1, xmm2
            addps xmm0, xmm1

            add eax, 4
            add ebx, 32
            inc ch
            cmp ch, 8
            jne _loop_mul22

        movaps [edx + 16], xmm0

        add edx, 32
        inc cl
        cmp cl, 8
        jne _loop_mul1
 
ret


section .data
    align 16
    matr1: dd 0.12500000, 0.12500000, 0.12500000, 0.12500000, 0.12500000, 0.12500000, 0.12500000, 0.12500000, 0.17337997, 0.14698444, 0.09821186, 0.03448742, -0.03448743, -0.09821188, -0.14698446, -0.17337999, 0.16332036, 0.06764951, -0.06764952, -0.16332038, -0.16332036, -0.06764949, 0.06764954, 0.16332039, 0.14698444, -0.03448743, -0.17337999, -0.09821185, 0.09821189, 0.17337997, 0.03448739, -0.14698447, 0.12500000, -0.12500001, -0.12499999, 0.12500001, 0.12499998, -0.12500003, -0.12499996, 0.12500004, 0.09821186, -0.17337999, 0.03448744, 0.14698444, -0.14698447, -0.03448737, 0.17337996, -0.09821194, 0.06764951, -0.16332036, 0.16332039, -0.06764955, -0.06764946, 0.16332035, -0.16332039, 0.06764959, 0.03448742, -0.09821185, 0.14698444, -0.17337997, 0.17338000, -0.14698449, 0.09821194, -0.03448752

    align 16
    matr2: dd 0.12500000, 0.17337997, 0.16332036, 0.14698444, 0.12500000, 0.09821186, 0.06764951, 0.03448742, 0.12500000, 0.14698444, 0.06764951, -0.03448743, -0.12500001, -0.17337999, -0.16332036, -0.09821185, 0.12500000, 0.09821186, -0.06764952, -0.17337999, -0.12499999, 0.03448744, 0.16332039, 0.14698444, 0.12500000, 0.03448742, -0.16332038, -0.09821185, 0.12500001, 0.14698444, -0.06764955, -0.17337997, 0.12500000, -0.03448743, -0.16332036, 0.09821189, 0.12499998, -0.14698447, -0.06764946, 0.17338000, 0.12500000, -0.09821188, -0.06764949, 0.17337997, -0.12500003, -0.03448737, 0.16332035, -0.14698449, 0.12500000, -0.14698446, 0.06764954, 0.03448739, -0.12499996, 0.17337996, -0.16332039, 0.09821194, 0.12500000, -0.17337999, 0.16332039, -0.14698447, 0.12500004, -0.09821194, 0.06764959, -0.03448752

    align 16
    tmp: dd 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
