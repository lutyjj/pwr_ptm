ORG 0

	LCALL	test_reverse_xram
	sjmp	$

test_reverse_iram:
	mov	R0, #30h	; adres poczatkowy tablicy
	mov	R2, #8		; dlugosc tablicy
	lcall	fill_iram

	mov	R0, #30h	; adres poczatkowy tablicy
	mov	R2, #8		; dlugosc tablicy
	lcall	reverse_iram
	sjmp	$

test_reverse_xram:
	mov	DPTR, #8000h	; adres poczatkowy tablicy
	mov	R2, #8		; dlugosc tablicy R3|R2
	mov	R3, #0
	lcall	fill_xram

	mov	DPTR, #8000h	; adres poczatkowy tablicy
	mov	R2, #8		; dlugosc tablicy R3|R2
	mov	R3, #0
	lcall	reverse_xram
	sjmp	$
test_string:
	mov	DPTR, #text	; adres poczatkowy stringu (CODE)
	mov	R0, #30h	; adres poczatkowy stringu (IRAM)
	lcall	copy_string

	mov	R0, #30h	; adres poczatkowy stringu (IRAM)
	lcall	reverse_string

	mov	R0, #30h	; adres poczatkowy stringu (IRAM)
	lcall	count_letters

	sjmp	$

;---------------------------------------------------------------------
; Wypelnianie tablicy ciagiem liczbowym 1,2,3, ... (IRAM)
; Wejscie:  R0 - adres poczatkowy tablicy
;           R2 - dlugosc tablicy
;---------------------------------------------------------------------
fill_iram:
	MOV	A, #0			; licznik
loop_f_iram:
	INC	A
	MOV	@R0, A
	INC	R0
	DJNZ	R2, loop_f_iram	
	ret

;---------------------------------------------------------------------
; Wypelnianie tablicy ciagiem liczbowym 1,2,3, ... (XRAM)
; Wejscie:  DPTR  - adres poczatkowy tablicy
;           R3|R2 - dlugosc tablicy
;---------------------------------------------------------------------
fill_xram:
	MOV	A, #0			; licznik
	DEC	R2
loop_f_xram:
	INC	A
	MOVX	@DPTR, A		; przenosimy licznik do DPTR
	INC	DPTR
	
	DEC	R2			; zmniejszamy dlugosc tablicy (Low)
	CJNE	R2, #0FFh, loop_f_xram	; sprawdzamy czy byla ona zerowa
	
	PUSH	ACC
	MOV	A, R2			
	INC	A
	ORL	A, R3			; sprawdzenie czy dlogosc tablicy sie wyzerowala
	JZ	exit
	DEC	R3			; zmniejszamy dlugosc tablicy ((High)
	POP	ACC
	SJMP	loop_f_xram
exit:
	POP	ACC
	ret

;---------------------------------------------------------------------
; Odwracanie tablicy w pamieci wewnetrznej (IRAM)
; Wejscie:  R0 - adres poczatkowy tablicy
;           R2 - dlugosc tablicy
;---------------------------------------------------------------------
reverse_iram:
	MOV	A, R0
	ADD	A, R2			; obliczamy adres koncowy tablicy
	DEC	A
	MOV	R1, A
	MOV	A, R2			; dzielimy dlugosc przez 2
	RRC	A
	MOV	R2, A			; korzystamy z R2 jak z licznika
loop_r_iram:
	MOV	A, @R0
	XCH	A, @R1			; zamieniamy zawartosc R0 i R1 miejscami
	MOV	@R0, A
	INC	R0			; przechodzimy do nastepnej komorki
	DEC	R1			; przechodzimy do poprzedniej komorki
	DJNZ	R2, loop_r_iram
	ret

;---------------------------------------------------------------------
; Odwracanie tablicy w pamieci zewnetrznej (XRAM)
; Wejscie:  DPTR  - adres poczatkowy tablicy
;           R3|R2 - dlugosc tablicy
;---------------------------------------------------------------------
reverse_xram:
	MOV	A, DPH
	ADD	A, R3			; obliczamy adres koncowy XRAM (High)
	MOV	R1, A		
	
	MOV	A, DPL
	ADD	A, R2			; obliczamy adres koncowy XRAM (Low)
	DEC	A
	MOV	R0, A
	
	MOV	A, R3			; dzielenie przez 2 dlugosci tablicy
	RRC	A
	MOV	R3, A
	MOV	A, R2
	RRC	A
	MOV	R2, A		
	
loop_r_xram:
	MOVX	A, @DPTR
	MOV	R4, A			; pobieramy zawartosc DPTR z przodu
	LCALL	dptr_conv		; przenosimy DPTR na adres koncowy R1|R0
	MOVX	A, @DPTR	
	MOV	R5, A			; pobieramy zawartosc DPTR z konca
	MOV	A, R4
	MOVX	@DPTR, A		; zapisujemy do konca zawartosc z przodu
	LCALL	dptr_conv		; przenosimy DPTR na adres poczatkowy
	MOV	A, R5
	MOVX	@DPTR, A		; zapisujemy do poczatku zawartosc z konca
	INC	DPTR			; przechodzimy do nastepnej komorki
	DEC	R0			; zmniejszamy adres koncowy DPTR/R0 (Low)
	
	DEC	R2			; zmniejszamy licznik powtorzen (Low)
	CJNE	R2, #0FFh, loop_r_xram
	
	PUSH	ACC
	MOV	A, R2		
	INC	A
	ORL	A, R3			; sprawdzamy czy licznik sie nie wyzerowal
	JZ	exit_xram		; jesli tak, konczymy
	POP	ACC
	
	DEC	R3			; jesli nie, zmniejszamy licznik powtorzen (High)
	DEC	R1			; zmniejszamy adres koncowy DPTR/R1 (High)
	
	SJMP	loop_r_xram
exit_xram:
	POP	ACC
	ret

dptr_conv:
	PUSH 	ACC
	MOV 	A, DPL
	MOV 	DPL, R0
	MOV 	R0, A
	MOV 	A, DPH
	MOV 	DPH, R1
	MOV 	R1, A
	POP 	ACC
	RET

;---------------------------------------------------------------------
; Kopiowanie stringu z pamieci programu (CODE) do pamieci IRAM
; Wejscie:  DPTR - adres poczatkowy stringu (CODE)
;           R0   - adres poczatkowy stringu (IRAM)
;---------------------------------------------------------------------
copy_string:
	MOVC 	A, @A+DPTR		; pobieramy char z DPTR
	MOV	@R0, A			; przenosimy char do komorki R0
	JZ	end_cpy			; jesli char jest zerowy, konczymy
	INC	R0			; przechodzimy do nastepnej komorki R0
	INC	DPTR			; przechodzimy do nastepnej komorki DPTR
	CLR	A
	SJMP	copy_string
end_cpy:
	ret

;---------------------------------------------------------------------
; Odwracanie stringu w pamieci IRAM
; Wejscie:  R0 - adres poczatkowy stringu
;---------------------------------------------------------------------
reverse_string:
	MOV	R2, #0			; licznik dlugosci tablicy
	MOV	A, R0			; nie mozemy zmieniac oryginalnego adresu
loop_r_string:
	CJNE	@R1, #0, not_end	; sprawdzamy czy string sie skonzyl
	SJMP	start_reverse
not_end:				; jesli nie, przechodzimy do nastepnej komorki
	INC	R1
	INC	R2
	SJMP	loop_r_string
start_reverse:
	LCALL	reverse_iram
	ret

;---------------------------------------------------------------------
; Zliczanie liter w stringu umieszczonym w pamieci IRAM
; Wejscie:  R0 - adres poczatkowy stringu
; Wyjscie:  A  - liczba liter w stringu
;---------------------------------------------------------------------
count_letters:
	MOV	A, #0
start_counter:
	CJNE	@R0, #'A', big_A
big_A:
	JC	exit_count
	CJNE	@R0, #'Z', big_Z
big_Z:
	JC	inc_counter
	CJNE	@R0, #'a', small_a
small_a:
	JC	exit_count
	CJNE	@R0, #'z', small_z
small_z:
	JNC	exit_count
inc_counter:
	INC	A
	
exit_count:
	INC	R0
	CJNE	@R0, #0, start_counter
	ret
	
text:	DB	'Hello world 0123456789', 0

END
