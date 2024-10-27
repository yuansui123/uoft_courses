.global _start
_start:  LDR   R6, =0xFF200050
		 LDR   R8, =0xFFFEC600
		 LDR   R9, =2000000
		 STR   R9, [R8]

MAIN:    MOV   R3, #0 //counter that will count from 0 to 5999
		 LDR   SP, =0x40000000

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
		 
END:      B       END

//pass in value is R3
/* Display */
DISPLAY: PUSH {R4-R12, LR}

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
		   
		  		  
BIT_CODES:.byte 0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
		  .byte 0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
          .end        




	
	