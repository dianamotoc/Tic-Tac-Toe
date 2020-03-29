.386
.model flat, stdcall
includelib msvcrt.lib

extern exit: proc
extern malloc: proc
extern memset: proc

includelib canvas.lib
extern BeginDrawing: proc

public start

.data
cnt_aux DD 0
cnt DD 0
vector_simboluri DB 1, 1, 1, 1, 1, 1, 1, 1, 1   ;;un vector de 9 elemente care initial e gol pentru a alterna simbolurile
window_title DB "Tic Tac Toe", 0
area_width EQU 630
area_height EQU 630
area DD 0

counter DD 0 ; numara evenimentele de tip timer

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

x DD 0
y DD 0

symbol_width EQU 10
symbol_height EQU 20

include digits.inc
include letters.inc

dim_width EQU 41
dim_height EQU 41

include ZEROdraw.inc
include Xdraw.inc

;vector_simboluri DB 1, 1, 1, 1, 1, 1, 1, 1, 1   ;;un vector de 9 elemente care initial e gol pentru a alterna simbolurile
;cnt DD 0     ;; porneste de la 0 si merge pana la 8 si cu ajutorul lui verific paritatea ca sa stiu daca trebuie sa pun X sau 0

.code
; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y

make_text proc
	push ebp
	mov ebp, esp
	pusha

	mov eax, [ebp + arg1] ; citim simbolul de afisat
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
	make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
	make_space: 
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters

	draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
	bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
	bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	mov dword ptr [edi], 0
	jmp simbol_pixel_next
	simbol_pixel_alb:
	mov dword ptr [edi], 0FFFFFFh
	simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm

make_X proc
	push ebp
	mov ebp, esp
	pusha

	mov eax, [ebp + arg1] ; citim simbolul de afisat
	cmp eax, 'X'
	je etichetaX
	etichetaZERO:
		lea esi, ZEROdraw
		jmp draw_text_pers
	
	etichetaX:
		lea esi, Xdraw

	draw_text_pers:
	mov ecx, dim_height
	bucla_simbol_linii_:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, dim_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, dim_width
	bucla_simbol_coloane_:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb_
	mov dword ptr [edi], 0
	jmp simbol_pixel_next_
	simbol_pixel_alb_:
	mov dword ptr [edi], 0FFFFFFh
	simbol_pixel_next_:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane_
	pop ecx
	loop bucla_simbol_linii_
	popa
	mov esp, ebp
	pop ebp
	ret
make_X endp

make_X_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_X
	add esp, 16
endm

vertical_draw macro x, y 
local bucla
	pusha 				;punem registrele pe stiva ca sa nu pierdem informatiile
	mov edi, area
	mov esi, area_width
	shl esi, 2
	
	mov eax, y
	mov ebx, area_width
	mul ebx				;suntem la linia care trebuie, mai avem nevoie sa adunam x
	
	add eax, x
	shl eax, 2
	
	mov ecx, 300   		;lungimea liniei
	
	bucla: 
		mov ebx, eax
		add ebx, edi
		mov dword ptr[ebx], 8000000
		add eax, esi   ;ajungem un nivel mai jos
	loop bucla
	popa
endm

horizontal_draw macro x, y
local bucla
	pusha
	mov eax, y
	mov esi, area_width
	mov edi, area
	shl esi, 2
	
	mov ebx, area_width
	mul ebx
	add eax, x  		;;am ajuns la punctul de unde vrem sa desenam
	shl eax, 2
	
	mov ecx, 360
	bucla:
		mov ebx, eax
		add ebx, edi
		mov dword ptr[ebx], 25000
		add eax, 4   	;;ajungem la punctul urmator unde vrem sa desenam
						;; adunam 4 pentru ca noi avem double word
	loop bucla
	popa
endm

square macro
	vertical_draw 130, 120
	vertical_draw 250, 120
	vertical_draw 370, 120
	vertical_draw 490, 120
	horizontal_draw 130, 120
	horizontal_draw 130, 220
	horizontal_draw 130, 320
	horizontal_draw 130, 420
endm

verif_parity proc
	push ebp
	mov ebp, esp
	
	
	mov eax, cnt
	mov edx, 0
	mov ebx, 2
	div ebx
	;;eax avem restul impartirii contorului la 2
	mov eax, edx
	
	mov esp, ebp
	pop ebp
	ret 
verif_parity endp

algorithm proc
	;aici se scrie codul
	mov eax, 0
	mov bl, [vector_simboluri + 4]
	
	;;comparari pentru a doua linie orizontala
	cmp bl, [vector_simboluri + 5]
	je casuta_4_5
	jmp gata0
	casuta_4_5:
		cmp bl, [vector_simboluri + 3]
		je casuta_4_3
	jmp gata0
	casuta_4_3:
		mov al, bl
	jmp gata
	
	;;comparari pentru a doua linie verticala
	gata0:
	cmp bl, [vector_simboluri + 7]
	je casuta_4_7
	jmp gata1
	casuta_4_7:
		cmp bl, [vector_simboluri + 1]
		je casuta_7_1
	jmp gata1
	casuta_7_1:
		mov al, bl
	jmp gata
	
	gata1:
	;;comparari pentru diagonala principala
	cmp bl, [vector_simboluri]
	je casuta_4_0
	jmp gata2
	casuta_4_0:
		cmp bl, [vector_simboluri + 8]
		je casuta_4_8
	jmp gata2
	casuta_4_8:
		mov al, bl
	jmp gata
	
	gata2:
	;;comparari pentru diagonala secundara
	cmp bl, [vector_simboluri + 2]
	je casuta_4_2
	jmp gata3
	casuta_4_2:
		cmp bl, [vector_simboluri + 6]
		je casuta_4_6
	jmp gata3
	casuta_4_6:
		mov al, bl
	jmp gata
	
	gata3:
	;;comparari pentru prima linie verticala
	mov bl, [vector_simboluri + 3]
	cmp bl, [vector_simboluri]
	je casuta_3_0
	jmp gata4
	casuta_3_0:
		cmp bl, [vector_simboluri + 6]
		je casuta_3_6
	jmp gata4
	casuta_3_6:
		mov al, bl
	jmp gata
	
	gata4:
	;;comparari pentru ultima linie verticala
	mov bl, [vector_simboluri + 5]
	cmp bl, [vector_simboluri + 2]
	je casuta_5_2
	jmp gata5
	casuta_5_2:
		cmp bl, [vector_simboluri + 8]
		je casuta_5_8
	jmp gata5
	casuta_5_8:
		mov al, bl
	jmp gata
		
	gata5:
	;;comparari pentru prima linie orizontala
	mov bl, [vector_simboluri + 1]
	cmp bl, [vector_simboluri]
	je casuta_1_0
	jmp gata6
	casuta_1_0:
		cmp bl, [vector_simboluri + 2]
		je casuta_1_2
	jmp gata6
	casuta_1_2:
		mov al, bl
	jmp gata
		
	gata6:
	;;comparari pentru ultima linie orizontala
	mov bl, [vector_simboluri + 7]
	cmp bl, [vector_simboluri + 6]
	je casuta_6_7
	jmp gata
	casuta_6_7:
		cmp bl, [vector_simboluri + 8]
		je casuta_7_8
	jmp gata
	casuta_7_8:
		mov al, bl
	gata:
	ret
algorithm endp

algorithm_2 proc
mov bl, [vector_simboluri + 8]
	cmp bl, [vector_simboluri + 5]
	je casuta_8_5
	jmp linie_verticala
	casuta_8_5:
		cmp bl, [vector_simboluri + 2]
		je casuta_8_2
	jmp linie_verticala
	casuta_8_2:
		mov al, bl
	
	linie_verticala:
		cmp bl, [vector_simboluri + 7]
		je casuta_8_7
		jmp final_drum
		casuta_8_7:
			cmp bl, [vector_simboluri + 6]
			je casuta_8_6
		jmp final_drum
		casuta_8_6:
			mov al, bl	
	
	final_drum:
	ret
algorithm_2 endp

simbol_alternativ proc
	push ebp
	mov ebp, esp
	pusha
	
	
	cmp cnt, 9
	je gata
	
	mov edx, [ebp + 12]
	mov ebx, [ebp + 8]
	
	;;punem contorul pe stiva pentru a-i verifica paritatea
	; REZOLVA ASTA->     IDEEA E CA AICI SE STRICA EDX SAU EBX CAND SE APELEAZA FUNCTIA PENTRU CA LA IMPARTIRE STRICAM EDX
	push ebx
	push edx
	;push cnt
	call verif_parity
	
	pop edx
	pop ebx
	
	cmp eax, 1
	je punemZERO
	make_X_macro "X", area, edx, ebx
	
	
	
	jmp sfarsit
	punemZERO:
	make_X_macro "0", area, edx, ebx 

	sfarsit: 
	inc cnt
	;cmp cnt, 8
		;jg gata
	jmp gata
	;sari:
	;	make_text_macro 'T', area, 50, 50
	;	make_text_macro 'I', area, 60, 50
	;	make_text_macro 'E', area, 70, 50 
	gata:
	popa
	mov esp, ebp
	pop ebp
	
	ret 8
simbol_alternativ endp 

display_TIE macro 
	make_text_macro 'T', area, 50, 50
	make_text_macro 'I', area, 60, 50
	make_text_macro 'E', area, 70, 50
endm

simbol_alternativ_macro macro x, y 
	push x
	push y
	call simbol_alternativ
endm

fix_in_centre proc 
	push ebp
	mov ebp, esp
	pusha

	mov edx, [ebp + arg2]   ;x
	mov ebx, [ebp + arg3]   ;y
	mov x, edx
	mov y, ebx
	
	
	;;verificari cadrane         Verificam mai intai daca suntem pe prima linie si de acolo verificam in ce careu de pe prima linie ne aflam
	;;  						 Apoi trecem la a treia linie ca sa mai scutim din cazuri
	;;							 In cele din urma, ramanem cu a doua linie, excluzandu-le pe celelalte doua ne scutim de niste calcule in plus
	;;							 Pentru careu, verificam mai intai daca e in primul careu, apoi in ultimul, ramanand cu cel din mijloc
	cmp y, 220
	jl linie_1   ;;verificam daca am dat click pe linia intai
	
	cmp y, 320
	jg linie_3	;;verificam daca am dat click pe linia a treia
	
	;;a ramas doar linia a 2-a neevaluata
	cmp x, 250
	jl ocup_apatra_casuta
			
	cmp x, 370
	jg ocup_asasea_casuta

	cmp [vector_simboluri + 4], 1
	jne gata
	simbol_alternativ_macro 290, 250  ;;a 5 a casuta
	call verif_parity 
		cmp eax, 0		;;inseamna ca am pus 0 si marcam acest lucru in vectorul nostru
		je impar_casuta5
		mov [vector_simboluri + 4], 'X' 
		jmp gata
		impar_casuta5:
			mov [vector_simboluri + 4], '0' 
	
	jmp gata
	
	linie_1:
		cmp x, 250
		jl ocup_prima_casuta
		
		cmp x, 370
		jg ocup_atreia_casuta
		
		
		cmp [vector_simboluri + 1], 1
		jne gata
		simbol_alternativ_macro 290, 150   ;; a doua casuta
		call verif_parity 
		cmp eax, 0		;;inseamna ca am pus 0 si marcam acest lucru in vectorul nostru
		je impar_casuta2
		mov [vector_simboluri + 1], 'X'       ;;punem invers pentru ca aici prima data creste cnt si apoi imparte la 2
		jmp gata
		impar_casuta2:
			mov [vector_simboluri + 1], '0' 
				
		jmp gata
		
	ocup_prima_casuta:
		cmp [vector_simboluri], 1
		jne gata
		simbol_alternativ_macro 170, 150
		call verif_parity 
		cmp eax, 0		;;inseamna ca am pus 0 si marcam acest lucru in vectorul nostru
		je impar_casuta1
		mov [vector_simboluri], 'X' 
		jmp gata
		impar_casuta1:
			mov [vector_simboluri], '0' 
		jmp gata
		
	ocup_atreia_casuta:
		cmp [vector_simboluri + 2], 1
		jne gata
		simbol_alternativ_macro 413, 150
		call verif_parity 
		cmp eax, 0		;;inseamna ca am pus 0 si marcam acest lucru in vectorul nostru
		je impar_casuta3
		mov [vector_simboluri + 2], 'X' 
		jmp gata
		impar_casuta3:
			mov [vector_simboluri + 2], '0' 
		jmp gata
		
	linie_3:
		cmp x, 250
		jl ocup_asaptea_casuta
		
		cmp x, 370
		jg ocup_anoua_casuta
		
		cmp [vector_simboluri + 7], 1
		jne gata
		simbol_alternativ_macro 290, 350   ;a opta casuta
		call verif_parity 
		cmp eax, 0		;;inseamna ca am pus 0 si marcam acest lucru in vectorul nostru
		je impar_casuta8
		mov [vector_simboluri + 7], 'X' 
		jmp gata
		impar_casuta8:
			mov [vector_simboluri + 7], '0' 
		
		jmp gata
		
	ocup_asaptea_casuta:
		cmp [vector_simboluri + 6], 1
		jne gata
		simbol_alternativ_macro 170, 350
		call verif_parity 
		cmp eax, 0		;;inseamna ca am pus 0 si marcam acest lucru in vectorul nostru
		je impar_casuta7
		mov [vector_simboluri + 6], 'X' 
		jmp gata
		impar_casuta7:
			mov [vector_simboluri + 6], '0' 
		jmp gata
		
	ocup_anoua_casuta:
		cmp [vector_simboluri + 8], 1
		jne gata
		simbol_alternativ_macro 413, 350
		call verif_parity 
		cmp eax, 0		;;inseamna ca am pus 0 si marcam acest lucru in vectorul nostru
		je impar_casuta9
		mov [vector_simboluri + 8], 'X' 
		jmp gata
		impar_casuta9:
			mov [vector_simboluri + 8], '0' 
		
		jmp gata
		
	ocup_apatra_casuta:
		cmp [vector_simboluri + 3], 1
		jne gata
		simbol_alternativ_macro 170, 250
		call verif_parity 
		cmp eax, 0		;;inseamna ca am pus 0 si marcam acest lucru in vectorul nostru
		je impar_casuta4
		mov [vector_simboluri + 3], 'X' 
		jmp gata
		impar_casuta4:
			mov [vector_simboluri + 3], '0' 
		jmp gata
		
	ocup_asasea_casuta:
		cmp [vector_simboluri + 5], 1
		jne gata
		simbol_alternativ_macro 413, 250
		call verif_parity 
		cmp eax, 0		;;inseamna ca am pus 0 si marcam acest lucru in vectorul nostru
		je impar_casuta6
		mov [vector_simboluri + 5], 'X' 
		jmp gata
		impar_casuta6:
			mov [vector_simboluri + 5], '0' 
		jmp gata
	miscare_nepermisa:
	gata:
	popa
	mov esp, ebp
	pop ebp
	ret 8
fix_in_centre endp


draw proc
	push ebp
	mov ebp, esp
	pusha

	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp eax, 2
	jz evt_timer ; nu s-a efectuat click pe nimic
	;mai jos e codul care intializeaza fereastra cu pixeli albi
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 255
	push area
	call memset
	add esp, 12
	
	square ; macro care deseneaza tabla de joc
	
	jmp final_draw
	
	evt_click:
			cmp cnt_aux, -1
			je final_draw
			
			pusha
		
			mov edx, [ebp + arg2]   ;x
			mov ebx, [ebp + arg3]   ;y
			

			mov x, edx
			mov y, ebx
			cmp y, 120 ;verificam daca e in partea de sus a tablei
			jl registre
			cmp y, 420 ;verificam daca e in partea de jos
			jg registre
			cmp x, 490	;verificam daca e in partea dreapta
			jg registre
			cmp x, 130	;verificam daca e in partea stanga
			jl registre
		;;punem coordonatele x si y pe stiva
			push edx
			push ebx
			
			
			
			call fix_in_centre
			
			call algorithm
				cmp eax, 'X'
				je Xwins
				cmp eax, '0'
				je ZEROwins
			
			call algorithm_2
				cmp eax, 'X'
				je Xwins
				cmp eax, '0'
				je ZEROwins
			cmp cnt, 9
			je TIE
			
			jmp sari
			
			Xwins:
			make_X_macro "X", area, 200, 50
			make_text_macro "A", area, 260, 55
			make_text_macro " ", area, 270, 55
			make_text_macro "C", area, 280, 55
			make_text_macro "A", area, 290, 55
			make_text_macro "S", area, 300, 55
			make_text_macro "T", area, 310, 55
			make_text_macro "I", area, 320, 55
			make_text_macro "G", area, 330, 55
			make_text_macro "A", area, 340, 55
			make_text_macro "T", area, 350, 55
			mov cnt_aux, -1
			jmp sari 
			ZEROwins:
			make_X_macro "0", area, 200, 50
			make_text_macro "A", area, 260, 55
			make_text_macro " ", area, 270, 55
			make_text_macro "C", area, 280, 55
			make_text_macro "A", area, 290, 55
			make_text_macro "S", area, 300, 55
			make_text_macro "T", area, 310, 55
			make_text_macro "I", area, 320, 55
			make_text_macro "G", area, 330, 55
			make_text_macro "A", area, 340, 55
			make_text_macro "T", area, 350, 55
			mov cnt_aux, -1
			jmp sari
			TIE:
			make_text_macro "T", area, 260, 55
			make_text_macro " ", area, 270, 55
			make_text_macro "I", area, 280, 55
			make_text_macro " ", area, 290, 55
			make_text_macro "E", area, 300, 55
			mov cnt_aux, -1
			sari:
			popa
		jmp final
		
		
		
	registre:
		popa
		jmp final_draw
	final:
	
	
	;bucla:
		

	JMP final_draw 
	evt_timer:

	afisare_litere:
	
	;scriem un mesaj
	make_text_macro 'T', area, 10, 10
	make_text_macro 'I', area, 20, 10
	make_text_macro 'C', area, 30, 10
	make_text_macro '-', area, 40, 10
	make_text_macro 'T', area, 50, 10
	make_text_macro 'A', area, 60, 10
	make_text_macro 'C', area, 70, 10
	make_text_macro '-', area, 80, 10
	make_text_macro 'T', area, 90, 10
	make_text_macro 'O', area, 100, 10
	make_text_macro 'E', area, 110, 10

	final_draw:
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
;alocam memorie pentru zona de desenat
mov eax, area_width
mov ebx, area_height
mul ebx
shl eax, 2
push eax
call malloc
add esp, 4
mov area, eax
;apelam functia de desenare a ferestrei
; typedef void (*DrawFunc)(int evt, int x, int y);
; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
push offset draw
push area
push area_height
push area_width
push offset window_title
call BeginDrawing
add esp, 20

;terminarea programului
push 0
call exit
end start