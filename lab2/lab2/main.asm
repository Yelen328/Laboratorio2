
; Created: 13/2/2025 23:50:57
; Author : Yelena Cotzojay
;

;
; Laboratorio_2.asm
;
; Created: 14/2/2025 04:30:27
; Author : yelen
;
// Encabezado
.include "M328PDEF.inc"
.dseg
.org	SRAM_START
.cseg
.org	0x000
.DEF	DISPLAY=R21 
.def	COUNTER=R20	//Contador para el Timer0

//Stack
LDI		R16, LOW(RAMEND)
OUT		SPL, R16
LDI		R16, HIGH(RAMEND)
OUT		SPH, R16

// Tabla de conversión hexadecimal a 7 segmentos

TABLA:
    .DB 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x67, 0x77, 0x7F, 0x39, 0x5E, 0x79, 0x71

// Configuracion MCU
SETUP:
	//Configurar Prescaler "Principal"
	LDI R16, (1 << CLKPCE)
	STS CLKPR, R16 // Habilitar cambio de PRESCALER
	LDI R16, 0b00000100
	STS CLKPR, R16 // Configurar Prescaler a 16 F_cpu = 1MHz
	// Inicializar timer0
	CALL INIT_TMR0

	;PORTC COMO ENTRADA CON PULL-UP HABILIDATO 
	LDI		R16, 0x00
	OUT		DDRC, R16
	LDI		R16, 0xFF
	OUT		PORTC, R16

	;PORTD COMO SALIDA 
	LDI		R16, 0xFF
	OUT		DDRD,R16
	LDI		R16, 0x00
	OUT		PORTD, R16

	; PORTB COMO SALIDA INICIALMENTE APAGADO
	LDI		R16, 0xFF
	OUT		DDRB, R16 //Setear el puerto B como salida
	LDI		R16, 0x00
	OUT		PORTB, R16 //Valor inicial en 0

	// Deshabilitar serial (esto apaga los dem s LEDs del Arduino)
	LDI R16, 0x00
	STS UCSR0B, R16
	//LDI COUNTER, 0x00

	//variables iniciales 
	LDI		DISPLAY, 0x00	//Iniciar en 0
	CALL	ACTUALIZAR_DISPLAY	
	
/****************************************/
// Loop Infinito
MAIN_LOOP:IN R16, TIFR0 // Leer registro de interrupci n de TIMER 0?
	SBRS R16, TOV0 // Salta si el bit 0 est "set" (TOV0 bit)?
	RJMP MAIN_LOOP // Reiniciar loop
	SBI TIFR0, TOV0 // Limpiar bandera de "overflow"
	LDI R16, 100
	OUT TCNT0, R16 // Volver a cargar valor inicial en TCNT0
	INC COUNTER
	CPI COUNTER, 10 // R20 = 10 after 100ms (since TCNT0 is set to 10 ms)
	BRNE MAIN_LOOP
	CLR COUNTER
	CALL CONTADOR
	//ANTIREBOTE
	IN		R16, PINC // Guardando el estado de PORTC en R16 0xFF
	CP		R17, R16 // Comparamos estado "viejo" con estado "nuevo"
	BREQ	MAIN_LOOP
	CALL	DELAY
	IN		R16, PINC
	CP		R17, R16
	BREQ	MAIN_LOOP
	// Volver a leer PIND
	MOV		R17, R16
	
	SBRS	R17, 0	//SI el bit 0 del PINC es 0 (No apachado)
	CALL	INC_CONT // Si está en 1 ejecuta esta línea
	SBRS	R17, 1	// si el bit 1 del pin es 0
	CALL	DEC_CONT
	
	RJMP MAIN_LOOP
	
/****************************************/
// NON-Interrupt subroutines
INIT_TMR0:
	LDI R16, (1<<CS01) | (1<<CS00)
	OUT TCCR0B, R16 // Setear prescaler del TIMER 0 a 64
	LDI R16, 100
	OUT TCNT0, R16 // Cargar valor inicial en TCNT0
	RET

CONTADOR:
	INC R19
	ANDI	R19,0x0F
	OUT		PORTB, R19
	RET
INC_CONT:
	INC		DISPLAY
	CPI		DISPLAY,0x10	//Si llega a 16, reninicar
	BRLO	ACTUALIZAR_DISPLAY
	LDI		DISPLAY, 0x00	//Reiniciar el contador

ACTUALIZAR_DISPLAY:
	LDI     ZH, HIGH(TABLA<<1)
    LDI     ZL, LOW(TABLA<<1)
	ADD		ZL, DISPLAY
	LPM		R23, Z
	OUT		PORTD, R23
	RET

DEC_CONT:
	CPI		DISPLAY, 0x00	//Si, esta en 0, resetearlo a 15
	BRNE	DECREMENTAR
	LDI		DISPLAY, 0x0F	//Si está en 0, ponerlo en 15
	RJMP	ACTUALIZAR_DISPLAY
DECREMENTAR:
	DEC		DISPLAY
	RJMP	ACTUALIZAR_DISPLAY


// Sub-rutina (no de interrupci n) 
DELAY:
	LDI		 R18, 0xFF

	SUB_DELAY1:
	DEC		R18
	CPI		R18, 0
	BRNE	SUB_DELAY1
	LDI		R18, 0xFF

	SUB_DELAY2:
	DEC		R18
	CPI		R18, 0
	BRNE	SUB_DELAY2
	LDI		R18, 0xFF

	SUB_DELAY3:
	DEC		R18
	CPI		R18, 0
	BRNE	SUB_DELAY3
	RET



