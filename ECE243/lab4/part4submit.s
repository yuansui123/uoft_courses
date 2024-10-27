               .equ      EDGE_TRIGGERED,    0x1
               .equ      LEVEL_SENSITIVE,   0x0
               .equ      CPU0,              0x01    // bit-mask; bit 0 represents cpu0
               .equ      ENABLE,            0x1

               .equ      KEY0,              0b0001
               .equ      KEY1,              0b0010
               .equ      KEY2,              0b0100
               .equ      KEY3,              0b1000

               .equ      IRQ_MODE,          0b10010
               .equ      SVC_MODE,          0b10011

               .equ      INT_ENABLE,        0b01000000
               .equ      INT_DISABLE,       0b11000000

/*********************************************************************************
 * Initialize the exception vector table
 ********************************************************************************/
                .section .vectors, "ax"

                B        _start             // reset vector
                .word    0                  // undefined instruction vector
                .word    0                  // software interrrupt vector
                .word    0                  // aborted prefetch vector
                .word    0                  // aborted data vector
                .word    0                  // unused vector
                B        IRQ_HANDLER        // IRQ interrupt vector
                .word    0                  // FIQ interrupt vector

/* ********************************************************************************
 * This program demonstrates use of interrupts with assembly code. The program 
 * responds to interrupts from a timer and the pushbutton KEYs in the FPGA.
 *
 * The interrupt service routine for the timer increments a counter that is shown
 * on the red lights LEDR by the main program. The counter can be stopped/run by 
 * pressing any of the KEYs.
 ********************************************************************************/
                .text
                .global  _start
_start:        
                /* Set up stack pointers for IRQ and SVC processor modes */
                MOV      R1, #INT_DISABLE | IRQ_MODE 
				MSR      CPSR_c, R1              // Change to IRQ mode
				LDR      SP, =0x40000           // set IRQ mode stack pointer
				
				MOV      R1, #INT_DISABLE | SVC_MODE
				MSR      CPSR_c, R1               // Change into SVC mode
				LDR      SP, =0x20000           // set SVC mode stack pointer
                
				BL       CONFIG_GIC         // configure the ARM generic interrupt controller

                BL       CONFIG_PRIV_TIMER  // configure the timer
                BL       CONFIG_TIMER       // configure the FPGA interval timer
                BL       CONFIG_KEYS        // configure the pushbutton KEYs

                /* enable IRQ interrupts in the processor */
                MOV      R0, #INT_ENABLE | SVC_MODE        // IRQ unmasked, MODE = SVC
                MSR      CPSR_c, R0
                //LDR      R5, =0xFF200000    // LEDR base address

                LDR      R5, =0xFF200000    // LEDR base address
                LDR      R6, =0xFF200020    // HEX3-0 base address
LOOP:
                LDR      R3, COUNT          // global variable
                STR      R3, [R5]           // light up the red lights
                LDR      R4, HEX_code       // global variable
                STR      R4, [R6]           // show the time in format SS:DD

                B        LOOP                            

/* Global variables */
                .global  COUNT
COUNT:          .word    0x0                // used by timer
                .global  RUN
RUN:            .word    0x1                // initial value to increment COUNT
                .global  TIME
TIME:           .word    0x0                // used for real-time clock
                .global  HEX_code
HEX_code:       .word    0x0

/* Configure the A9 Private Timer to create interrupts every 0.25 seconds */
CONFIG_PRIV_TIMER:
                PUSH {R7, R8, R9, LR}
				LDR   R8, =0xFFFEC600
			    LDR   R9, =500000
			    STR   R9, [R8]
                
				MOV   R7, #0b111
			    STR   R7, [R8, #0x8]
				
				POP {R7, R8, R9, LR}
                MOV      PC, LR
                   
/* Configure the FPGA interval timer to create interrupts at 0.01 second intervals */
CONFIG_TIMER:
                PUSH {R7-R10, LR}
				LDR  R7, =0xFF202000
				LDR  R8, =1000000
				STR  R8, [R7]
				
				MOV  R9, #0b0111    //dont want this timer to stop
				STR  R9, [R7, #0x4]
				POP {R7-R10, LR}
                MOV  PC, LR

/* Configure the pushbutton KEYS to generate interrupts */
CONFIG_KEYS:
                PUSH {R10, R11, LR}
				
				LDR R10, =0xFF200058    //R1 is holding the address of the keys
			
				MOV R11, #0b1111
			    STR R11, [R10] 
				
				POP {R10, R11, LR} 
                MOV      PC, LR

/*--- IRQ ---------------------------------------------------------------------*/
IRQ_HANDLER:
                PUSH     {R0-R7, LR}
    
                /* Read the ICCIAR in the CPU interface */
                LDR      R4, =0xFFFEC100
                LDR      R5, [R4, #0x0C]         // read the interrupt ID
				
				CMP      R5, #73                 //73 means the key
				BLEQ     KEY_ISR               

                CMP      R5, #29                //29 means A9 Private Timer
                BLEQ     PRIV_TIMER_ISR
				
				CMP      R5, #72                //72 means FPGA timer
				BLEQ     TIMER_ISR

EXIT_IRQ:
                /* Write to the End of Interrupt Register (ICCEOIR) */
                STR      R5, [R4, #0x10]
    
                POP      {R0-R7, LR}
                SUBS     PC, LR, #4 


/****************************************************************************************
 * Pushbutton - Interrupt Service Routine                                
 *                                                                          
 * This routine toggles the RUN global variable.
 ***************************************************************************************/
                .global  KEY_ISR
KEY_ISR:        
                PUSH {R6, R10, R11, LR}
				LDR R6, RUN
				
				LDR R10, =0xFF200050    //R1 is holding the address of the keys
				
				LDR R11, [R10, #0xC]     //R2 is holding all the keys that are pressed
				
				EOR R6, #1       //This alternates RUN (between 1 and 0)
				
				STR R6, RUN
				
				STR R11, [R10, #0xC]
				
				POP {R6, R10, R11, LR}
                MOV      PC, LR

/******************************************************************************
 * A9 Private Timer interrupt service routine
 *                                                                          
 * This code toggles performs the operation COUNT = COUNT + RUN
 *****************************************************************************/
                .global  PRIV_TIMER_ISR
PRIV_TIMER_ISR:
                LDR      R2, COUNT
				LDR      R3, RUN
				ADD      R2, R3
				STR      R2, COUNT
				LDR      R2, =0xFFFEC600
				MOV      R0, #1
                STR      R0, [R2, #0xC] 
                MOV      PC, LR 
                MOV      PC, LR

/******************************************************************************
 * Interval timer interrupt service routine
 *                                                                          
 * This code performs the operation ++TIME, and produces HEX_code
 *****************************************************************************/
                .global  TIMER_ISR
TIMER_ISR:
                LDR     R2, TIME
				ADD     R2, #1
				STR     R2, TIME
				LDR     R2, =0xFF202000
				
				//branch to display from here
				MOV     R3, #0       //counter
				BL      DISPLAY
                MOV     PC, LR
/*
MLOOP:   LDR   R0, [R6, #0xC]
		 CMP   R0, #0
		 BLNE  RESET
		 LDR   R1, =6000
		 CMP   R3, R1
		 MOVEQ R3, #0
		 BL     DISPLAY
		 ADD   R3, #1  

DO_DELAY:MOV   R7, #0b011
		 STR   R7, [R8, #0x8] //this will start the timer
DELAY_WAIT:	 LDR   R0, [R8, #0xC]
		 CMP   R0, #0
		 BEQ   DELAY_WAIT
		 STR   R0, [R8, #0xC]
		 MOV   R7, #0b010
		 STR   R7, [R8, #0x8] //this will stop the timer
		 B     MLOOP
		
RESET:   PUSH {R6, LR}
		 STR   R0, [R6, #0xC]
WAIT:    LDR R0, [R6, #0xC]
		 CMP R0, #0
		 BEQ WAIT
		 STR   R0, [R6, #0xC]
		 POP  {R6, LR}
		 MOV   PC, LR
		 
END:     B       END
*/
//pass in value is R3
/* Display */
DISPLAY:    PUSH {R4-R12, LR}

			LDR R8, =0xFF200020 // base address of HEX3-HEX0

			MOV    R0, R3       // first parameter for DIVIDE goes in R0
			MOV	   R1, #1000    // second parameter for DIVIDE goes in R1
            BL     DIVIDE      
			MOV    R9, R1       //1000 digit
			MOV    R10, R0      //remainder
			MOV    R0, R9
			BL     SEG7_CODE
			MOV    R4, R0
            
			MOV    R0, R10
			MOV	   R1, #100
            BL     DIVIDE
			MOV    R9, R1       //100 digit
			MOV    R10, R0      //remainder
			MOV    R0, R9
			BL     SEG7_CODE
			LSL    R4, #8
		 	ORR    R4, R0
			
            MOV    R0, R10
			MOV	   R1, #10
            BL     DIVIDE
			MOV    R9, R1       //10 digit
			MOV    R10, R0      //1 digit
			MOV    R0, R9
			BL     SEG7_CODE
			LSL    R4, #8
		 	ORR    R4, R0
			
			MOV    R0, R10
			BL     SEG7_CODE
			LSL    R4, #8
			ORR    R4, R0

         STR R4, [R8] // display the number from R 
		 POP {R4-R12, LR}
		 MOV PC, LR

//pass in value is R1, R0
//return value is R1, R0
/* Subroutine to perform the integer division R0 / 10.
 * Returns: quotient in R1, and remainder in R0 */
DIVIDE:     PUSH {R2, LR}
			MOV    R2, #0
CONT:       CMP    R0, R1
            BLT    DIV_END
            SUB    R0, R1
            ADD    R2, #1
            B      CONT
DIV_END:    MOV    R1, R2     // quotient in R1 (remainder in R0)
			POP {R2, LR}
            MOV    PC, LR

//pass in value is R0
//return value is R0
SEG7_CODE: PUSH {R1, LR}
		   MOV R1, #BIT_CODES
		   ADD R1, R0 // index into the BIT_CODES "array"
	       LDRB R0, [R1] // load the bit pattern (to be returned)
		   POP {R1, LR}
	       MOV PC, LR
		   
		  		  


/* 
 * Configure the Generic Interrupt Controller (GIC)
*/
                .global  CONFIG_GIC
CONFIG_GIC:
                PUSH     {LR}
                /* Enable A9 Private Timer interrupts */
                MOV      R0, #29
                MOV      R1, #CPU0
                BL       CONFIG_INTERRUPT
                
                /* Enable FPGA Timer interrupts */
                MOV      R0, #72
                MOV      R1, #CPU0
                BL       CONFIG_INTERRUPT

                /* Enable KEYs interrupts */
                MOV      R0, #73
                MOV      R1, #CPU0
                /* CONFIG_INTERRUPT (int_ID (R0), CPU_target (R1)); */
                BL       CONFIG_INTERRUPT

                /* configure the GIC CPU interface */
                LDR      R0, =0xFFFEC100        // base address of CPU interface
                /* Set Interrupt Priority Mask Register (ICCPMR) */
                LDR      R1, =0xFFFF            // enable interrupts of all priorities levels
                STR      R1, [R0, #0x04]
                /* Set the enable bit in the CPU Interface Control Register (ICCICR). This bit
                 * allows interrupts to be forwarded to the CPU(s) */
                MOV      R1, #1
                STR      R1, [R0]
    
                /* Set the enable bit in the Distributor Control Register (ICDDCR). This bit
                 * allows the distributor to forward interrupts to the CPU interface(s) */
                LDR      R0, =0xFFFED000
                STR      R1, [R0]    
    
                POP      {PC}
/* 
 * Configure registers in the GIC for an individual interrupt ID
 * We configure only the Interrupt Set Enable Registers (ICDISERn) and Interrupt 
 * Processor Target Registers (ICDIPTRn). The default (reset) values are used for 
 * other registers in the GIC
 * Arguments: R0 = interrupt ID, N
 *            R1 = CPU target
*/
CONFIG_INTERRUPT:
                PUSH     {R4-R5, LR}
    
                /* Configure Interrupt Set-Enable Registers (ICDISERn). 
                 * reg_offset = (integer_div(N / 32) * 4
                 * value = 1 << (N mod 32) */
                LSR      R4, R0, #3               // calculate reg_offset
                BIC      R4, R4, #3               // R4 = reg_offset
                LDR      R2, =0xFFFED100
                ADD      R4, R2, R4               // R4 = address of ICDISER
    
                AND      R2, R0, #0x1F            // N mod 32
                MOV      R5, #1                   // enable
                LSL      R2, R5, R2               // R2 = value

                /* now that we have the register address (R4) and value (R2), we need to set the
                 * correct bit in the GIC register */
                LDR      R3, [R4]                 // read current register value
                ORR      R3, R3, R2               // set the enable bit
                STR      R3, [R4]                 // store the new register value

                /* Configure Interrupt Processor Targets Register (ICDIPTRn)
                  * reg_offset = integer_div(N / 4) * 4
                  * index = N mod 4 */
                BIC      R4, R0, #3               // R4 = reg_offset
                LDR      R2, =0xFFFED800
                ADD      R4, R2, R4               // R4 = word address of ICDIPTR
                AND      R2, R0, #0x3             // N mod 4
                ADD      R4, R2, R4               // R4 = byte address in ICDIPTR

                /* now that we have the register address (R4) and value (R2), write to (only)
                 * the appropriate byte */
                STRB     R1, [R4]
    
                POP      {R4-R5, PC}

BIT_CODES:.byte 0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
		  .byte 0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
          .end

