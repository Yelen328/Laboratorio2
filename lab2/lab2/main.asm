
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
.cseg
.org	0x0000
.def	COUNTER=R20	//Contador para el Timer0

//Stack
LDI		R16, LOW(RAMEND)
OUT		SPL, R16
LDI		R16, HIGH(RAMEND)
OUT		SPH, R16

// Configuracion MCU
SETUP:
	// Configurar Prescaler "Principal"
	LDI R16, (1 << CLKPCE)
	STS CLKPR, R16 // Habilitar cambio de PRESCALER
	LDI R16, 0b00000100
	STS CLKPR, R16 // Configurar Prescaler a 16 F_cpu = 1MHz
	// Inicializar timer0
	CALL INIT_TMR0

	; PORTB COMO SALIDA INICIALMENTE APAGADO
	LDI		R16, 0xFF
	OUT		DDRB, R16 //Setear el puerto B como salida
	LDI		R16, 0x00
	OUT		PORTB, R16 //Valor inicial en 0

	// Deshabilitar serial (esto apaga los dem s LEDs del Arduino)
	LDI R16, 0x00
	STS UCSR0B, R16
	LDI COUNTER, 0x00
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
	INC R17
	ANDI	R17,0x0F
	OUT		PORTB, R17
	RET
