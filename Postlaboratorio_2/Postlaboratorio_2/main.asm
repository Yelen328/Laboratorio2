;
; Postlaboratorio_2.asm
;
; Created: 19/2/2025 12:51:55
; Author : yelena cotzojay
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



// Configuracion MCU
SETUP:
	//Configurar Prescaler "Principal"
	LDI		R16, (1 << CLKPCE)
	STS		CLKPR, R16 // Habilitar cambio de PRESCALER
	LDI		R16, 0b00000100
	STS		CLKPR, R16 // Configurar Prescaler a 16 F_cpu = 1MHz
	// Inicializar timer0
	CALL	INIT_TMR0

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
	LDI		R24, 0x00	//REGISTRO PARA EL LED DE "ALARMA"
	
/****************************************/
// Loop Infinito
MAIN_LOOP:
	//botones
	CALL	ANTIREBOTE
	//Timer
	IN		R16, TIFR0 // Leer registro de interrupci n de TIMER 0?
	SBRS	R16, TOV0 // Salta si el bit 0 est "set" (TOV0 bit)?
	RJMP	MAIN_LOOP // Reiniciar loop
	SBI		TIFR0, TOV0 // Limpiar bandera de "overflow"
	LDI		R16, 100
	OUT		TCNT0, R16 // Volver a cargar valor inicial en TCNT0
	INC		COUNTER
	CPI		COUNTER, 100 // R20 = 10 after 100ms (since TCNT0 is set to 10 ms)
	BRNE	MAIN_LOOP
	CLR		COUNTER
	CALL	CONTADOR
	
	

	//Comparar los valores de ambos contadores
	//R19=contador en segundos 
	//R21=DISPLAY
	//CP		R19, DISPLAY
	//CALL	REINICIO_TCE
	RJMP	MAIN_LOOP
	
/****************************************/
// NON-Interrupt subroutines


INIT_TMR0:
	LDI		R16, (1<<CS01) | (1<<CS00)
	OUT		TCCR0B, R16 // Setear prescaler del TIMER 0 a 64
	LDI		R16, 100
	OUT		TCNT0, R16 // Cargar valor inicial en TCNT0
	RET

ANTIREBOTE:
	IN		R16, PINC // Guardando el estado de PORTC en R16 0xFF
	CP		R17, R16 // Comparamos estado "viejo" con estado "nuevo"
	BREQ	ACTUALIZAR_DISPLAY
	CALL	DELAY
	IN		R16, PINC
	CP		R17, R16
	BREQ	MAIN_LOOP
	// Volver a leer PIND
	MOV		R17, R16

	//BOTONES
	SBRC	R17, 0
	RJMP	DEC_CONT
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
	SBRC	R17, 1
	RJMP	ACTUALIZAR_DISPLAY
	CPI		DISPLAY, 0x00	//Si, esta en 0, resetearlo a 15
	BRNE	DECREMENTAR
	LDI		DISPLAY, 0x0F	//Si está en 0, ponerlo en 15
	RJMP	ACTUALIZAR_DISPLAY
DECREMENTAR:
	DEC		DISPLAY
	RJMP	ACTUALIZAR_DISPLAY

CONTADOR:
	CP		DISPLAY, R19
	BREQ	REINICIO_TCE
	INC		R19
	ANDI	R19,0x0F
	OUT		PORTB, R19
	Ret
	

//Alarma

REINICIO_TCE:
	SBRS	R24, 4	//si el bit está en 1 (ENCENDIDO)
	RJMP	ENCENDER_LED
    CBR		R24, (1<<4)  // Apagar bit 4 si está encendido
	OUT		PORTB, R24   // Enviar cambios al puerto
	//reiniciar el contador binario
	CLR		R19
    RET	

ENCENDER_LED:
	SBRC	R24, 4	//Si el bit 4 está en 0 (apagado)
	RJMP	CONTINUAR
    SBR		R24, (1<<4)  // Encender bit 4 si está apagado
	OUT		PORTB, R24   // Enviar cambios al puerto
	
CONTINUAR:
	//reiniciar el contador binario
	CLR		R19
    RJMP	MAIN_LOOP	

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

// Tabla de conversión hexadecimal a 7 segmentos

TABLA:
    .DB 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x67, 0x77, 0x7F, 0x39, 0x5E, 0x79, 0x71



