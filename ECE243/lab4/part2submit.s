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

                  BL       CONFIG_GIC         // configure the ARM generic
                                              // interrupt controller
                  BL       CONFIG_PRIV_TIMER  // configure A9 Private Timer
				                              // Private time will now generate an interrupt every 0.25 seconds
                  BL       CONFIG_KEYS        // configure the pushbutton
                                              // KEYs port

/* Enable IRQ interrupts in the ARM processor */
                  MOV      R0, #INT_ENABLE | SVC_MODE        // IRQ unmasked, MODE = SVC
                  MSR      CPSR_c, R0
                  LDR      R5, =0xFF200000    // LEDR base address
LOOP:                                          
                  LDR      R3, COUNT          // global variable
                  STR      R3, [R5]           // writes COUNT to the LEDR lights
                  B        LOOP                
          

/* Global variables */
                .global  COUNT
COUNT:          .word    0x0                  // used by timer
                .global  RUN
RUN:            .word    0x1                  // initial value to increment COUNT

/* Configure the A9 Private Timer to create interrupts at 0.25 second intervals */
CONFIG_PRIV_TIMER:                             
                PUSH {R7, R8, R9, LR}
				LDR   R8, =0xFFFEC600
			    LDR   R9, =500000
			    STR   R9, [R8]
                
				MOV   R7, #0b111
			    STR   R7, [R8, #0x8] //this will start the timer (I and A and E are set to 1)
				                     //when F is set to 1, 
									 //a processor interrupt can be generated 
									 //when the timer reaches 0.
			    
			    //LDR   R0, [R8, #0xC] //Interrupt status (F)
				//CMP   R0, #0       //Interrupt status set to 1 means clock is done and branches itseld
		        //BEQ   CONFIG_PRIV_TIMER
				
				//STR   R0, [R8, #0xC] //Counting is done, need to reset F to 0 by writing 1 to it
                
				//MOV   R7, #0b010
		        //STR   R7, [R8, #0x8] //this will stop the timer b/c E is set to 0
				                       //Don't want to stop the timer
			
			    POP {R7, R8, R9, LR}
                MOV      PC, LR
                   
/* Configure the pushbutton KEYS to generate interrupts */
CONFIG_KEYS:                                    
                //The interrupt-mask register (0xFF200058) allows interrupts to be generated 
				//when a key is pressed.
				//Each bit in the Edgecapture register is set to 1 by the parallel port
				//when the corresponding key is pressed.
				//An interrupt service routine can read this register to determine which 
				//key has been pressed.
				//Writing any value to the Edgecapture register deasserts the interrupt signal
				//being sent to the GIC and sets all bits of the Edgecapture register to zero
				
				PUSH {R10, R11, LR}
				
				LDR R10, =0xFF200058    //R1 is holding the address of the keys
				//LDR R11, [R10, #0xC]     //R2 is holding all the keys that are pressed
				//doesnt matter which keys are pressed, only need to know that when the keys are pressed they generate an interrupt
				MOV R11, #0b1111
			    STR R11, [R10] 
				
				//STR R11, [R10, #0xC] this deasserts the interrupt signal so this shouldnt
				//be here?
				
				POP {R10, R11, LR}
                MOV  PC, LR

/*--- IRQ ---------------------------------------------------------------------*/
IRQ_HANDLER:    
                //how to get to this part of the code? there is no branch to here

                PUSH     {R0-R7, LR}
    
                /* Read the ICCIAR in the CPU interface */
                LDR      R4, =0xFFFEC100
                LDR      R5, [R4, #0x0C]         // read the interrupt ID
				
				CMP      R5, #73                 //73 means the key
				BLEQ       KEY_ISR               //If key is pressed, branch
//UNEXPECTED:     BNE      UNEXPECTED            // if not recognized, stop here
                                                 // infinite loop if R5 is not 73
                CMP       R5, #29                //29 means A9 Private Timer
                BLEQ      PRIV_TIMER_ISR

                //SUBS     PC, LR, #4 //What does this do?
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
                //Need to toggle the value of the RUN global variable each time a 
				//key is pressed.
				PUSH {R6, R10, R11, LR}
				LDR R6, RUN
				
				LDR R10, =0xFF200050    //R1 is holding the address of the keys
				
				LDR R11, [R10, #0xC]     //R2 is holding all the keys that are pressed
				
				//CMP R11, #0 KEY will always be 1 otherwise woulnt get in here
				//MOVEQ R6, #0
				EOR R6, #1       //This alternates RUN (between 1 and 0)
				
				
				STR R6, RUN
				
				STR R11, [R10, #0xC]
				
				
				
				//How to even get to this part of the code? there is no branch to here
                POP {R6, R10, R11, LR}
                MOV      PC, LR

/******************************************************************************
 * A9 Private Timer interrupt service routine
 *                                                                          
 * This code toggles performs the operation COUNT = COUNT + RUN
 *****************************************************************************/
                .global    TIMER_ISR
PRIV_TIMER_ISR: 
                LDR  R2, COUNT
				LDR  R3, RUN
				ADD  R2, R3
				STR  R2, COUNT
                //MOV      R2, #COUNT
				//ADD      R2, #RUN
				LDR  R2, =0xFFFEC600
				MOV   R0, #1
                STR   R0, [R2, #0xC] 
                MOV      PC, LR
/* 
 * Configure the Generic Interrupt Controller (GIC)
*/
                .global  CONFIG_GIC
CONFIG_GIC:
                PUSH     {LR}
                MOV      R0, #29
                MOV      R1, #CPU0
                BL       CONFIG_INTERRUPT
                
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
                .end   
