;-----------------------------
; Title: Temperature Control Systen
;-----------------------------
; Purpose: Turns on heating or cooling systems based on desired temperature 
; Dependencies: None
; Compiler: MPLAB X IDE v6.20
; Author: Tyler Walters
; OUTPUTS: Outputs Connected to heating and cooling systems
; INPUTS: Connected to keypad and temperature sensor 
; Versions:
;  	V1.0: 3/2/2024 -First Version
;-----------------------------
#include <xc.inc>
;----------------
; PROGRAM INPUTS
;----------------
MEASURED_TEMP	EQU 0X0 ; Mesured value from temperature sensor
REFERENCE_TEMP	EQU 0XF ; input value from the keypad
DENOMINATOR EQU	0XA
COUNTER	EQU 0X31
;----------------
; REGISTERS
;----------------
MEASURED_TEMP_REG   EQU	0X21 ; MEASURE TEMP STORAGE
REFERENCE_TEMP_REG  EQU	0X20 ; REFEREMCE TEMP STORAGE
CONT_REG    EQU	0X22 ; CONTROL REGISTER LOCATION
NUMERATOR   EQU	0X30
SIGN_FLAG   EQU	0X31
MEAS_DEC_H  EQU	0x72 ; REG FOR MEASURED TEMP CONVERTED TO DECIMAL
MEAS_DEC_M  EQU	0X71
MEAS_DEC_L  EQU	0X70
REF_DEC_H   EQU	0X62 ; REGISTERS FOR REF TEMP IN DECIMAL
REF_DEC_M   EQU	0X61
REF_DEC_L   EQU	0X60
;----------------
; PROGRAM OUTPUTS
;----------------
CONT_REG_NOTHING    EQU	0X00	;CONTROL REGISTER SETTINGS
CONT_REG_COOL	EQU 0X02
CONT_REG_HEAT	EQU 0X01
#define	HEATER	PORTD,2
#define	COOLER	PORTD,1
	
PSECT absdata,abs,ovrld

	GOTO START
	org	0x20
;MAIN PROGRAM
	
START:
    MOVLW   0X00
    MOVWF   TRISD,0		;set portd as output
    MOVLW   MEASURED_TEMP   
    MOVWF   MEASURED_TEMP_REG	
    BTFSC   MEASURED_TEMP_REG,7	;Check if measured temp is positive
    GOTO    _HEAT		;If negative we already know we need to heat
    MOVLW   REFERENCE_TEMP
    MOVWF   REFERENCE_TEMP_REG
    CPFSGT  MEASURED_TEMP_REG	;If measured>ref skip next command and go to cool
    BRA	_LEQ			;If not check for less than or equal too
    GOTO    _COOL
_LEQ:
    CPFSLT  MEASURED_TEMP_REG	;IF NOT LESS THAN IT MUST BE EQUAL
    BRA _EQ			
    GOTO    _HEAT		;IF MEAS<REF TURN ON HEATER
_EQ:
    GOTO    _NOTHING		; DO NOTHING IF TEMPS ARE EQUAL

_NOTHING:
	MOVLW   CONT_REG_NOTHING    ;TURN OFF HEAT AND COLD
	MOVWF   CONT_REG
	MOVFF	CONT_REG, PORTD
	GOTO	_CONVERT
_COOL:
	MOVLW   CONT_REG_COOL	    ;TURN ON COOLING SYSTEM AND HEATER OFF
	MOVWF   CONT_REG
	MOVFF	CONT_REG, PORTD
	GOTO	_CONVERT
_HEAT:
	MOVLW	CONT_REG_HEAT	    ;TURN ON HEAT AND COOLING OFF
	MOVWF	CONT_REG
	MOVFF	CONT_REG, PORTD
	GOTO	_CONVERT
_CONVERT:
    MOVLW   MEASURED_TEMP	
    MOVWF   NUMERATOR
    CLRF    SIGN_FLAG
    BTFSS   NUMERATOR, 7	;CHECK FOR NEGATIVE
    GOTO    _POSITIVE		; IF POSITIVE SKIP NEXT SECTION
    COMF    NUMERATOR, F	;IF NEGATIVE PERFORM 2'S COMPLEMENT 
    INCF    NUMERATOR, F
    
_POSITIVE:   
    MOVLW   DENOMINATOR
    CLRF    COUNTER
_D1MEAS:	
    INCF    COUNTER,F	    ;CONTINOUSLY SUB 10, USE COUNTER TO FIND HOW MANY
    SUBWF   NUMERATOR,F	    
    BC	_D1MEAS		    ;KEEP GOING TILL BELOW ZERO
    ADDWF   NUMERATOR,F	    ;ADD 10 BACK TO FIND REMAINDER
    DECF    COUNTER,F	    ;COUNTER WAS ONE TO FAR ADD IT BACK
    MOVFF   NUMERATOR, MEAS_DEC_L   ;STORE REMAINDER IN LSB
    MOVFF   COUNTER, NUMERATOR	    ;REPEAT PROCESS WITH VALUE IN COUNTER
    CLRF    COUNTER
_D2MEAS:	
    INCF    COUNTER,F		    ;SAME PROCESS TO GET NEXT DIGITS
    SUBWF   NUMERATOR,F
    BC	_D2MEAS
    ADDWF   NUMERATOR,F
    DECF    COUNTER,F
    MOVFF   NUMERATOR, MEAS_DEC_M
    MOVFF   COUNTER, MEAS_DEC_H
    
    MOVLW   REFERENCE_TEMP
    MOVWF   NUMERATOR
    MOVLW   DENOMINATOR
    CLRF    COUNTER
_D1REF:	
    INCF    COUNTER,F	    ;SAME ALGORITHM BUT RUN ON REF TEMP
    SUBWF   NUMERATOR,F
    BC	_D1REF
    ADDWF   NUMERATOR,F
    DECF    COUNTER,F
    MOVFF   NUMERATOR, REF_DEC_L
    MOVFF   COUNTER, NUMERATOR
    CLRF    COUNTER
_D2REF:	INCF    COUNTER,F
    SUBWF   NUMERATOR,F
    BC	_D2REF
    ADDWF   NUMERATOR,F
    DECF    COUNTER,F
    MOVFF   NUMERATOR, REF_DEC_M
    MOVFF   COUNTER, REF_DEC_H
    END