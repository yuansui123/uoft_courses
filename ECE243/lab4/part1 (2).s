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

/*********************************************************************************
 * Main program
 ********************************************************************************/
                .text
                .global  _start
_start:        
                /* Set up stack pointers for IRQ and SVC processor modes */
                MOV		 R0, #IRQ_MODE
				MSR	     CPSR_c, R0
				LDR      SP, =0x40000
				MOV      R0, #SVC_MODE
				MSR		 CPSR_c, R0
				LDR      SP, =0x20000

                BL       CONFIG_GIC              // configure the ARM generic interrupt controller

                // Configure the KEY pushbutton port to generate interrupts
                LDR      R0, =0xFF200050                    // pushbutton KEY base address
             	MOV      R1, #0xF                                // set interrupt mask bits
             	STR      R1, [R0, #0x8]

                // enable IRQ interrupts in the processor
                MOV      R0, #0b01010011                    // IRQ unmasked, MODE = SVC
             	MSR      CPSR, R0
IDLE:
                B        IDLE                    // main program simply idles

IRQ_HANDLER:
                PUSH     {R0-R7, LR}
    
                /* Read the ICCIAR in the CPU interface */
                LDR      R4, =0xFFFEC100
                LDR      R5, [R4, #0x0C]         // read the interrupt ID

CHECK_KEYS:
                CMP      R5, #73
UNEXPECTED:     BNE      UNEXPECTED              // if not recognized, stop here
    
                BL       KEY_ISR
EXIT_IRQ:
                /* Write to the End of Interrupt Register (ICCEOIR) */
                STR      R5, [R4, #0x10]
    
                POP      {R0-R7, LR}
                SUBS     PC, LR, #4

/*****************************************************0xFF200050***********************************
 * Pushbutton - Interrupt Service Routine                                
 *                                                                          
 * This routine checks which KEY(s) have been pressed. It writes to HEX3-0
 ***************************************************************************************/
                .global  KEY_ISR
KEY_ISR:		
				PUSH     {LR} 
                LDR      R0, =0xFF200050	//loads addr of key
				LDR      R2, =0xFF200020	//load addr of hex
				LDR		 R1, [R0, #0xC]
				STR		 R1, [R0, #0xC]
				
				ANDS	 R3, R1, #KEY0
				BLNE	 KEY0
				
				ANDS     R3, R1, #KEY1
				BLNE     KEY1
				
				ANDS	 R3, R1, #KEY2
				BLNE	 KEY2
				
				ANDS     R3, R1, #KEY3
				BLNE     KEY3
				
				POP      {LR}
				MOV      PC, LR

KEY0:			PUSH     {R0, R1, R2, R3, LR}
				MOV		 R3, #0b00111111	//display 0

				LDR		 R1, DISPLAY
				EOR 	 R3, R1
				STR		 R3, [R2]
				STR		 R3, DISPLAY
				
				POP     {R0, R1, R2, R3, LR}
				MOV      PC, LR

KEY1:			PUSH     {R0, R1, R2, R3, LR}
				MOV		 R3, #0b00000110	//display 1
				LSL      R3, #8
				LDR		 R1, DISPLAY
				EOR 	 R3, R1
				STR		 R3, [R2]
				STR		 R3, DISPLAY
				
				POP     {R0, R1, R2, R3, LR}
				MOV      PC, LR

KEY2:			PUSH     {R0, R1, R2, R3, LR}
				MOV		 R3, #0b01011011	//display 2
				LSL      R3, #16
				LDR		 R1, DISPLAY
				EOR 	 R3, R1
				STR		 R3, [R2]
				STR		 R3, DISPLAY
				
				POP     {R0, R1, R2, R3, LR}
				MOV      PC, LR

KEY3:			PUSH     {R0, R1, R2, R3, LR}
				MOV		 R3, #0b01001111	//display 3
				LSL      R3, #24
				LDR		 R1, DISPLAY
				EOR 	 R3, R1
				STR		 R3, [R2]
				STR		 R3, DISPLAY
				
				POP     {R0, R1, R2, R3, LR}
				MOV      PC, LR

/* 
 * Configure the Generic Interrupt Controller (GIC)
*/
                .global  CONFIG_GIC
CONFIG_GIC:
                PUSH     {LR}
                /* Enable the KEYs interrupts */
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

DISPLAY: .word   0x00000001


                .end   
