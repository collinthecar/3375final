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

	org $1000
ahourten	 DS 1 ; the tens place for the alarm hour time
ahourone	 DS 1 ; the ones place for the alarm hour time
aminone		 DS 1 
aminten		 DS 1 
chourten	 DS 1; hour tens place for current time
chourone	 DS 1
cminten		 DS 1
cminone		 DS 1

	org $400
	LDS #$2000
	LDAA #%10010000
	STAA TSCR1
	LDAA #0
	STAA cminone
	STAA cminten
	STAA chourone
	STAA chourten
TOP		 JSR IncMinute
		 BRA TOP



IncMinute:
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



UpdateDisplay:
