ORG 0

	mov	DPTR, #test_data	; adres poczatkowy danych
	mov	R0, #30h		; adres poczatkowy tablicy
	lcall	copy_data

	mov	R0, #30h		; adres poczatkowy tablicy
	mov	R2, #9			; dlugosc tablicy
	lcall	bubble_sort_iram

	sjmp	$

;---------------------------------------------------------------------
; Kopiowanie danych z pamieci programu (CODE) do pamieci IRAM
; Dane CODE: pierwszy bajt - licznik danych, kolejne bajty  - dane
; Wejscie:  DPTR - adres poczatkowy bloku danych (CODE)
;           R0   - adres poczatkowy (IRAM)
;---------------------------------------------------------------------
copy_data:
	MOVC	A, @A+DPTR		; pobieramy dlugosc tablicy
	JZ	copy_exit
	MOV	R2, A
copy_loop:
	INC	DPTR			; przechodzimy do nastepnej komorki xram
	CLR	A
	MOVC	A, @A+DPTR		; pobieramy wartosc komorki
	MOV	@R0, A			; przenosimy do iram
	INC	R0			; przechodzimy do nastepnej komorki iram
	DJNZ	R2, copy_loop		; powtarzamy poki dlugosc nie jest zerowa
copy_exit:
	ret

;---------------------------------------------------------------------
; Sortowanie babelkowe (rosnaco) w pamieci wewnetrznej (IRAM)
; Wejscie:  R0 - adres poczatkowy tablicy
;           R2 - dlugosc tablicy
;---------------------------------------------------------------------
bubble_sort_iram:
	CJNE	R2, #2, sort_start	; sortujemy jesli dlugosc wieksza niz 1
sort_start:
	JC	sort_exit
	MOV	A, R0
	MOV	R1, A			; w R1 trzymamy adres poczatkowy
	DEC	R2			; mamy przejsc przez tablice n-1 razy
	MOV	A, R2
	MOV	R3, A			; w R3 trzymamy	licznik petli wewnetrznej
	MOV	R4, A			; w R4 trzymamy licznik petli zewnetrznej		
outer_loop:
	MOV	A, R1			; pobieramy adres poczatkowy tablicy
	MOV	R0, A
	MOV	A, R2			; resetujemy licznik petli wewnetrznej
	MOV	R3, A
	CLR	F0			; F0 sluzy jako flaga, ze zamienialismy element
inner_loop:
	INC	R0			
	MOV	A, @R0			; pobieramy zawartosc nastepnej komorki
	DEC	R0
	CLR	C
	SUBB	A, @R0			; jesli nastepna komorka jest wieksza, zamieniamy miejscami
	JNC	skip_swap
	LCALL	swap_elems
	SETB	F0			; ustawiamy flage zamiany elementow
skip_swap:
	INC	R0			; przechodzimy do nastepnej komorki
	DJNZ	R3, inner_loop
	JNB	F0, sort_exit		; jesli nie zamienialismy element, mozemy konczyc
	DJNZ	R4, outer_loop
sort_exit:
	ret

;---------------------------------------------------------------------
; Zamiana elementu miejscami z nastepnym
; Wejscie:  R0 - adres elementu
;---------------------------------------------------------------------
swap_elems:
	MOV	A, @R0			; pobieramy wartosc komorki
	INC	R0			; przechodzimy do nastepnej komorki
	XCH	A, @R0
	DEC	R0			; przechodzimy do poprzedniej komorki
	XCH	A, @R0
	ret

test_data:
	DB	0
	DB	6, 5, 3, 7, 4, 2, 0, 1, 9

END