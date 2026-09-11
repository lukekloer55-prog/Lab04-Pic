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
    FiveHundredmsLoopCount EQU 0x20
    OuterCount EQU 0x21
    InnerCount EQU 0x22
        
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
    ;Setup Port B and disable unnecessary features.
    BCF 0x03,5				;Set Bank 0
    BCF 0x03,6				;Set Bank 0
    CLRF 0x17	   			;Set all low for ccp to be disabled.
    
    BSF 0x03,5				;Set Bank 1
    BCF 0x03,6				;Set Bank 1
    CLRF 0x86				;Set all low for output to be enabled.
    MOVLW 0xFF				;Move the value into the working register ready to be moved into the register.
    MOVWF 0x95				;Set all High for weak pull ups to be Enabled.
    CLRF 0x96				;Set all low for interrupt to be disabled.
    
    BCF 0x03,5				;Set Bank 2
    BSF 0x03,6				;Set Bank 2
    BSF 0x09,1				;Set Bit 1 High for original state to be enabled.
    
    BSF 0x03,5				;Set Bank 3
    BSF 0x03,6				;Set Bank 3
    CLRF 0x89				;Set all low for digital I/O Enabled.
    BSF 0x81,7				;Set Bit 7 High to disable Pull-Up.
    CLRF 0x8B				;Set all low to disable interupts.
    
    BCF 0x03,5				;Set Bank 0 to get to PORTB.
    BCF 0x03,6				;Set Bank 0 to get to PORTB.
    MOVLW 0xB5				;Move the PORTB valie into the working register.
    MOVWF PORTB				;Move the working register into the PORTB register to output the 5 onto the display
    
GOTO Main
    
Main:
    MOVLW 0x05				;1 TCY code not part of delay, Also move the value of 5 to the working register.
    XORWF PORTB,1			;1 TCY code not part of delay, XOR the port b with the value of 5 to toggle between 5 and 0 on the display.
    MOVLW 0x11				;1 TCY delay overhead, load the value needed to achieve a 500ms delay in working register.
    MOVWF FiveHundredmsLoopCount        ;1 TCY delay overhead, load the value into the actual register for the 500ms delay.
    Call FiveHundredmsDelayLoop		;2 TCY, Call the 500ms delay loop, call the 500msdelayloop.
    ;If the loop finished continue the delay loop.
    GOTO Main				;2 TCY, Repeat the loop once the 500ms delay loop is finished.
    ;After the call start the 500ms delay.
    ;Code that deals with the whole of the inline delay starts here.
FiveHundredmsDelayLoop:
    MOVLW 0xAA				;1 TCY delay overhead, move the value needed to achieve a 500ms delay in working register.
    MOVWF OuterCount			;1 TCY delay overhead, load the value into the actual register for the 500ms delay.
    ;Code that deals with the 2nd part of the inline delay starts here.
OuterDelayLoop:
    MOVLW 0x37				;1 TCY delay overhead, move the value needed to achieve a 500ms delay in working register.
    MOVWF InnerCount			;1 TCY delay overhead, load the value into the actual register for the 500ms delay.
    Call InnerDelayLoop			;2 TCY Call the inner delay loop apart of the nested call requirement, will be moved ontop of the first call.
    DECFSZ OuterCount			;1(2) TCy, decrement the outercount and if it is 0 skip the next instruction.
    GOTO OuterDelayLoop			;2 TCY, continue the loop if the count is not 0.
    DECFSZ FiveHundredmsLoopCount	;1(2) TCY, decrement the FiveHundredmsLoopCount if the outer loop has finished its decrement. 
    GOTO FiveHundredmsLoopCount		;2 TCY, continue the loop and repeat all the above code if the outerloop hasn't hit 0. 
    Return				;2 TCY , Return to the call and execute the next instruction.
    ;Code that deals with the inner most part of the inline delay starts here.
InnerDelayLoop:
    DECFSZ InnerCount,1			;1(2) TCY, Decrement the innercount and if it is 0 skip the next instruction.
    GOTO InnerDelayLoop			;2 TCY, continue the loop if the count is not 0
    Return				;2 TCY, Return to the innerdelay loop call and execute the next instruction.			  