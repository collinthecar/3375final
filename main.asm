;**** Timer **** 
TSCR1 EQU $46
TSCR2 EQU $4D
TIOS  EQU $40
TCTL1 EQU $48
TCTL2 EQU $49
TFLG1 EQU $4E
TIE   EQU $4C
TSCNT EQU $44
TC4	  EQU $58
TC1	  EQU $52
;***************

;***LCD**
PORTA EQU $0000
DDRA EQU $0002
PORTM EQU $250
DDRM EQU $252

	org $FFEC
		FDB addMillis
	
	org $1000
ahourten	 DS 1 ; the tens place for the alarm hour time
ahourone	 DS 1 ; the ones place for the alarm hour time
aminone		 DS 1 
aminten		 DS 1 
chourten	 DS 1; hour tens place for current time
chourone	 DS 1
cminten		 DS 1
cminone		 DS 1
csecond		 DS 1
millis		 DS 2

 
 	
 	org $400
 	LDS #$2000
	;set up timer
 	LDAA #%10010000
 	STAA TSCR1
 	LDAA #%0011
 	STAA TSCR2
 	LDAA #%0010
 	STAA TIOS
 	
 	;reset current time
 	LDAA #0
 	STAA cminone
 	STAA cminten
 	STAA chourone
 	STAA chourten
	STAA csecond
	LDD #!0
	STD millis
 	
	;set up display
	LDD #%110000;function set
	LDD #%1100;on/off ctrl
	LDD #%110; entry mode set
	CLI
 	LDD TSCNT
 	ADDD #!1000
 	STD TC1
	LDAA #%10
	STAA TIE
TOP	LDD millis
	CPD #!1000
	BNE TOP	
	JSR IncSecond
	BRA TOP

IncSecond:
		  LDAA csecond
		  INCA
		  STAA csecond
		  CMPA #!60
		  BNE ENDSECOND
		  JSR IncMinute
ENDSECOND RTS

IncMinute:
		  LDAA #!0
		  STAA csecond;reset seconds
		  LDAA cminone
		  INCA
		  STAA cminone;increase the minute
		  CMPA #!10
		  BEQ addtotensmin;if we are at ten we need to increase the tens value
		  RTS

addtotensmin:
	 LDAA #0
	 STAA cminone;make the ones place 0
	 LDAA cminten
	 INCA
	 STAA cminten
	 CMPA #!6
	 BEQ IncHour
	 RTS

IncHour:
	LDAA #0
	STAA cminten;only need to reset the tens becaues tens increment routine resets the ones
	LDAA chourone
	INCA
	STAA chourone
	CMPA #!10
	LDAB chourten
	CPD #$402; if it is at 24 we need to reset
	BEQ resetDay
	BEQ addtohourtens
	RTS

addtohourtens: LDAA #!0
			   STAA chourone
			   LDAA chourten
			   INCA
			   STAA chourten
			   RTS

resetDay:	   LDAA #0
			   STAA chourten
			   STAA chourone
			   RTS
			   
			   
ADDMILLIS:	  
			   CLI
			   LDD TSCNT
			   ADDD #!1000
			   STD TC1
			   LDD millis
			   ADDD #!1
			   STD millis
			   SEI
			   RTI

InitLCD:ldaa #$FF ; Set port A to output for now
		staa DDRA
        ldaa #$1C ; Set port M bits 4,3,2
		staa DDRM


		LDAA #$30	; We need to send this command a bunch of times
		psha
		LDAA #5
		psha
		jsr SendWithDelay
		pula

		ldaa #1
		psha
		jsr SendWithDelay
		jsr SendWithDelay
		jsr SendWithDelay
		pula
		pula

		ldaa #$08
		psha
		ldaa #1
		psha
		jsr SendWithDelay
		pula
		pula

		ldaa #1
		psha
		psha
		jsr SendWithDelay
		pula
		pula

		ldaa #6
		psha
		ldaa #1
		psha
		jsr SendWithDelay
		pula
		pula

		ldaa #$0E
		psha
		ldaa #1
		psha
		jsr SendWithDelay
		pula
		pula

		rts

SendWithDelay:  TSX
		LDAA 3,x
		STAA PORTA

		bset PORTM,$10	 ; Turn on bit 4
		jsr Delay1MS
		bclr PORTM,$10	 ; Turn off bit 4

		tsx
		ldaa 2,x
		psha
		clra
		psha
		jsr Delay
		pula
		pula
		rts

Delay1MS:
RTS