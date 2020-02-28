;====================================================================================================
;
;    Filename:      DCC_Booster.asm
;    Date:          1/12/2020
;    File Version:  1.0d1
;
;    Author:        David M. Flynn
;    Company:       Oxford V.U.E., Inc.
;    E-Mail:        dflynn@oxfordvue.com
;    Web Site:      http://www.oxfordvue.com/
;
;====================================================================================================
;    DCC_Booster is the control and circuit breaker for a model railroar DCC booster.
;    Features and configurations will be added as needed.
;
;    Features: 	Current sensing.
;	
;
;    History:
; 1.0d1   1/12/2020	First code.
;
;====================================================================================================
; ToDo:
;
;
;====================================================================================================
;====================================================================================================
; What happens next:
;   At power up the system LED will blink.
;   Read current select switches, Norm/Rev switch, Test Switch and set mode/control bits.
;     Set direction bit.
;   DCC Signal valid? Set/Clear LED and Driver enable.
;   Monitor current and signal valid.
;     If over current or invalid signal disable driver, Error rate sys LED, clear dvr/sig LEDs.
;====================================================================================================
;
;   Pin 1 (RA2/AN2) SW5 (Active Low Input)
;   Pin 2 (RA3/AN3) DCC Polarity (Output)
;   Pin 3 (RA4/AN4) DCC Signal OK LED (Active High Output)
;   Pin 4 (RA5/MCLR*) VPP/MCLR*
;   Pin 5 (GND) Ground
;   Pin 6 (RB0) Current Select 0 (Active Low Input)
;   Pin 7 (RB1/AN11/SDA1) Current Select 1 (Active Low Input)
;   Pin 8 (RB2/AN10/TX) Current Select 2 (Active Low Input)
;   Pin 9 (RB3/CCP1) DCC Signal (Active High Input)
;
;   Pin 10 (RB4/AN8/SLC1) Normal/Reverse* (Active Low Input)
;   Pin 11 (RB5/AN7) Driver Status LED (Active High Output)
;   Pin 12 (RB6/AN5/CCP2) ICSPCLK
;   Pin 13 (RB7/AN6) ICSPDAT
;   Pin 14 (Vcc) +5 volts
;   Pin 15 (RA6) MOSFET Driver Enable (Active High Output)
;   Pin 16 (RA7/CCP2) System LED (Active Low Output)(System LED)
;   Pin 17 (RA0/AN0) Input voltage sensing analog input
;   Pin 18 (RA1/AN1) Current sensing analog input
;
;====================================================================================================
;
;
	list	p=16f1847,r=hex,W=1	; list directive to define processor
	nolist
	include	p16f1847.inc	; processor specific variable definitions
	list
;
	__CONFIG _CONFIG1,_FOSC_INTOSC & _WDTE_OFF & _MCLRE_OFF & _IESO_OFF
;
;
; INTOSC oscillator: I/O function on CLKIN pin
; WDT disabled
; PWRT disabled
; MCLR/VPP pin function is digital input
; Program memory code protection is disabled
; Data memory code protection is disabled
; Brown-out Reset enabled
; CLKOUT function is disabled. I/O or oscillator function on the CLKOUT pin
; Internal/External Switchover mode is disabled
; Fail-Safe Clock Monitor is enabled
;
	__CONFIG _CONFIG2,_WRT_OFF & _PLLEN_ON & _LVP_OFF
;
; Write protection off
; 4x PLL Enabled
; Stack Overflow or Underflow will cause a Reset
; Brown-out Reset Voltage (Vbor), low trip point selected.
; Low-voltage programming enabled
;
; '__CONFIG' directive is used to embed configuration data within .asm file.
; The lables following the directive are located in the respective .inc file.
; See respective data sheet for additional information on configuration word.
;
	constant	oldCode=0
	constant	useRS232=0
	constant	UseEEParams=0
;
;
#Define	_C	STATUS,C
#Define	_Z	STATUS,Z
;
;====================================================================================================
	nolist
	include	F1847_Macros.inc
	list
;
;    Port A bits
PortADDRBits	EQU	b'10100111'
PortAValue	EQU	b'00000000'
ANSELA_Val	EQU	b'00000011'	;RA0/AN0, RA4/AN4
;
#Define	RA0_In	PORTA,0	;Volts, Analog Input
#Define	RA1_In	PORTA,1	;Current, Analog Input
#Define	SW5_In	PORTA,2	;SW5 Test Mode
#Define	DCC_Pole	LATA,3	;DCC Polarity (Output)
#Define	SigOK_LED	LATA,4	;DCC Signal OK LED (Active High Output)
#Define	RA5_In	PORTA,5	;VPP/MCLR*
#Define	Drv_Enable	LATA,6	;MOSFET Driver Enable (Active High Output)
#Define	RA7_In	PORTA,7	;System LED (Active Low Output)(System LED)
SysLED_Bit	EQU	7	;System LED (Active Low Output)
#Define	SysLED_Tris	TRISA,SysLED_Bit	;System LED (Active Low Output)
;
Servo_AddrDataMask	EQU	0xF8
;
;
;    Port B bits
PortBDDRBits	EQU	b'11011111'
PortBValue	EQU	b'00010001'
ANSELB_Val	EQU	b'00000000'	;RB5/AN7
;
#Define	SW1_In	PORTB,0	;Current Select 0 (Active Low Input)
#Define	SW2_In	PORTB,1	;Current Select 1 (Active Low Input)
#Define	SW3_In	PORTB,2	;Current Select 2 (Active Low Input)
#Define	RB3_In	PORTB,3	;CCP1 Input, DCC Signal (Active High Input)
#Define	SW4_In	PORTB,4	;Normal/Reverse* (Active Low Input)
#Define	Drv_StatusLED	LATB,5	;Driver Status LED (Active High Output)
#Define	RB6_In	PORTB,6	;ICSPCLK
#Define	RB7_In	PORTB,7	;ICSPDAT
;
;
;========================================================================================
;========================================================================================
;
;Constants
All_In	EQU	0xFF
All_Out	EQU	0x00
;
;OSCCON_Value	EQU	b'01110010'	; 8 MHz
OSCCON_Value	EQU	b'11110000'	;32MHz
;
;T2CON_Value	EQU	b'01001110'	;T2 On, /16 pre, /10 post
T2CON_Value	EQU	b'01001111'	;T2 On, /64 pre, /10 post
PR2_Value	EQU	.125
;
LEDTIME	EQU	d'100'	;1.00 seconds
LEDErrorTime	EQU	d'10'
LEDFastTime	EQU	d'20'
;
;T1CON_Val	EQU	b'00000001'	;Fosc=8MHz, PreScale=1,Fosc/4,Timer ON
T1CON_Val	EQU	b'00100001'	;Fosc=32MHz, PreScale=4,Fosc/4,Timer ON
;
;
;
;================================================================================================
;***** VARIABLE DEFINITIONS
; there is 1K bytes of ram, Bank0 0x20..0x7F, Bank1 0xA0..0xEF .. Bank11 0x620..0x66F
; there are 256 bytes of EEPROM starting at 0x00 the EEPROM is not mapped into memory but
;  accessed through the EEADR and EEDATA registers
;================================================================================================
;  Bank0 Ram 020h-06Fh 80 Bytes
;
	cblock	0x20
;
	SysLED_Time		;sys LED time
	SysLED_Blinks		;0=1 flash,1,2,3
	SysLED_BlinkCount
	SysLEDCount		;sys LED Timer tick count
;
	EEAddrTemp		;EEProm address to read or write
	EEDataTemp		;Data to be writen to EEProm
;
	Timer1Lo		;1st 16 bit timer
	Timer1Hi		; 50 mS RX timeiout
	Timer2Lo		;2nd 16 bit timer
	Timer2Hi		; OverCurrentHold
	Timer3Lo		;3rd 16 bit timer
	Timer3Hi		; GP wait timer
	Timer4Lo		;4th 16 bit timer
	Timer4Hi		; debounce timer
;
	SysFlags
	StatusFlags
	StatusFlags2		
;
	endc
;--------------------------------------------------------------
;
#Define	SW1_Flag	SysFlags,0             ;Current Select 0 (Active Low Input)
#Define	SW2_Flag	SysFlags,1             ;Current Select 1 (Active Low Input)
#Define	SW3_Flag	SysFlags,2             ;Current Select 2 (Active Low Input)
#Define	SW4_Flag	SysFlags,3             ;Normal/Reverse* (Active Low Input)
#Define                SW5_Flag               SysFlags,4             ;SW5 Test Mode
;
#Define                DCC_ErrorFlag          StatusFlags,0
#Define                DCC_Sig1_Flag          StatusFlags,1          ;Set by DCC signal transition, Cleared by 0.01 Sec timer
#Define                DCC_Sig2_Flag          StatusFlags,2          ;Set by DCC signal transition, Cleared by 0.01 Sec timer
#Define                DCC_Sig_Lvl            StatusFlags,3          ;old signal level
#Define                DCC_Sig_Active         StatusFlags,4          ;We have a DCC signal
#Define                InVoltsOK              StatusFlags,5          ;Set when input volts are >= 13V
;
#Define                OutCurrentOK           StatusFlags2,0          ;Set when output current is OK
#Define                OverCurrentHold        StatusFlags2,1
;
;================================================================================================
;  Bank1 Ram 0A0h-0EFh 80 Bytes
	cblock	0x0A0
;
	ANFlags
	Cur_AN0:2		;IServo
	Cur_AN1:2		;Battery Volts
	MaxCurrent:2                                  ;Set from SW1..SW3 values
;
	endc
;
#Define	InputVolts	Cur_AN0
#Define	OuputCurrent	Cur_AN1
;
;---ANFlags bits---
#Define	NewDataAN0	ANFlags,0
#Define	NewDataAN1	ANFlags,1
;
MinInVolts             EQU                    .640                   ;3.1V * 4.19v/v = 13v
;
;================================================================================================
;  Bank2 Ram 120h-16Fh 80 Bytes
;
;
;================================================================================================
;  Bank3 Ram 1A0h-1EFh 80 Bytes
;=========================================================================================
;  Bank5 Ram 2A0h-2EFh 80 Bytes
;
	cblock	0x2A0
	SigOutTime
	SigOutTimeH
	CalcdDwell
	CalcdDwellH
	endc
;
;=======================================================================================================
;  Common Ram 70-7F same for all banks
;      except for ISR_W_Temp these are used for paramiter passing and temp vars
;=======================================================================================================
;
	cblock	0x70
	Param70
	Param71
	Param72
	Param73
	Param74
	Param75
	Param76
	Param77
	Param78
	Param79
	Param7A
	Param7B
	Param7C
	Param7D
	Param7E
	Param7F
	endc
;
;=========================================================================================
;Conditions
HasISR	EQU	0x80	;used to enable interupts 0x80=true 0x00=false
;
;=========================================================================================
;==============================================================================================
; ID Locations
	__idlocs	0x10d1
;
;==============================================================================================
; EEPROM locations (NV-RAM) 0x00..0x7F (offsets)
;
;
;==============================================================================================
;============================================================================================
;
;
	ORG	0x000	; processor reset vector
ProgStartVector	CLRF	PCLATH
                       CLRF	BSR	; bank0
  	goto	start	; go to beginning of program
;
;===============================================================================================
; Interupt Service Routine
;
; we loop through the interupt service routing every 0.01 seconds
;
;
	ORG	0x004	; interrupt vector location
	CLRF	PCLATH
	CLRF	BSR	; bank0
;
;
	BTFSS	PIR1,TMR2IF
	goto	SystemTick_end
;
	BCF	PIR1,TMR2IF	; reset interupt flag bit
;------------------
; These routines run 100 times per second
;
;------------------
;Decrement timers until they are zero
;
	call	DecTimer1	;if timer 1 is not zero decrement
	call	DecTimer2
	call	DecTimer3
	call	DecTimer4
;
;-----------------------------------------------------------------
; blink LEDs
;
; All LEDs off
	movlb	0x01	;bank 1
	bsf	SysLED_Tris
;
;
	movlb	0x00	;bank 0
;--------------------
; Sys LED time
	DECFSZ	SysLEDCount,F	;Is it time?
	bra	SystemBlink_end	; No, not yet
;
	movf	SysLED_Blinks,F
	SKPNZ		;Standard Blinking?
	bra	SystemBlink_Std	; Yes
;
; custom blinking
;
SystemBlink_Std	CLRF	SysLED_BlinkCount
	MOVF	SysLED_Time,W
SystemBlink_DoIt	MOVWF	SysLEDCount
	movlb	0x01	;bank 1
	bcf	SysLED_Tris	;LED ON
SystemBlink_end:
;--------------------
; DCC Signal sensing
                       movlb                  0                      ;bank 0
                       btfss                  DCC_Sig1_Flag
                       bcf                    DCC_Sig2_Flag
                       bcf                    DCC_Sig1_Flag
; only change once per 0.01 sec
                       btfss                  DCC_Sig2_Flag
                       bcf                    DCC_Sig_Active
                       btfsc                  DCC_Sig2_Flag
                       bsf                    DCC_Sig_Active
; set/clr DCC Sig OK LED
                       clrw
                       btfsc                  DCC_Sig_Active
                       bsf                    WREG,0
                       movlb                  2                      ;bank 2
                       btfss                  WREG,0
                       bcf                    SigOK_LED
                       btfsc                  WREG,0
                       bsf                    SigOK_LED
                       movlb                  0                      ;bank 0
;
SystemTick_end:
;
;==================================================================================
;
; Handle CCP1 Interupt Flag, Enter w/ bank 0 selected
;
IRQ_DCCSig	MOVLB	0	;bank 0
	BTFSS	PIR1,CCP1IF
	bra	IRQ_DCCSig_End
;
;
IRQ_DCCSig_Done	MOVLB	0x00
	BCF	PIR1,CCP1IF
IRQ_DCCSig_End:
;-----------------------------------------------------------------------------------------
	retfie		; return from interrupt
;
;
;=========================================================================================
;*****************************************************************************************
;=========================================================================================
;
	include <F1847_Common.inc>
;
;=========================================================================================
;
start	call	InitializeIO
;
	CALL	ReadAN0_ColdStart
;
;=========================================================================================
;*****************************************************************************************
;=========================================================================================
MainLoop	CLRWDT
;
;Look for DCC signal
                       movlb                  0                      ;bank 0
                       btfss                  RB3_In                 ;High?
                       bra                    DCCSigTest_Low         ; No
; it's high
                       btfss                  DCC_Sig_Lvl            ;Was low last?
                       bra                    DCCSigTest_End         ; No
                       bsf                    DCC_Sig_Lvl            ;Remember it as high
;
DCCSigChanged          btfsc                  DCC_Sig1_Flag
                       bsf                    DCC_Sig2_Flag
                       bsf                    DCC_Sig1_Flag
                       bra                    DCCSigTest_End
; it's low
DCCSigTest_Low         btfsc                  DCC_Sig_Lvl            ;Was high last?
                       bra                    DCCSigTest_End         ; No
                       bcf                    DCC_Sig_Lvl            ;Remember it as low
                       bra                    DCCSigChanged
DCCSigTest_End:
;
; Test for input volts too low
                       movlb                  1                      ;bank 1
                       movlw                  MinInVolts
                       subwf                  InputVolts,W
                       movlb                  0                      ;bank 0
                       SKPB                                          ;MinInVolts>InputVolts?
                       bsf                    InVoltsOK              ; No
                       SKPNB                                         ;MinInVolts<=InputVolts?
                       bcf                    InVoltsOK              ; No
;
; Set / clear error condition
                       bcf                    DCC_ErrorFlag
                       btfss                  InVoltsOK              ;Input volts OK?
                       bsf                    DCC_ErrorFlag          ; No
                       btfss                  DCC_Sig_Active         ;DCC Signal is active?
                       bsf                    DCC_ErrorFlag          ; No
;
; Fast blink the system LED if the output is disabled because of an error
	MOVLB	0x00
	MOVLW	LEDTIME
	btfsc	DCC_ErrorFlag
	movlw	LEDErrorTime
	MOVWF	SysLED_Time
;
	CALL	ReadAN
;
;
	goto	MainLoop
;=========================================================================================
;*****************************************************************************************
;=========================================================================================
;
;=========================================================================================
; Setup or Read AN0 or Read AN4
ANNumMask	EQU	0x7C
AN0_Val	EQU	0x00
AN1_Val	EQU	0x04
AN2_Val	EQU	0x08
AN3_Val	EQU	0x0C
;AN4_Val	EQU	0x10
;AN7_Val	EQU	0x1C
;
ReadAN	MOVLB	1	;bank 1
	BTFSS	ADCON0,ADON	;Is the Analog input ON?
	BRA	ReadAN0_ColdStart	; No, go start it
;
	BTFSC	ADCON0,GO_NOT_DONE	;Conversion done?
	BRA	ReadAN_Rtn	; No
;
	movlw	HIGH Cur_AN0
	movwf	FSR0H
	movf	ADCON0,W
	movlb	0x00	;bank 0
	andlw	ANNumMask
	SKPNZ
	bra	ReadAN_AN0
;
	movwf	Param78	;AN select bits
;IServo
ReadAN_TryAN0	movlw	AN0_Val
	subwf	Param78,W
	SKPNZ
	bra	ReadAN_AN0
;
	movlw	AN0_Val	;next to read
	movwf	Param78
	movlw	LOW Cur_AN0
	movwf	FSR0L
	BankSel	Cur_AN0	;where the analog stuff is
	bsf	NewDataAN0
	bra	ReadAN_1
;
ReadAN_AN0	movlw	low Cur_AN0
	movwf	FSR0L
	BankSel	Cur_AN0	;where the analog stuff is
	bsf	NewDataAN0
	movlw	AN1_Val	;next to read
	movwf	Param78
	bra	ReadAN_1
;
ReadAN_AN0_1	movlw	AN2_Val	;next to read
	movwf	Param78
	bra	ReadAN_1
;
ReadAN_AN0_2	movlw	AN3_Val	;next to read
	movwf	Param78
	bra	ReadAN_1
;
ReadAN_AN0_3	movlw	AN0_Val	;next to read
	movwf	Param78
	bra	ReadAN_1
;
ReadAN_AN1	movlw	low Cur_AN1
	movwf	FSR0L
	bra	ReadAN_AN0_1
;
;
ReadAN_1	movlb	0x01	;bank 1
	MOVF	ADRESL,W
	MOVWI	FSR0++
	MOVF	ADRESH,W
	MOVWI	FSR0++
;
	movf	Param78,W
	BSF	WREG,0	;ADC ON
	MOVWF	ADCON0
	movlw	0x04	;Acquisition time 5uS
	call	DelayWuS
	BSF	ADCON0,ADGO	;Start next conversion.
	movlb	0x00	; bank 0
	return
;
ReadAN0_ColdStart	MOVLB	1
	MOVLW	b'11100000'	;Right Just, fosc/64
;	MOVLW	b'11110000'	;Right Just, Frc
	MOVWF	ADCON1
	MOVLW	AN0_Val	;Select AN0
	BSF	WREG,0	;ADC ON
	MOVWF	ADCON0
	movlw	0x04	;Acquisition time 5uS
	call	DelayWuS
ReadAN_3	BSF	ADCON0,GO
ReadAN_Rtn:
Bank0_Rtn	MOVLB	0
	Return
;
;=========================================================================================
;
;=========================================================================================
; call once
;=========================================================================================
;
InitializeIO	MOVLB	0x01	; select bank 1
	bsf	OPTION_REG,NOT_WPUEN	; disable pullups on port B
	bcf	OPTION_REG,TMR0CS	; TMR0 clock Fosc/4
	bcf	OPTION_REG,PSA	; prescaler assigned to TMR0
	bsf	OPTION_REG,PS0	;111 8mhz/4/256=7812.5hz=128uS/Ct=0.032768S/ISR
	bsf	OPTION_REG,PS1	;101 8mhz/4/64=31250hz=32uS/Ct=0.008192S/ISR
	bsf	OPTION_REG,PS2
;
	MOVLW	OSCCON_Value
	MOVWF	OSCCON
	movlw	b'00010111'	; WDT prescaler 1:65536 period is 2 sec (RESET value)
	movwf	WDTCON
;
	movlb	4	; bank 4
	bsf	WPUA,WPUA5	;Put a pull up on the MCLR unused pin.
;
	MOVLB	0x03	; bank 3
	movlw	ANSELA_Val
	movwf	ANSELA
	movlw	ANSELB_Val
	movwf	ANSELB
;
;Setup T2 for 100/s
	movlb	0	; bank 0
	MOVLW	T2CON_Value
	MOVWF	T2CON
	MOVLW	PR2_Value
	MOVWF	PR2
	movlb	1	; bank 1
	bsf	PIE1,TMR2IE	; enable Timer 2 interupt
;
; setup timer 1 for 0.5uS/count
;
	MOVLB	0x00	; bank 0
	MOVLW	T1CON_Val
	MOVWF	T1CON
	bcf	T1GCON,TMR1GE	;always count
;	
; clear memory to zero
	CALL	ClearRam
	CLRWDT
;	CALL	CopyToRam
;
;
;
	MOVLB	0x00	;Bank 0
; setup data ports
	movlw	PortBValue
	movwf	PORTB	;init port B
	movlw	PortAValue
	movwf	PORTA
	MOVLB	0x01	; bank 1
	movlw	PortADDRBits
	movwf	TRISA
	movlw	PortBDDRBits	;setup for programer
	movwf	TRISB
;
	CLRWDT
;-----------------------
;
	MOVLB	0x00
	MOVLW	LEDTIME
	MOVWF	SysLED_Time
	movlw	0x01
	movwf	SysLEDCount	;start blinking right away
	movlw	.100
	movwf	Timer4Lo	;ignor buttons for 1st second
;
;
	CLRWDT
;
;
	bsf	INTCON,PEIE	; enable periferal interupts
	bsf	INTCON,GIE	; enable interupts
;
	return
;
;=========================================================================================
;=========================================================================================
;
;
;
	END
;
