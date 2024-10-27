.global _start
_start:  LDR   R6, =0xFF200050
		 LDR   R8, =0xFFFEC600
		 LDR   R9, =50000000
		 STR   R9, [R8]

MAIN:    MOV   R3, #0 //counter that will count from 0 to 99
		 LDR   SP, =0x40000000

MLOOP:   LDR   R0, [R6, #0xC]
		 CMP   R0, #0
		 BLNE  RESET
		 CMP   R3, #100
		 MOVEQ R3, #0
		 BL     DISPLAY
//DO_DELAY: LDR R7, =500000 // for CPUlator use =500000
//SUB_LOOP: SUBS R7, R7, #1
//BNE SUB_LOOP
DO_DELAY:MOV   R7, #0b011
		 STR   R7, [R8, #0x8] //this will start the timer
		 LDR   R0, [R8, #0xC]
		 CMP   R0, #0
		 BEQ   DO_DELAY
		 STR   R0, [R8, #0xC]
		 MOV   R7, #0b010
		 STR   R7, [R8, #0x8] //this will stop the timer
		 ADD   R3, #1
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
		 
/* Display R5 on HEX1-0, R6 on HEX3-2 and R7 on HEX5-4 */
DISPLAY: PUSH {R4, R8, R9, LR}
		 LDR R8, =0xFF200020 // base address of HEX3-HEX0
	     MOV R0, R3 // display R5 on HEX1-0
	     BL DIVIDE // ones digit will be in R0; tens
	               // digit in R1
	     MOV R9, R1 // save the tens digit
	     BL SEG7_CODE
	     MOV R4, R0 // save bit code
	     MOV R0, R9 // retrieve the tens digit, get bit
				    // code
		 BL SEG7_CODE
		 LSL R0, #8
		 ORR R4, R0

         STR R4, [R8] // display the number from R 
		 POP {R4, R8, R9, LR}
		 MOV PC, LR
			
DIVIDE:     PUSH {LR}
			MOV R2, #0
CONT:       CMP R0, #10
            BLT DIV_END
            SUB R0, #10
            ADD R2, #1
            B CONT
DIV_END:    MOV R1, R2 // quotient in R1 (remainder in R0)
			POP {LR}
            MOV PC, LR

SEG7_CODE:
		   MOV R1, #BIT_CODES
		   ADD R1, R0 // index into the BIT_CODES "array"
	       LDRB R0, [R1] // load the bit pattern (to be returned)
	       MOV PC, LR
		   
		  		  
BIT_CODES:.byte 0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
		  .byte 0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
          .end        




	
	