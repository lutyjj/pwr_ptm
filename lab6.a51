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
	CLR	A		; licznik
	CJNE	R2, #0,	loop_f_iram
	SJMP	exit_f_iram
loop_f_iram:
	INC	A
	MOV	@R0, A
	INC	R0
	DJNZ	R2, loop_f_iram
exit_f_iram:
	RET

;---------------------------------------------------------------------
; Wypelnianie tablicy ciagiem liczbowym 1,2,3, ... (XRAM)
; Wejscie:  DPTR  - adres poczatkowy tablicy
;           R3|R2 - dlugosc tablicy
;---------------------------------------------------------------------
fill_xram:
	MOV	R4, #0			; licznik <- bylo A nie R5
loop_f_xram:
	MOV 	A, R2			; sprawdzenie czy licznik nie jest zerowy
	ORL 	A, R3
	JZ 	exit_f_xram

	INC	R4
	MOV	A, R4
	MOVX	@DPTR, A		; przenosimy licznik do DPTR
	INC	DPTR
	
	MOV 	A, R2
	DEC	R2			; zmniejszamy dlugosc tablicy (Low)
	JNZ 	loop_f_xram
	DEC 	R3			; zmniejszamy dlugosc tablicy ((High)
	
	SJMP	loop_f_xram
exit_f_xram:
	RET

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
	CLR	C
	RRC	A
	JZ	exit_r_iram
	MOV	R2, A			; korzystamy z R2 jak z licznika
loop_r_iram:
	MOV	A, @R0
	XCH	A, @R1			; zamieniamy zawartosc R0 i R1 miejscami
	MOV	@R0, A
	INC	R0			; przechodzimy do nastepnej komorki
	DEC	R1			; przechodzimy do poprzedniej komorki
	DJNZ	R2, loop_r_iram
exit_r_iram:
	RET

;---------------------------------------------------------------------
; Odwracanie tablicy w pamieci zewnetrznej (XRAM)
; Wejscie:  DPTR  - adres poczatkowy tablicy
;           R3|R2 - dlugosc tablicy
;---------------------------------------------------------------------
reverse_xram:
	MOV	A, DPL
	ADD	A, R2			; obliczamy adres koncowy XRAM (Low)
	MOV	R0, A

	MOV	A, DPH
	ADDC	A, R3			; obliczamy adres koncowy XRAM (High)
	MOV	R1, A		
	
	MOV	A, R0			; sprawdzenie czy nie mamy zwiekszyc High
	DEC	R0
	JNZ	skip_dec
	DEC	R1
	
skip_dec:
	MOV	A, R3			; dzielenie przez 2 dlugosci tablicy
	RRC	A
	MOV	R3, A
	MOV	A, R2
	RRC	A
	MOV	R2, A		

loop_r_xram:
	MOV 	A, R2			; sprawdzenie czy licznik nie jest zerowy
	ORL 	A, R3
	JZ 	exit_r_xram

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

	MOV	A, R0			; sprawdzamy czy R0 wyzerowal sie
	DEC	R0			; zmniejszamy adres koncowy DPTR/R0 (Low)
	JNZ	dec_only_low	
	DEC	R1			; zmniejszamy adres koncowy DPTR/R1 (High)
	
dec_only_low:
	MOV	A, R2
	DEC 	R2			; zmniejszamy licznik powtorzen (Low)
	JNZ 	loop_r_xram
	DEC	R3			; jesli nie, zmniejszamy licznik powtorzen (High)
	SJMP	loop_r_xram
	
exit_r_xram:
	RET

;---------------------------------------------------------------------
; Zamiana DPH|DPL z R1|R0 miejscami.
; Wejscie:  DPTR  - adres poczatkowy tablicy
;           R1|R0 - potrzebny adres DPTR
; Wyjscie:  R1|R0 - poprzedni ares DPTR
;	    DPTR  - nowy adres, skonstruowany z R1|R0
;---------------------------------------------------------------------
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
	CLR	A
	MOVC 	A, @A+DPTR		; pobieramy char z DPTR
	MOV	@R0, A			; przenosimy char do komorki R0
	JZ	end_cpy			; jesli char jest zerowy, konczymy
	INC	R0			; przechodzimy do nastepnej komorki R0
	INC	DPTR			; przechodzimy do nastepnej komorki DPTR
	SJMP	copy_string
end_cpy:
	RET

;---------------------------------------------------------------------
; Odwracanie stringu w pamieci IRAM
; Wejscie:  R0 - adres poczatkowy stringu
;---------------------------------------------------------------------
reverse_string:
	MOV	R2, #0			; licznik dlugosci tablicy
	MOV	A, R0			; nie mozemy zmieniac oryginalnego adresu
	MOV	R1, A
loop_r_string:
	CJNE	@R1, #0, not_end	; sprawdzamy czy string sie skonzyl
	SJMP	start_reverse
not_end:				; jesli nie, przechodzimy do nastepnej komorki
	INC	R1
	INC	R2
	SJMP	loop_r_string
start_reverse:
	LCALL	reverse_iram
	RET

;---------------------------------------------------------------------
; Zliczanie liter w stringu umieszczonym w pamieci IRAM
; Wejscie:  R0 - adres poczatkowy stringu
; Wyjscie:  A  - liczba liter w stringu
;---------------------------------------------------------------------
count_letters:
	CLR	A
counter_loop:
	CJNE	@R0, #0, start_counter
	SJMP	exit_count
start_counter:
	CJNE	@R0, #'A', big_A
big_A:
	JC	inc_string
	CJNE	@R0, #'Z'+1, big_Z
big_Z:
	JC	inc_counter
	CJNE	@R0, #'a', small_a
small_a:
	JC	inc_string
	CJNE	@R0, #'z'+1, small_z
small_z:
	JNC	inc_string
inc_counter:
	INC	A
inc_string:
	INC	R0
	SJMP	counter_loop
exit_count:
	RET
	
text:	DB	'', 0

END
