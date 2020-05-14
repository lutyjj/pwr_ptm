;------------------------------------------------------------------------------
TIME_MS		EQU	50			; czas w [ms]
CYCLES		EQU	(1000 * TIME_MS)	; czas w cyklach (f = 12 MHz)
LOAD		EQU	(65536 - CYCLES)	; wartosc ladowana do TH0|TL0
;------------------------------------------------------------------------------
CNT_50		EQU	30h			; licznik w ramach sekundy
SEC		EQU	31h			; sekundy
MIN		EQU	32h			; minuty
HOUR		EQU	33h			; godziny

ALARM_SEC	EQU	34h			; alarm - sekundy
ALARM_MIN	EQU	35h			; alarm - minuty
ALARM_HOUR	EQU	36h			; alarm - godziny
ALARM_DURATION	EQU	37h			; alarm - pozostaly czas trwania [s]
	
SEC_CHANGE	EQU	0			; flaga zmiany sekund (BIT)
;------------------------------------------------------------------------------
LEDS		EQU	P1			; diody LED na P1 (0=ON)
ALARM		EQU	P1.7			; sygnalizacja alarmu
;------------------------------------------------------------------------------

CSEG AT 0
	SJMP	start
	
CSEG AT 0Bh	
;---------------------------------------------------------------------
; Obsluga przerwania Timera 0
;---------------------------------------------------------------------
T0_int:
	MOV	TH0, #HIGH(LOAD)		; przypisanie starzych bitow wartosci timera
	MOV	TL0, #LOW(LOAD)			; przypisanie mlodzych bitow wartosci timera
	PUSH	ACC				; odlozenie akumulatora na stos
	PUSH	PSW				; odlozenie pwn na stos
	DJNZ 	CNT_50, exit_clock		; obsluga czasu
seconds:
	SETB	SEC_CHANGE			; ustawienie flagi zmiany sekundy
	MOV	CNT_50, #20
	INC	SEC
	MOV	A, SEC
	CJNE	A, #60, exit_clock		; sprawdzenie czy sekundy == 60
	MOV	SEC, #0				; jesli tak, zerowanie sekund
	INC	MIN
minutes:
	MOV	A, MIN
	CJNE	A, #60, exit_clock		; sprawdzenie czy minuty == 60
	MOV	MIN, #0				; jesli tak, zerowanie minut
	INC	HOUR
hours:
	MOV	A, HOUR
	CJNE	A, #24, exit_clock		; sprawdzenie czy godziny == 60
	MOV	HOUR, #0			; jesli tak, zerowanie godzin
exit_clock:
	POP	PSW				; pobranie pwn ze stosu
	POP	ACC				; pobranie akumulatora ze stosu
	RETI

;---------------------------------------------------------------------
; Start programu
;---------------------------------------------------------------------
start:
	MOV	LEDS, #0FFh			; zgaszenie wszystkich diod
	LCALL	clock_init
	LCALL	timer_init

;---------------------------------------------------------------------
; Petla glowna programu
;---------------------------------------------------------------------
main_loop:
	JNB	SEC_CHANGE, main_loop		; czekanie na ustawienie flagi zmiany sekundy
	
	CLR	SEC_CHANGE			; wyzerowanie flagi
	LCALL	clock_display			; wyswietlenie czasu
	LCALL	clock_alarm			; obsluga alarmu
	
	SJMP	main_loop

;---------------------------------------------------------------------
; Inicjowanie Timera 0 w trybie 16-bitowym z przerwaniami
;---------------------------------------------------------------------
timer_init:
	CLR	TR0				; zatrzymanie timera
	MOV 	TMOD, #00000001B		; tryb 16-bit
	MOV	TH0, #HIGH(LOAD)		; przypisanie starzych bitow wartosci timera
	MOV	TL0, #LOW(LOAD)			; przypisanie mlodzych bitow wartosci timera
	CLR 	TF0				; zerowanie flagi pzepepelnenia
	SETB	EA				; odblokowanie wsysktich przerwan
	SETB	ET0				; odblokowanie przerwan timera0
	
	SETB	TR0				; uruchomienie timera
	RET

;---------------------------------------------------------------------
; Inicjowanie zmiennych zwiazanych z czasem
;---------------------------------------------------------------------
clock_init:
	MOV	SEC, #0
	MOV	MIN, #0
	MOV	HOUR, #0
	MOV	ALARM_SEC, #1			; przyklad
	MOV	ALARM_MIN, #0
	MOV	ALARM_HOUR, #0
	RET

;---------------------------------------------------------------------
; Wyswietlanie czasu
;---------------------------------------------------------------------
clock_display:
	MOV	A, SEC
	CPL	A				; dopelnienie dla diod (0=ON)
	ANL	A, #00111111b			; zachowanie bitow sekund
	ANL	LEDS, #11000000b		; zachowanie flag na wyzszych bitach
	ORL	LEDS, A				; polaczenie sekund i flag
	RET

;---------------------------------------------------------------------
; Obsluga alarmu
;---------------------------------------------------------------------
clock_alarm:
	JNB	ALARM, ring_counter		; czy alarm musi zaraz dzwonic
 	MOV	A, SEC				; jesli nie, sprawdzamy czas alarmu
	CJNE 	A, ALARM_SEC, skip_alarm	; sprawdzenie czy sekunda jest zgodna z ustawionym alarmem
	MOV	A, MIN
	CJNE	A, ALARM_MIN, skip_alarm 	; sprawdzenie czy minuta jest zgodna z ustawionym alarmem
	MOV	A, HOUR
	CJNE 	A, ALARM_HOUR, skip_alarm	; sprawdzenie czy godzina jest zgodna z ustawionym alarmem
	CLR	ALARM				; wlaczenie flagi dzwonka alarmu
	MOV	ALARM_DURATION, #10
	JMP	skip_alarm
ring_counter:
	DEC 	ALARM_DURATION			; ile alarm musi dzwonic
	MOV	A, ALARM_DURATION		; sprawdzenie czy czas trwania alarmu wyzerowal sie
	JNZ	skip_alarm
	SETB	ALARM				; wylacz flage alarmu jesli tak
skip_alarm:
	RET

END