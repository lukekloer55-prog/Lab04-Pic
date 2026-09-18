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
    Portbsnapshot EQU 0x22
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
    MOVLW 0xFF				;Set all bits in PORTB high, to enable inputs. This is not needed as the bits will be changed later, but just in there for setup.
    MOVWF 0x06				;Move it from the work register to the actual PortB register
    CLRF 0x17				;Set all low for ccp to be disabled.
    
    BSF 0x03,5				;Set Bank 1
    BCF 0x03,6				;Set Bank 1
    MOVLW 0x0F				;Set the working register as a 0F to be moved into the TRISB to make all the top 4 bits low to enable outputs on the top 4 pins, and high on the bottom 4 bits to enable inputs on those pins.
    MOVWF 0x86				;Move all the bits into the register to enable and disable the wanted states for outputs and inputs.
    MOVLW 0x0F				;Set the pull up resistors for the outputs to enable the 5v supply to the keypad. But set the pull ups low for the inputs.
    MOVWF 0x95				;Set the pull up resistors for the outputs to enable the 5v supply to the keypad. But set the pull ups low for the inputs and move it from the working register to the WPUB.
    CLRF 0x96				;Set all low for interrupt to be disabled.
    
    BCF 0x03,5				;Set Bank 2
    BSF 0x03,6				;Set Bank 2
    BSF 0x09,1				;Set Bit 1 High for original state to be enabled.
    
    BSF 0x03,5				;Set Bank 3
    BSF 0x03,6				;Set Bank 3
    CLRF 0x89				;Set all low for digital I/O Enabled.
    BCF 0x81,7				;Set Bit 7 Low to enable Pull-Up.
    CLRF 0x8B				;Set all low to disable interupts.
GOTO Main

;LookUpTable code starts here
;LookUpTable had to be moved above main as when the higher values were called, it caused a rollover of the PCL causing the program
;to put the PCL at an instruction in setup.
LookUpTable:
    MOVF LookUpTableValue,0	    ;Move the value that is in the LookUpTableValue general register into the working register.
    ADDWF PCL,1			    ;Add the working register to the PCL register to cause the PCL to change its next instruction location.
    RETLW 0xEE			    ;Return from the call with the value in the working register, ready to be moved into the DelayLoopCount register. 
    RETLW 0xD4
    RETLW 0xBD
    RETLW 0xB2
    RETLW 0x9F
    RETLW 0x8E
    RETLW 0x7E
    RETLW 0x77
    RETLW 0x6A
    RETLW 0x5E
    RETLW 0x59
    RETLW 0x4F
    RETLW 0x47
    RETLW 0x3F
    RETLW 0x3B
    RETLW 0x35  
    
Main: 

CheckPriorityBits:
    ;This will check column4 or the msb coloumn to see if any rows are being pressed. 
    ;After this check it will move on to the next coloumn and so on, until it see's an input or finds nothing pressed. 
    BSF 0x03,5			    ;Set Bank 1
    BCF 0x03,6			    ;Set Bank 1
    MOVLW 0x80			    ;Set Column 4 to be on by switching the pull up resistor enable/disable states.
    MOVWF 0x95			    ;Move the set state into the register WPUB.
    MOVLW 0x7F			    ;Set Column 4 to be on by switching the pull up resistor enable/disable states.
    MOVWF 0x86			    ;Turn on inputs for everything but the 4th line, also move the working register data into the actual register.
    BANKSEL PORTB		    ;Select the Bank of PORTB bank0.
    MOVF PORTB,0		    ;Move PORTB values into the working register.
    MOVWF Portbsnapshot		    ;Move the working register into Portbsnapshot general purpose register.
    BTFSC Portbsnapshot,3	    ;Check if row 4 is being enabled. If it is not then skip the next instruction.
    GOTO Valued			    ;Move to the valued that will load the lookuptablevalue.
    BSF 0x03,5			    ;Set Bank 1
    BCF 0x03,6			    ;Set Bank 1
    MOVLW 0x40			    ;Set Column 3 to be on by switching the pull up resistor enable/disable states.
    MOVWF 0x95			    ;Move the set state into the register WPUB.
    MOVLW 0xBF			    ;Set Column 3 to be on by switching the pull up resistor enable/disable states.
    MOVWF 0x86			    ;Turn on inputs for everything but the 3rd line, also move the working register data into the actual register.
    BANKSEL PORTB		    ;Select the Bank of PORTB bank0.
    MOVF PORTB,0		    ;Move PORTB values into the working register.
    MOVWF Portbsnapshot		    ;Move the working register into Portbsnapshot general purpose register.
    BTFSC Portbsnapshot,3	    ;Check if row 4 is being enabled. If it is not then skip the next instruction.
    GOTO Valuehashtag		    ;Move to the Valuehashtag that will load the lookuptablevalue.
    BSF 0x03,5			    ;Set Bank 1
    BCF 0x03,6			    ;Set Bank 1
    MOVLW 0x20			    ;Set Column 2 to be on by switching the pull up resistor enable/disable states.
    MOVWF 0x95			    ;Move the set state into the register WPUB.
    MOVLW 0xDF			    ;Set Column 2 to be on by switching the pull up resistor enable/disable states.
    MOVWF 0x86			    ;Turn on inputs for everything but the 2nd line, also move the working register data into the actual register.
    BANKSEL PORTB
    MOVF PORTB,0
    MOVWF Portbsnapshot
    BTFSC Portbsnapshot,3	    ;Check if row 4 is being enabled. If it is not then skip the next instruction.
    GOTO Value0			    ;Move to the Valuehashtag that will load the lookuptablevalue.
    BSF 0x03,5			    ;Set Bank 1
    BCF 0x03,6			    ;Set Bank 1
    MOVLW 0x10			    ;Set Column 1 to be on by switching the pull up resistor enable/disable states.
    MOVWF 0x95			    ;Move the set state into the register WPUB.
    MOVLW 0xEF			    ;Set Column 1 to be on by switching the pull up resistor enable/disable states.
    MOVWF 0x86			    ;Turn on inputs for everything but the 1st line, also move the working register data into the actual register.
    BANKSEL PORTB
    MOVF PORTB,0
    MOVWF Portbsnapshot
    BTFSC Portbsnapshot,3	    ;Check if colloumn 4 is being enabled. If it is not then skip the next instruction.
    GOTO Valuestar		    ;Move to the Valuehashtag that will load the lookuptablevalue.
    BSF 0x03,5			    ;Set Bank 1
    BCF 0x03,6			    ;Set Bank 1
    MOVLW 0x80			    ;Set Column 4 to be on by switching the pull up resistor enable/disable states.
    MOVWF 0x95			    ;Move the set state into the register WPUB.
    MOVLW 0x7F			    ;Set Column 4 to be on by switching the pull up resistor enable/disable states.
    MOVWF 0x86			    ;Turn on inputs for everything but the 4th line, also move the working register data into the actual register.
    BANKSEL PORTB
    MOVF PORTB,0
    MOVWF Portbsnapshot		    ;Move the states of the inputs into a register to be checked by the bit check, helps with stability with changing inputs.
    BTFSC Portbsnapshot,3	    ;Check if row 4 is being enabled. If it is not then skip the next instruction.
    GOTO Valuec			    ;Move to the Valuehashtag that will load the lookuptablevalue.
    BSF 0x03,5			    ;Set Bank 1
    BCF 0x03,6			    ;Set Bank 1
    MOVLW 0x40			    ;Set Column 3 to be on by switching the pull up resistor enable/disable states.
    MOVWF 0x95			    ;Move the set state into the register WPUB.
    MOVLW 0xBF			    ;Set Column 3 to be on by switching the pull up resistor enable/disable states.
    MOVWF 0x86			    ;Turn on inputs for everything but the 3rd line, also move the working register data into the actual register.
    BANKSEL PORTB
    MOVF PORTB,0
    MOVWF Portbsnapshot
    BTFSC Portbsnapshot,2	    ;Check if row 3 is being enabled. If it is not then skip the next instruction.
    GOTO Value9			    ;Move to the Valuehashtag that will load the lookuptablevalue.
    BSF 0x03,5			    ;Set Bank 1
    BCF 0x03,6			    ;Set Bank 1
    MOVLW 0x20			    ;Set Column 2 to be on by switching the pull up resistor enable/disable states.
    MOVWF 0x95			    ;Move the set state into the register WPUB.
    MOVLW 0xDF			    ;Set Column 2 to be on by switching the pull up resistor enable/disable states.
    MOVWF 0x86			    ;Turn on inputs for everything but the 2nd line, also move the working register data into the actual register.
    BANKSEL PORTB
    MOVF PORTB,0
    MOVWF Portbsnapshot
    BTFSC Portbsnapshot,2	    ;Check if row 3 is being enabled. If it is not then skip the next instruction.
    GOTO Value8			    ;Move to the Valuehashtag that will load the lookuptablevalue.
     BSF 0x03,5			    ;Set Bank 1
    BCF 0x03,6			    ;Set Bank 1
    MOVLW 0x10			    ;Set Column 1 to be on by switching the pull up resistor enable/disable states.
    MOVWF 0x95			    ;Move the set state into the register WPUB.
    MOVLW 0xEF			    ;Set Column 1 to be on by switching the pull up resistor enable/disable states.
    MOVWF 0x86			    ;Turn on inputs for everything but the 1st line, also move the working register data into the actual register.
    BANKSEL PORTB
    MOVF PORTB,0
    MOVWF Portbsnapshot
    BTFSC Portbsnapshot,2	    ;Check if colloumn 3 is being enabled. If it is not then skip the next instruction.
    GOTO Value7			    ;Move to the Valuehashtag that will load the lookuptablevalue.
    BSF 0x03,5			    ;Set Bank 1
    BCF 0x03,6			    ;Set Bank 1
    MOVLW 0x80			    ;Set Column 4 to be on by switching the pull up resistor enable/disable states.
    MOVWF 0x95			    ;Move the set state into the register WPUB.
    MOVLW 0x7F			    ;Set Column 4 to be on by switching the pull up resistor enable/disable states.
    MOVWF 0x86			    ;Turn on inputs for everything but the 4th line, also move the working register data into the actual register.
    BANKSEL PORTB
    MOVF PORTB,0
    MOVWF Portbsnapshot		    ;Move the states of the inputs into a register to be checked by the bit check, helps with stability with changing inputs.
    BTFSC Portbsnapshot,1	    ;Check if row 2 is being enabled. If it is not then skip the next instruction.
    GOTO Valueb			    ;Move to the Valuehashtag that will load the lookuptablevalue.
    BSF 0x03,5			    ;Set Bank 1
    BCF 0x03,6			    ;Set Bank 1
    MOVLW 0x40			    ;Set Column 3 to be on by switching the pull up resistor enable/disable states.
    MOVWF 0x95			    ;Move the set state into the register WPUB.
    MOVLW 0xBF			    ;Set Column 3 to be on by switching the pull up resistor enable/disable states.
    MOVWF 0x86			    ;Turn on inputs for everything but the 3rd line, also move the working register data into the actual register.
    BANKSEL PORTB
    MOVF PORTB,0
    MOVWF Portbsnapshot
    BTFSC Portbsnapshot,1	    ;Check if row 2 is being enabled. If it is not then skip the next instruction.
    GOTO Value6			    ;Move to the Valuehashtag that will load the lookuptablevalue.
    BSF 0x03,5			    ;Set Bank 1
    BCF 0x03,6			    ;Set Bank 1
    MOVLW 0x20			    ;Set Column 2 to be on by switching the pull up resistor enable/disable states.
    MOVWF 0x95			    ;Move the set state into the register WPUB.
    MOVLW 0xDF			    ;Set Column 2 to be on by switching the pull up resistor enable/disable states.
    MOVWF 0x86			    ;Turn on inputs for everything but the 2nd line, also move the working register data into the actual register.
    BANKSEL PORTB
    MOVF PORTB,0
    MOVWF Portbsnapshot
    BTFSC Portbsnapshot,1	    ;Check if row 2 is being enabled. If it is not then skip the next instruction.
    GOTO Value5			    ;Move to the Valuehashtag that will load the lookuptablevalue.
    BSF 0x03,5			    ;Set Bank 1
    BCF 0x03,6			    ;Set Bank 1
    MOVLW 0x10			    ;Set Column 1 to be on by switching the pull up resistor enable/disable states.
    MOVWF 0x95			    ;Move the set state into the register WPUB.
    MOVLW 0xEF			    ;Set Column 1 to be on by switching the pull up resistor enable/disable states.
    MOVWF 0x86			    ;Turn on inputs for everything but the 1st line, also move the working register data into the actual register.
    BANKSEL PORTB
    MOVF PORTB,0
    MOVWF Portbsnapshot
    BTFSC Portbsnapshot,1	    ;Check if colloumn 2 is being enabled. If it is not then skip the next instruction.
    GOTO Value4			    ;Move to the Valuehashtag that will load the lookuptablevalue.
    BSF 0x03,5			    ;Set Bank 1
    BCF 0x03,6			    ;Set Bank 1
    MOVLW 0x80			    ;Set Column 4 to be on by switching the pull up resistor enable/disable states.
    MOVWF 0x95			    ;Move the set state into the register WPUB.
    MOVLW 0x7F			    ;Set Column 4 to be on by switching the pull up resistor enable/disable states.
    MOVWF 0x86			    ;Turn on inputs for everything but the 4th line, also move the working register data into the actual register.
    BANKSEL PORTB
    MOVF PORTB,0
    MOVWF Portbsnapshot		    ;Move the states of the inputs into a register to be checked by the bit check, helps with stability with changing inputs.
    BTFSC Portbsnapshot,0	    ;Check if row 1 is being enabled. If it is not then skip the next instruction.
    GOTO Valuea			    ;Move to the Valuehashtag that will load the lookuptablevalue.
    BSF 0x03,5			    ;Set Bank 1
    BCF 0x03,6			    ;Set Bank 1
    MOVLW 0x40	    		    ;Set Column 3 to be on by switching the pull up resistor enable/disable states.
    MOVWF 0x95			    ;Move the set state into the register WPUB.
    MOVLW 0xBF			    ;Set Column 3 to be on by switching the pull up resistor enable/disable states.
    MOVWF 0x86			    ;Turn on inputs for everything but the 3rd line, also move the working register data into the actual register.
    BANKSEL PORTB
    MOVF PORTB,0
    MOVWF Portbsnapshot
    BTFSC Portbsnapshot,0	    ;Check if row 1 is being enabled. If it is not then skip the next instruction.
    GOTO Value3			    ;Move to the Valuehashtag that will load the lookuptablevalue.
    BSF 0x03,5			    ;Set Bank 1
    BCF 0x03,6			    ;Set Bank 1
    MOVLW 0x20			    ;Set Column 2 to be on by switching the pull up resistor enable/disable states.
    MOVWF 0x95			    ;Move the set state into the register WPUB.
    MOVLW 0xDF			    ;Set Column 2 to be on by switching the pull up resistor enable/disable states.
    MOVWF 0x86			    ;Turn on inputs for everything but the 2nd line, also move the working register data into the actual register.
    BANKSEL PORTB
    MOVF PORTB,0
    MOVWF Portbsnapshot
    BTFSC Portbsnapshot,0	    ;Check if row 1 is being enabled. If it is not then skip the next instruction.
    GOTO Value2			    ;Move to the Valuehashtag that will load the lookuptablevalue.
    BSF 0x03,5			    ;Set Bank 1
    BCF 0x03,6			    ;Set Bank 1
    MOVLW 0x10			    ;Set Column 1 to be on by switching the pull up resistor enable/disable states.
    MOVWF 0x95			    ;Move the set state into the register WPUB.
    MOVLW 0xEF			    ;Set Column 1 to be on by switching the pull up resistor enable/disable states.
    MOVWF 0x86			    ;Turn on inputs for everything but the 1st line, also move the working register data into the actual register.
    BANKSEL PORTB
    MOVF PORTB,0
    MOVWF Portbsnapshot
    BTFSC Portbsnapshot,0	    ;Check if colloumn 1 is being enabled. If it is not then skip the next instruction.
    GOTO Value1			    ;Move to the Valuehashtag that will load the lookuptablevalue.
    
IfNoKeyPressed:
    CLRF PORTA			    ;If no key is pressed Clear PORTA, to keep the output low.
    GOTO Main			    ;If no key is pressed GOTO Main and do the matrix keypad scanning again.

;DelayLoop code starts here. 
LoadDelayLoop:
    MOVLW 0x01			    ;Move the value to the working register.
    XORWF PORTA,1		    ;XOR the port A with the value 1.
    Call DelayLoop		    ;Call the delay loop.
    ;If the loop finished continue the delay loop.
    GOTO Main			    ;Repeat the loop once the delay loop is finished.
    ;After the call start the delay.
    ;Code that deals with the whole of the inline delay starts here.
DelayLoop:
    MOVLW 0x04			    ;Move the value of 4 into the working register.
    MOVWF InnerCount		    ;Move the working register value into the InnerCount general purpose register.
;Code that deals with the inner most part of the inline delay starts here.
InnerLoop:
    DECFSZ InnerCount		    ;Decrement the InnerCount, if it zero it will skip the next instruction.
    GOTO InnerLoop		    ;If the count is not 0, repeat the decrement innercount loop.
    DECFSZ DelayLoopCount	    ;Decrement the DelayLoop if the outer loop has finished its decrement. 
    GOTO DelayLoop		    ;Continue the loop and repeat all the above code if the outerloop hasn't hit 0. 
    
    Return			    ;Return to the call and execute the next instruction.

;This will deal with the result of the input checking from the matrix keypad, all the comments that follow apply to all Value sections.
Valuea:				    ;Move the hex value needed to get the correct not then goto lookuptable.
    MOVLW 0x03			    ;Load the hex value into the working register.
    MOVWF LookUpTableValue	    ;Move the working register into the LookUpTableValue general purpose register.
    Call LookUpTable		    ;GOTO LookUpTable after it is done loading the character.
    MOVWF DelayLoopCount	    ;Return from the LookUpTable, and move it into the DelayLoopCount general purpose register.
    GOTO LoadDelayLoop		    ;GOTO the loaddelayloop to start the delay.
Valueb:
    MOVLW 0x07
    MOVWF LookUpTableValue
    CALL LookUpTable
    MOVWF DelayLoopCount
    GOTO LoadDelayLoop
Valuec:
    MOVLW 0x0B
    MOVWF LookUpTableValue
    CALL LookUpTable
    MOVWF DelayLoopCount
    GOTO LoadDelayLoop
Valued:
    MOVLW 0x0F
    MOVWF LookUpTableValue
    CALL LookUpTable
    MOVWF DelayLoopCount
    GOTO LoadDelayLoop
Value0:
    MOVLW 0x0D
    MOVWF LookUpTableValue
    CALL LookUpTable
    MOVWF DelayLoopCount
    GOTO LoadDelayLoop
Value1:
    MOVLW 0x00
    MOVWF LookUpTableValue
    CALL LookUpTable
    MOVWF DelayLoopCount
    GOTO LoadDelayLoop
Value2:
    MOVLW 0x01
    MOVWF LookUpTableValue
    CALL LookUpTable
    MOVWF DelayLoopCount
    GOTO LoadDelayLoop
Value3:
    MOVLW 0x02
    MOVWF LookUpTableValue
    CALL LookUpTable
    MOVWF DelayLoopCount
    GOTO LoadDelayLoop
Value4:
    MOVLW 0x04
    MOVWF LookUpTableValue
    CALL LookUpTable
    MOVWF DelayLoopCount
    GOTO LoadDelayLoop
Value5:
    MOVLW 0x05
    MOVWF LookUpTableValue
    CALL LookUpTable
    MOVWF DelayLoopCount
    GOTO LoadDelayLoop
Value6:
    MOVLW 0x06
    MOVWF LookUpTableValue
    CALL LookUpTable
    MOVWF DelayLoopCount
    GOTO LoadDelayLoop
Value7:
    MOVLW 0x08
    MOVWF LookUpTableValue
    CALL LookUpTable
    MOVWF DelayLoopCount
    GOTO LoadDelayLoop
Value8:
    MOVLW 0x09
    MOVWF LookUpTableValue
    CALL LookUpTable
    MOVWF DelayLoopCount
    GOTO LoadDelayLoop
Value9:
    MOVLW 0x0A
    MOVWF LookUpTableValue
    CALL LookUpTable
    MOVWF DelayLoopCount
    GOTO LoadDelayLoop
Valuehashtag:
    MOVLW 0x0E
    MOVWF LookUpTableValue
    CALL LookUpTable
    MOVWF DelayLoopCount
    GOTO LoadDelayLoop
Valuestar:
    MOVLW 0x0C
    MOVWF LookUpTableValue
    CALL LookUpTable
    MOVWF DelayLoopCount
    GOTO LoadDelayLoop
    
    GOTO Main