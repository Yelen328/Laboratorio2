
; Created: 13/2/2025 23:50:57
; Author : Yelena Cotzojay
;

;
; Laboratorio_2.asm
;
; Created: 14/2/2025 09:49:27
; Author : yelen
;
// Encabezado
.include "M328PDEF.inc"
.dseg
.org	SRAM_START
.cseg
.org	0x0000
.def	COUNTER=R20	//Contador para el Timer0

//Stack
LDI		R16, LOW(RAMEND)
OUT		SPL, R16
LDI		R16, HIGH(RAMEND)
OUT		SPH, R16

// Tabla de conversión hexadecimal a 7 segmentos
TABLA:
    .DB 0x7E, 0x30, 0x6D, 0x79, 0x33, 0x5B, 0x5F, 0x70, 0x7F, 0x7B, 0x77, 0x7F, 0x4E, 0x7E, 0x4F, 0x47

// Configuracion MCU
SETUP:
	// Configurar Prescaler "Principal"
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
	LDI COUNTER, 0x00

	//variables iniciales 
	LDI		R16, 0xFF
	
	LDI		ZH, HIGH(TABLA<<1) //Carga la parte alta de la dirección de tabla en el registro ZH
	LDI		ZL, LOW(TABLA<<1)	//Carga la parte baja de la dirección de la tabla en el registro ZL
	LPM		R16, Z				//Carga en R16 el valor de la tabla en ela dirreción Z
	OUT		PORTD, R16			//Muestra en el puerto D el valor leido de la tabla
/****************************************/
// Loop Infinito
MAIN_LOOP:
	IN R16, TIFR0 // Leer registro de interrupci n de TIMER 0?
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