.hc12
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

;**KEYPAD**
PORTB EQU $0001
DDRB EQU $0003
PUCR EQU $000C

;***LCD**
PORTA EQU $0000
DDRA EQU $0002
PORTM EQU $250
DDRM EQU $252

	org $0800
	JSR ADDMILLIS
	pula
	pula
	pula
	pula
	pula
	pula
	pula
	CLI
	RTS
	
	
	org $1000
ahourten	 DS 1 ; the tens place for the alarm hour time
ahourone	 DS 1 ; the ones place for the alarm hour time
aminten		 DS 1 
aminone		 DS 1 
chourten	 DS 1; hour tens place for current time
chourone	 DS 1
cminten		 DS 1
cminone		 DS 1
csecond		 DS 1
millis		 DS 2
hrbuttonstate DS 2
minbuttonstate DS 2 
cancelbuttonstate DS 2
displaycora	   DS 1
timesincebtnpressed DS 2
 
 	
 	org $400
 	LDS #$4000
	;set up timer
	;CLI
 	LDAA #%10010000
 	STAA TSCR1
 	LDAA #%00000011
 	STAA TSCR2
 	LDAA #%00000010
 	STAA TIOS
 	
 	;reset current time
 	LDAA #0
 	STAA cminone
 	STAA cminten
 	STAA chourone
 	STAA chourten
	STAA csecond
	LDAA #!1
	STAA aminone
	CLRA
	STAA aminten
	STAA ahourone
	STAA ahourten
	STAA displaycora
	STAA cancelbuttonstate
	LDD #!10000
	STD timesincebtnpressed
	LDD #!0
	STD millis
	;set up display
	JSR InitLCD
	
	;**KEYPAD INIT**
	LDAA #$80
	STAA DDRB
	LDAA #$01;pullup resistor for port B
	STAA PUCR
	CLRA
	STAA hrbuttonstate
	STAA minbuttonstate
	
	LDAA #%10
	STAA TIE
	
 	LDD TSCNT
 	ADDD #!1000
 	STD TC1
TOP:	
	JSR ADDMILLIS
	BRSET PORTB,$01,DebounceMinButton
	BRSET PORTB,$02,DebounceHrButton
	BRCLR PORTB,$04,NoPress
DebounceCancelButton:
	LDD cancelbuttonstate
	ADDD #!1
	STD cancelbuttonstate
	CPD #!25000
	BNE DoneDebounce
	JSR CancelAlarm
	LDD #!0
	STD cancelbuttonstate
	STD timesincebtnpressed
	BRA NoPress
DebounceHrButton:
	LDD hrbuttonstate
	ADDD #!1
	STD hrbuttonstate
	CPD #!25000
	BNE DoneDebounce
	JSR IncAlarmHour
	BRA NoPress
DebounceMinButton:
	LDD minbuttonstate
	ADDD #!1
	STD minbuttonstate
	CPD #!25000
	BNE DoneDebounce
	JSR IncAlarmMin
NoPress:
	CLRA
	CLRB
	STD hrbuttonstate
	STD minbuttonstate
	STD cancelbuttonstate
	LDD timesincebtnpressed
	CPD #!10000
	BEQ DoneDebounce
	ADDD #!1
	STD timesincebtnpressed
DoneDebounce:
	LDD millis
	CPD #!1000
	BNE TOP	
	JSR IncSecond
	JSR UPDATECLOCK
	BRA TOP
	
	

IncSecond:
		  LDAA csecond
		  INCA
		  STAA csecond
		  CMPA #!60
		  BNE ENDSECOND
		  JSR IncMinute
ENDSECOND 
		  RTS

IncMinute:
		  LDAA #!0
		  STAA csecond;reset seconds
		  LDAA cminone
		  INCA
		  STAA cminone;increase the minute
		  CMPA #!10
		  BEQ addtotensmin;if we are at ten we need to increase the tens value
		  JSR CHECKALARM
		  RTS

addtotensmin:
	 LDAA #0
	 STAA cminone;make the ones place 0
	 LDAA cminten
	 INCA
	 STAA cminten
	 CMPA #!6
	 BEQ IncHour
	 JSR CHECKALARM
	 RTS

IncHour:
	LDAA #0
	STAA cminten;only need to reset the tens becaues tens increment routine resets the ones
	LDAA chourone
	INCA
	STAA chourone
	CMPA #!10
	BEQ addtohourtens
	LDAB chourten
	CPD #$402; if it is at 24 we need to reset
	BEQ resetDay
	JSR CHECKALARM
	RTS

addtohourtens: LDAA #!0
			   STAA chourone
			   LDAA chourten
			   INCA
			   STAA chourten
			   JSR CHECKALARM 
			   RTS

resetDay:	   LDAA #0
			   STAA chourten
			   STAA chourone
			   JSR CHECKALARM
			   RTS
			   
			   
ADDMILLIS:	  
			   LDD TSCNT
			   ADDD #!1000
			   STD TC1
			   LDD millis
			   ADDD #!1
			   STD millis
			   RTS

InitLCD:
		ldaa #$FF ; Set port A to output for now
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

SendWithDelay:  
		TSX
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
		jsr Delay1MS
		pula
		pula
		rts

Delay1MS:
		 LDD TSCNT
		 ADDD #!1000
		 STD TC1
		 BRCLR TFLG1,%0010,*
		 RTS

CHECKALARM:
	LDD cminone
	CPD aminone
	BNE NOALARM
	LDD cminten
	CPD aminten
	BNE NOALARM
	LDD chourone
	CPD ahourone
	BNE NOALARM
	LDD chourten
	CPD ahourten
	BNE NOALARM
	BSET PORTB,%10000000
NOALARM:
	RTS
	
UPDATECLOCK:
	bclr PORTM,%00000100
 	LDAA #$01
	PSHA
	LDAA #1
	PSHA
	JSR SendWithDelay
	PULA
	PULA
	bset PORTM,%00000100
	LDD timesincebtnpressed
	CPD #!10000
	BNE showalarm
	LDAA #%00110000 
	ORAA chourten
	PSHA
	LDAA #$FF
	PSHA
	jsr SendWithDelay
	LEAS 2,SP
	LDAA #%00110000 
	ORAA chourone
	PSHA
	LDAA #$FF
	PSHA
	jsr SendWithDelay
	LEAS 2,SP
	LDAA #%00111010
	PSHA
	LDAA #$FF
	PSHA
	jsr SendWithDelay
	LEAS 2,SP
	LDAA #%00110000 
	ORAA cminten
	PSHA
	LDAA #$FF
	PSHA
	jsr SendWithDelay
	LEAS 2,SP
	LDAA #%00110000 
	ORAA cminone
	PSHA
	LDAA #$FF
	PSHA
	jsr SendWithDelay
	LEAS 2,SP
	RTS	
showalarm:
	LDAA #%00110000 
	ORAA ahourten
	PSHA
	LDAA #$FF
	PSHA
	jsr SendWithDelay
	LEAS 2,SP
	LDAA #%00110000 
	ORAA ahourone
	PSHA
	LDAA #$FF
	PSHA
	jsr SendWithDelay
	LEAS 2,SP
	LDAA #%00111010
	PSHA
	LDAA #$FF
	PSHA
	jsr SendWithDelay
	LEAS 2,SP
	LDAA #%00110000 
	ORAA aminten
	PSHA
	LDAA #$FF
	PSHA
	jsr SendWithDelay
	LEAS 2,SP
	LDAA #%00110000 
	ORAA aminone
	PSHA
	LDAA #$FF
	PSHA
	jsr SendWithDelay
	LEAS 2,SP
	RTS

IncAlarmMin:
	LDD #!0
	STD minbuttonstate
	STD timesincebtnpressed
	LDAA aminone
	INCA
	STAA aminone
	CMPA #!10
	BNE DONEAMIN
	CLRA
	STAA aminone
	LDAA aminten
	INCA
	STAA aminten
	CMPA #!6
	BNE DONEAMIN
	CLRA
	STAA aminten
	JSR IncAlarmHour
DONEAMIN:
	RTS

IncAlarmHour:
			 LDD #!0
	STD hrbuttonstate
	STD timesincebtnpressed
	LDAA ahourone
	INCA
	STAA ahourone
	CMPA #!10
	BNE DONEAHOURONE
	CLRA
	STAA ahourone
	LDAA ahourten
	INCA
	STAA ahourten
DONEAHOURONE:
	LDAA ahourten
	LDAB ahourone
	CPD #$0204
	BEQ RESETADAY
	RTS
RESETADAY:
	CLRA
	CLRB
	STAA ahourten
	STAA ahourone
	RTS
	
CancelAlarm:
		   BCLR PORTB,%10000000
		   RTS 

