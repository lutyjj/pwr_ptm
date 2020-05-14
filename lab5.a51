;---------------------------------------------------------------------
P5		EQU	0F8h		; adres P5 w obszarze SFR
P7		EQU	0DBh		; adres P7 w obszarze SFR
;---------------------------------------------------------------------
ROWS		EQU	P5		; wiersze na P5.7-4
COLS		EQU	P7		; kolumny na P7.3-0
;---------------------------------------------------------------------
LEDS		EQU	P1		; diody LED na P1 (0=ON)
;---------------------------------------------------------------------

ORG 0

main_loop:
	lcall	kbd_read
	lcall	kbd_display
	sjmp	main_loop

;---------------------------------------------------------------------
; Uaktywnienie wybranego wiersza klawiatury
;
; Wejscie: A - numer wiersza (0 .. 3)
;---------------------------------------------------------------------
kbd_select_row:
	MOV	R0, A			; licznik wierszy
	MOV	A, #01111111b		; maska dla rotacji wybranego wiersza
	CJNE	R0, #4, in_range	; sprawdzenie czy numer jest w zakresie 
in_range:	
	JC	loop			; jesli jest w zakresie, zaczynamy petle
	MOV	A, #11111111b		; jesli nie, wylaczamy wszystkie wiersze
	SJMP	end_loop
loop:
	RR	A
	DJNZ	R0, continue_loop	; jesli licznik nie wyzerowal sie, zapetlamy sie
	SJMP	end_loop		; jesli wyzerowal sie, konczymy
continue_loop:
	SJMP 	loop			; petla
end_loop:
	ANL	ROWS, #00001111b	; zachowanie bitow niewykorzystywanych
	ANL	A, #11110000b		; zachowanie bitow wierszy
	ORL	ROWS, A			; laczymy niewykorzystane bity z wybranym wierszem
	RET

;---------------------------------------------------------------------
; Odczyt wybranego wiersza klawiatury
;
; Wejscie: A  - numer wiersza (0 .. 3)
; Wyjscie: CY - stan wiersza (0 - brak klawisza, 1 - wcisniety klawisz)
;	   A  - kod klawisza (0 .. 3)
;---------------------------------------------------------------------
kbd_read_row:
	LCALL	kbd_select_row
	MOV	A, COLS
	CPL	A
	ANL 	A, #00001111b		; wyczyszczamy nieistotne bity
	CLR	C			
	JZ	exit_kbd_read_row	; jesli A jest pusty, nie zostal wybrany wiersz, konczymy
	MOV	R1, #0			; licznik odczytanych kolumn
row_loop:
	JB	ACC.3, exit_row_loop	; rotujemy kolumny poki nie znajdziemy wcisniejty klawisz
	RL	A
	INC	R1			; zwiekszamy kod klawiszy
	SJMP	row_loop
exit_row_loop:
	SETB	C			; wlaczamy sygnalizacje wcisnietej klawiszy
	MOV	A, R1			; przenosimy kod wybranej klawiszy do akumulatora
exit_kbd_read_row:
	RET

;---------------------------------------------------------------------
; Odczyt calej klawiatury
;
; Wyjscie: CY - stan klawiatury (0 - brak klawisza, 1 - wcisniety klawisz)
; 	   A - kod klawisza (0 .. 15)
;---------------------------------------------------------------------
kbd_read:
	MOV	R2, #0			; licznik wierszy
kbd_row_loop:
	MOV	A, R2			; zaczynamy od pierwszego wiersza
	LCALL 	kbd_read_row
	JC	kbd_calc_code		; jesli klawisz wcisniety, przechodzimy do obliczenia kodu
	INC	R2
	CJNE	R2, #4, kbd_row_loop	; sprawdzamy czy licznik wierszy jest w zakresie
	SJMP	end_kbd_read
kbd_calc_code:
	MOV	R3, A			; kopiujemy kod klawisza w wierszu do rejestru
	MOV	A, R2			; przenosimy numer wiersza do akumulatora
	RL	A
	RL	A
	ADD	A, R3
	SETB	C			; wlaczamy sygnalizacje wcisniecia klawiszy
end_kbd_read:
	ret

;---------------------------------------------------------------------
; Wyswietlenie stanu klawiatury
;
; Wejscie: CY - stanu klawiatur (0 - brak klawisza, 1 - wcisniety klawisz)
; 	   A  - kod klawisza (0 .. 15)
;---------------------------------------------------------------------
kbd_display:
	JC	enable_leds		; jesli nie ma wcisniecia
	MOV	LEDS, #11111111b	; wylaczamy wszystkie diody
	SJMP	end_kbd_display
enable_leds:
	CPL	A			; odwracamy kod klawiszy
	CLR	ACC.7			; wlaczamy diode wcisniecia
	MOV	LEDS, A
end_kbd_display:	
	ret

END