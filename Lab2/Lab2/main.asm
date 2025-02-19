/*******************************************************/
; Universidad del Valle de Guatemala
; IE2023: Programación de Microcontroladores;
; Lab2.asm
;
; Created: 1/30/2025 7:48:07 AM
; Author : Matheo
; Hardware ATMega 328P


.include "M328PDEF.inc" // Incluir definiciones de ATmega328P

.cseg
.org 0x0000
.def COUNTER = R20
.def LEDS = R21
.def COUNTER_DISPLAY = R22
.def DISPLAY = R23

// Configuración de la pila
	LDI     R16, LOW(RAMEND)
	OUT     SPL, R16
	LDI     R16, HIGH(RAMEND)
	OUT     SPH, R16

// Configuración de MCU
SETUP:
	//	CONFIGURA EL CLOCK GENERAL CON UN PRESCALER DE 16 (1MHz)
	LDI R16, (1 << CLKPCE)
	STS CLKPR, R16 // Habilitar cambio de PRESCALER
	LDI R16, 0b00000100
	STS CLKPR, R16 // Configurar Prescaler a 16 F_cpu = 1MHz

    // Configurar PORTC como salida (para mostrar el contador en LEDs)
    LDI     R16, 0xFF
    OUT     DDRC, R16  // PORTC como salida
	LDI		R16, 0x00
    OUT     PORTC, R16 // Inicializar PORTC con el contador en 0

	// Configurar PORTD como salida (para mostrar display de 7 segmentos)
    LDI     R16, 0xFF
    OUT     DDRD, R16  ; PORTD como salida
    
	//Configurar PORTB como entrada con pull-ups activados
    LDI     R16, 0x00
    OUT     DDRB, R16  ; PORTB como entrada
    LDI     R16, 0xFF
    OUT     PORTB, R16  ; Activar pull-ups

	//GUARDAR EN REGISTROS DE LA SRAM LAS COMBINACIONES PARA EL CONTADOR
	LDI     XH, 0x01  // PUNTERO X HACIA 0x0100
	LDI     XL, 0x00  


	LDI		R16, 0b01111110 //	0
	ST		X+,	R16		//	SE LE SUMA 1 AL PUNTERO

	LDI		R16, 0b00110000	//	1
	ST		X+,	R16 

	LDI		R16, 0b01101101	//	2
	ST		X+,	R16 

	LDI		R16, 0b01111001	//	3
	ST		X+,	R16 

	LDI		R16, 0b00110011	//	4
	ST		X+,	R16 

	LDI		R16, 0b01011011	//	5
	ST		X+,	R16 

	LDI		R16, 0b01011111	//	6
	ST		X+,	R16 

	LDI		R16, 0b01110000	//	7
	ST		X+,	R16 

	LDI		R16, 0b01111111	//	8
	ST		X+,	R16 

	LDI		R16, 0b01111011	//	9	
	ST		X+,	R16 

	LDI		R16, 0b01110111 //	A
	ST		X+,	R16 

	LDI		R16, 0b00011111 //	B
	ST		X+,	R16

	LDI		R16, 0b01001110 //	C
	ST		X+,	R16

	LDI		R16, 0b00111101 //	D
	ST		X+,	R16

	LDI		R16, 0b01001111 //	E
	ST		X+,	R16

	LDI		R16, 0b01000111 //	F
	ST		X+,	R16


	LDI		XH, 0X01	//	PUNTERO X HACIA 0x0100
	LDI		XL, 0X00

	LD      DISPLAY, X     //Cargar el primer número (0) 
	OUT     PORTD, DISPLAY // Mostrar 0 en el display


	LDI		R17, 0xFF	// ESTADO ACTUAL DE LOS BOTONES
	// Inicializar timer0
	CALL	INIT_TMR0

    LDI     COUNTER, 0x00	// Inicializar contador  en 0
	LDI		LEDS, 0x00		// EMPEZAR CON TODAS LAS LEDS APAGADAS
	LDI		COUNTER_DISPLAY, 0x00 // INCIALIZAR CONTADOR DE LEDS EN 0
	LDI		R25, 0x00

// Bucle principal

LOOP:
	IN		R18, TIFR0 // Leer registro de interrupci n de TIMER 0?
	SBRC	R18, TOV0 // Salta si el bit 0 est "set" (TOV0 bit)?
	RJMP	SALTAR_CONTADOR

//	VALOR botones del display DE 7 SEGMENTOS
//----------------- Anti-Rebote -----------------
    IN      R16, PINB   // Leer botones
    CP      R17, R16
    BREQ    LOOP        // Si no hay cambios, seguir esperando
    CALL    DELAY       // Esperar para filtrar rebotes
    IN      R16, PINB   // Leer botones otra vez
    CP      R17, R16
    BREQ    LOOP        // Si el estado no cambió después del delay, ignorar
	RJMP	SALTAR_DISPLAY
//-----------------------------------------------

SALTAR_CONTADOR:
	
	SBI		TIFR0, TOV0 // Limpiar bandera de "overflow"
	LDI		R16, 159
	OUT		TCNT0, R16 // Volver a cargar valor inicial en TCNT0
	
	INC		COUNTER

	CPI		COUNTER, 10
	BRNE	LOOP

	CLR		COUNTER
	
	CALL	SUMARL

	RJMP	LOOP


//	VALOR DISPLAY DE 7 SEGMENTOS
SALTAR_DISPLAY:

    MOV     R17, R16    // Guardar nuevo estado de botones

    SBRS    R16, 0      // Si PB0 fue presionado (LOW)
    CALL    SUMAR1

    SBRS    R16, 1      // Si PB1 fue presionado (LOW)
    CALL    RESTAR1

    OUT     PORTD, DISPLAY  // Actualizar el display

	RJMP	LOOP



// Subrutinas sin interrupcion


// Sumar UNO AL CONTADOR
SUMARL:
    CP		LEDS, COUNTER_DISPLAY	// Comparar si LEDS es 15
    BREQ    OVERFLOWL				// Si es igual al valor del DISPLAY, manejar overflow
    CPI		LEDS, 0x0F
	BREQ	OVER_OVERFLOW
	
	INC     LEDS					// Incrementar LEDS
	
	MOV		R28, R25
	ADD		R28, LEDS				
    OUT     PORTC, R28				// Mostrar el valor en los LEDs
    
	RET

OVERFLOWL:
    LDI     LEDS, 0x00

	LDI		R28, 0b00010000
	EOR		R25, R28          // XOR PARA CAMBIAR DE ESTADO EL BIT 4 DEL PORTC
    
	OUT		PORTC, R25		  // Alternar el LED

    RET 
	
OVER_OVERFLOW:
	LDI     LEDS, 0x00
	OUT		PORTC, R25
	RET
//-------------------------------------


// Subrutina para incrementar el contador
SUMAR1:
	CPI		DISPLAY, 0b01000111 // VERIFICAR SI HAY OVERFLOW EN EL DISPLAY
    BREQ    OVERFLOW1
	LD		DISPLAY, X+		//INCREMENTAR UNA AL PUNTERO X
	LD		DISPLAY, X		//	GUARDAR EN DISPLAY LO QUE ESTA APUNTANDO EL PUNTERO
	
	INC		COUNTER_DISPLAY
    
	RET
OVERFLOW1:
    LDI		XH, 0x01
	LDI		XL, 0X00

	LD		DISPLAY, X
	
	CLR		COUNTER_DISPLAY 
    
	RET    
// Subrutina para decrementar el contador
RESTAR1:
	CPI		DISPLAY, 0b01111110	// COMPOROBAR SI HAY UNDERFLOW EN EL DISPLAY
    BREQ    UNDERFLOW1	
	LD		DISPLAY, -X		//	DISMINUIR UNO AL PUNTERO EN X
	LD		DISPLAY, X
	
	DEC		COUNTER_DISPLAY
    
	RET
UNDERFLOW1:	
    LDI		XH, 0x01
	LDI		XL, 0X0F
	LD		DISPLAY, X
	LDI		COUNTER_DISPLAY, 0x0F
    RET   

// TIMER0
INIT_TMR0:
	LDI		R16, (1<<CS02) | (1<<CS00)
	OUT		TCCR0B, R16 // Setear prescaler del TIMER 0 a 1024
	LDI		R16, 159
	OUT		TCNT0, R16 // Cargar valor inicial en TCNT0
	RET

// DELAY
DELAY:
    LDI     R24, 255
SUBDELAY1:
    DEC     R24
    BRNE    SUBDELAY1
    LDI     R24, 255  
    RET





//Subrutinas de interrupción
