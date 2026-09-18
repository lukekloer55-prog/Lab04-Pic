// Luke Kloer
// RCET 3373
// Lab 4 Funky Muzak
// git url is : https://github.com/lukekloer55-prog/Lab04-Pic

; CONFIG1
CONFIG  FOSC = XT             ; Oscillator Selection bits (XT oscillator: Crystal/resonator on RA6/OSC2/CLKOUT and RA7/OSC1/CLKIN)
CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
CONFIG  PWRTE = OFF           ; Power-up Timer Enable bit (PWRT disabled)
CONFIG  MCLRE = ON            ; RE3/MCLR pin function select bit (RE3/MCLR pin function is MCLR)
CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
CONFIG  LVP = OFF             ; Low Voltage Programming Enable bit (RB3 pin has digital I/O, HV on MCLR must be used for programming)

; CONFIG2
CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)

; Config statements should precede project file includes.
#include <xc.inc>
    DelayLoopCount EQU 0x20
    InnerCount EQU 0x21
    ButtonState EQU 0x22
    LookUpTableValue EQU 0x23
        
; Reset Vector at 0000h. Execution starts here after reset.
 PSECT resetVect,class=CODE,delta=2
 ResetVector:
    NOP
    NOP
    NOP
    GOTO Setup
    
; Main Code section starts at 0008h. User code goes here.
PSECT code,class=CODE,delta=2

; Add device setup here
Setup:  
    ;Setup PORTA and disable unnecessary features.
    BANKSEL ANSEL
    CLRF ANSEL				;Clear ANSEL to set all pins to digital I/O
    BANKSEL TRISA			;Move the value into the working register ready to be moved into the register.
    CLRF TRISA				;Move the value into TRISA, to enable all pins as outputs.
    BANKSEL PORTA   
    CLRF PORTA				;Clear PORTA to set the I/0 pins to read vin low.
    
    ;Setup PORTB and disable unnecessary features.
    BCF 0x03,5				;Set Bank 0
    BCF 0x03,6				;Set Bank 0
    CLRF 0x17	   			;Set all low for ccp to be disabled.
    
    BSF 0x03,5				;Set Bank 1
    BCF 0x03,6				;Set Bank 1
    MOVLW 0xFF                          ;Move the value into the working register ready to be moved into the register.
    MOVWF 0x86				;Set all HIGH for input to be enabled.
    CLRF 0x95				;Set all LOW for weak pull ups to be Disabled.
    CLRF 0x96				;Set all low for interrupt to be disabled.
    
    BCF 0x03,5				;Set Bank 2
    BSF 0x03,6				;Set Bank 2
    BSF 0x09,1				;Set Bit 1 High for original state to be enabled.
    
    BSF 0x03,5				;Set Bank 3
    BSF 0x03,6				;Set Bank 3
    CLRF 0x89				;Set all low for digital I/O Enabled.
    BSF 0x81,7				;Set Bit 7 High to disable Pull-Up.
    CLRF 0x8B				;Set all low to disable interupts.
    
    BANKSEL PORTB
    CLRF PORTB
    
GOTO Main
    
Main: 
;Main code starts here
InputSelection:
    BANKSEL PORTB		;Set bank to bank that contains PORTB Bank 0
    MOVF PORTB,0		;Move the value of PORTB into the working register.
    MOVWF ButtonState		;Move the value of the working register into the ButtonState general purpose register.
    MOVLW 0x10			;Move this value into the working register to act as a check for if no inputs were found. 
    BTFSS ButtonState,0		;Check Bit 0 state.
    MOVLW 0x00			;If bit o is cleared meaning input is true, move the value of 0x00 into the working register.
    BTFSS ButtonState,1		;Check Bit 1 state.
    MOVLW 0x01			;If bit 1 is cleared meaning input is true, move the value of 0x01 into the working register.
    BTFSS ButtonState,2		;Check Bit 2 state.
    MOVLW 0x02			;If bit 2 is cleared meaning input is true, move the value of 0x02 into the working register.
    BTFSS ButtonState,3		;Check Bit 3 state.
    MOVLW 0x03			;If bit 3 is cleared meaning input is true, move the value of 0x03 into the working register.
    BTFSS ButtonState,4		;Check Bit 4 state.
    MOVLW 0x03			;If bit 4 is cleared meaning input is true, move the value of 0x04 into the working register.
    BTFSS ButtonState,5		;Check Bit 5 state.
    MOVLW 0x05			;If bit 5 is cleared meaning input is true, move the value of 0x05 into the working register.
    BTFSS ButtonState,6		;Check Bit 6 state.
    MOVLW 0x06			;If bit 6 is cleared meaning input is true, move the value of 0x06 into the working register.
    BTFSS ButtonState,7		;Check Bit 7 state.
    MOVLW 0x07			;If bit 7 is cleared meaning input is true, move the value of 0x07 into the working register.
    MOVWF LookUpTableValue	;Move the value in the working register into the LookUpTableValue general register.
    BTFSC LookUpTableValue,4	;Check that 0 input bit that was preloaded, skip the next instruction if the bit is clear. 
    CLRF PORTA			;Clear PORTA if no inputs to hold the output low if there is no switch set. 
    BTFSC LookUpTableValue,4	;Check that 0 input bit that was preloaded, skip the next instruction if the bit is clear. 
    GOTO InputSelection		;If no inputs are clicked GOTO InputSelection and start the input pulling again. 
    Call LookUpTable		;If input is valid, call the LookUpTable
    MOVWF DelayLoopCount	;Once the LookUpTable is returned from then move the working register value into the DelayLoopCount general register. 
    
LoadDelayLoop:
    MOVLW 0x01				;Move the value of 5 to the working register.
    XORWF PORTA,1			;XOR the port b with the value of 5 to toggle between 5 and 0 on the display.
    Call DelayLoop			;Call the delay loop.
    ;If the loop finished continue the delay loop.
    GOTO Main				;Repeat the main code once the delay loop is finished.
    ;After the call start the delay.
    ;Code that deals with the whole of the inline delay starts here.
DelayLoop:
    MOVLW 0x04				;Move the value for the InnerCount into the working register.
    MOVWF InnerCount			;Move the working register value into the InnerCount general purpose register.
InnerLoop:
    DECFSZ InnerCount			;Decrement the innercount, and skip the next instruction if the count is 0.
    GOTO InnerLoop			;Repeat the loop if the inner count is not 0
    DECFSZ DelayLoopCount		;Decrement the DelayLoop if the outer loop has finished its decrement. 
    GOTO DelayLoop			;Continue the loop and repeat all the above code if the outerloop hasn't hit 0. 
    
    Return				;Return to the call and execute the next instruction.
    ;Code that deals with the inner most part of the inline delay starts here.
  
;LookUpTable code starts here.
LookUpTable:
    MOVF LookUpTableValue,0		;Move the value that is in the LookUpTableValue general register into the working register.
    ADDWF PCL,1				;Add the working register to the PCL register to cause the PCL to change its next instruction location.
    RETLW 0xEE				;Return from the call with the value in the working register, ready to be moved into the DelayLoopCount register. 
    RETLW 0xD4
    RETLW 0xBD
    RETLW 0xB2
    RETLW 0x9F
    RETLW 0x8E
    RETLW 0x7E
    RETLW 0x77