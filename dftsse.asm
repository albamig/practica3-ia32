; Desarrollado por Sergio Delgado y Alberto Amigo
;
; En este código se calculan las DFT de un conjunto de números implementando 
; un eficiente algoritmo de multiplicacion de números complejos
; utilizando la extensión SSE de la arquitectura Intel IA32

segment .data
	j dq 0
	k dq 0
	menosuno dq -1
	angulo dq 0
	zero dq 0
	TAM dq 1024

segment .text
	global dftsse

	extern val_complex								; matriz de valores
	extern res_complex								; matriz de resultados

	dftsse:
		mov ecx, dword[TAM]
		mov edx, 0									; edx: indice de res_complex
		LoopJ:
			dec ecx
			mov ebx, ecx 							; Salvamos el contador del bucle J									
			mov ecx, dword[TAM]						; Inicializamos los registros usados para el sumatorio
			mov eax, 0								; ecx: 1024 repeticiones, eax: indice numeros complejos
			movupd xmm4, [zero]						; xmm4: acumulador para la suma
			LoopK:
				movddup xmm0, [val_complex+eax]		; xmm0 = parte real del numero x(subk) duplicada
				movddup xmm2, [val_complex+eax+8]	; xmm2 = parte imaginaria del numero x(subk) duplicada
				call Angulo
				fsin
				fstp qword[angulo]
				movhpd xmm1, [angulo]				; xmm1(alta) = sin(-2*pi*j*k/1024)
				movlpd xmm3, [angulo]				; xmm3(baja) =  xmm1(baja)
				call Angulo
				fcos
				fstp qword[angulo]
				movlpd xmm1, [angulo]				; xmm1(baja) = cos(-2*pi*j*k/1024)
				movhpd xmm3, [angulo]				; xmm3(alta) = xmm1(alta)
				mulpd xmm0, xmm1					; xmm0(baja, alta) = parte real * (baja)sin y (alta)cos
				mulpd xmm2, xmm3					; xmm2(baja, alta) =  parte imaginaria * (baja)cos y (alta)sin
				addsubpd xmm0, xmm2					; xmm0 = (baja)parte imaginaria del producto, (alta)parte real
				addpd xmm4, xmm0					; Acumulamos en xmm4 el resultado 
				add eax, 16							; Actualizamos el indice para conseguir el siguiente complejo
				inc qword[k]
				dec ecx
				cmp ecx, 0
				jne LoopK

			movupd [res_complex+edx], xmm4			; Almacenamos el resultado de cada dft
			add edx, 16

			mov ecx, ebx
			inc qword[j]
		cmp ecx, 0
		jne LoopJ
		ret

		;
		; Calcula -2*pi*j*k/TAM
		;
		Angulo:		
			finit	
			fldpi
			fldpi
			faddp
			fild qword[menosuno]
			fmulp
			fild qword[TAM]
			fdivp
			fild qword[j]
			fmulp
			fild qword[k]
			fmulp
			ret
