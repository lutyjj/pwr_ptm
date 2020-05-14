;------------------------------------------------------------------------------
LEDS		EQU	P1			; diody LED na P1 (0=ON)
LEDS_STATE	EQU	34h			; stan diod
;------------------------------------------------------------------------------
TIME_MS		EQU	50			; czas w [ms]
CYCLES		EQU	(1000 * TIME_MS)	; czas w cyklach (f = 12 MHz)
LOAD		EQU	(65536 - CYCLES)	; wartosc ladowana do TH0|TL0
;------------------------------------------------------------------------------
CNT_50		EQU	30h			; licznik w ramach sekundy
SEC		EQU	31h			; sekundy
MIN		EQU	32h			; minuty
HOUR		EQU	33h			; godziny
;------------------------------------------------------------------------------

ORG 0
	MOV	LEDS_STATE, #0FFh		; zgaszenie wszystkich diod
	
leds_loop:
	MOV	R7, #20				; opoznienie 20 x 50 ms = 1 s
	MOV	LEDS, LEDS_STATE
	LCALL	delay_nx50ms
	
	MOV	A, LEDS_STATE
	JNZ	led_shift			; przesuwanie diod o jeden w lewo
	MOV	A, #0FFh			; zgaszenie wszystkich diod
led_shift:
	RLC	A
	MOV	LEDS_STATE, A			; nowy stan diod
	SJMP	leds_loop

;---------------------------------------------------------------------
; Opoznienie 50 ms (zegar 12 MHz)
; 1 + 127 + 49470 + 254 + 2 = 49914 us ~= 50ms
;---------------------------------------------------------------------
delay_50ms:
	MOV 	R0, #127			; 1
loop_1:
	MOV 	R1, #195			; 1 127*1
loop_2:
	DJNZ 	R1, loop_2			; 2 195*127*2 = 49530
	DJNZ 	R0, loop_1			; 2 127*2 = 254
	RET					; 2

;---------------------------------------------------------------------
; Opoznienie n * 50 ms (zegar 12 MHz)
; R7 - czas x 50 ms
;---------------------------------------------------------------------
delay_nx50ms:
	LCALL 	delay_50ms
	DJNZ	R7, delay_nx50ms
	RET
;---------------------------------------------------------------------
; Opoznienie 50 ms z uzyciem Timera 0 (zegar 12 MHz)
;---------------------------------------------------------------------
delay_timer_50ms:
	CLR	TR0				; zatrzymanie timera
	MOV 	TMOD, #00000001B		; tryb 16-bit
	MOV	TH0, #HIGH(LOAD)		; przypisanie starzych bitow wartosci timera
	MOV	TL0, #LOW(LOAD)			; przypisanie mlodzych bitow wartosci timera
	CLR 	TF0				; zerowanie flagi pzepepelnenia
	SETB	TR0				; uruchomienie timera
loop:
	JNB 	TF0, loop			; czekanie na koniec timera
	RET

;---------------------------------------------------------------------
; Aktualizacja czasu w postaci (HOUR : MIN : SEC) | CNT_50
; Przy wywolywaniu procedury co 50 ms
; wykonywana jest aktualizacja czasu rzeczywistego
;---------------------------------------------------------------------
update_time:	
	DJNZ 	CNT_50, exit			; oczekiwanie 1s
seconds:
	MOV	CNT_50, #20
	INC	SEC
	MOV	A, SEC
	CJNE	A, #60, exit			; sprawdzenie czy sekundy == 60
	MOV	SEC, #0				; jesli tak, zerowanie sekund
	INC	MIN
minutes:
	MOV	A, MIN
	CJNE	A, #60, exit			; sprawdzenie czy minuty == 60
	MOV	MIN, #0				; jesli tak, zerowanie minut
	INC	HOUR
hours:
	MOV	A, HOUR
	CJNE	A, #24, exit			; sprawdzenie czy godziny == 60
	MOV	HOUR, #0			; jesli tak, zerowanie godzin
exit:
	RET

END