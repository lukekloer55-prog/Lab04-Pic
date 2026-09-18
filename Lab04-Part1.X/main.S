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
    
InputSelection:
BANKSEL PORTB				;Select the bank where PORTB is located.
MOVF PORTB,W				;MOVE PORTB values into the working register.
MOVWF ButtonState			;MOVE the portbs values that are in the working register into the ButtonState register.
BTFSC ButtonState,0			;Check Bit, if it is clear skip the next instruction.
CLRF PORTA				;Clear all bit values in PORTA, this allows the output to be held low if the button is not pressed. 
BTFSS ButtonState,0			;Check Bit 0, skip if the bit is set. 
GOTO Main				;GOTO Main if the bit is set. 	

    MOVLW 0x01				;Move the value of 5 to the working register.
    XORWF PORTA,1			;XOR the port b with the value of 5 to toggle between 5 and 0 on the display.
    MOVLW 0x01				;Load the value needed to achieve a 500ms delay in working register.
    MOVWF DelayLoopCount		;Delay overhead, load the value into the actual register for the 500ms delay.
    Call DelayLoop			;Call the 500ms delay loop, call the 500msdelayloop.
    ;If the loop finished continue the delay loop.
    GOTO Main				;Repeat the loop once the 500ms delay loop is finished.
    ;After the call start the delay.
    ;Code that deals with the whole of the inline delay starts here.
    
DelayLoop:
    MOVLW 0x9E				;Move the value needed to achieve a 500ms delay in working register.
    MOVWF InnerCount			;Load the value into the actual register for the 500ms delay.
    Call InnerDelayLoop			;Call the inner delay loop apart of the nested call requirement, will be moved ontop of the first call.
    DECFSZ DelayLoopCount		;Decrement the DelayLoop if the outer loop has finished its decrement. 
    GOTO DelayLoop			;Continue the loop and repeat all the above code if the outerloop hasn't hit 0. 
    Return				;Return to the call and execute the next instruction.
    ;Code that deals with the inner most part of the inline delay starts here.
InnerDelayLoop:
    DECFSZ InnerCount,1			;Decrement the innercount and if it is 0 skip the next instruction.
    GOTO InnerDelayLoop			;Continue the loop if the count is not 0
    Return				;Return to the innerdelay loop call and execute the next instruction.			  