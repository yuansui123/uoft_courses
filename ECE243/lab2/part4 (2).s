/* Program that counts consecutive 1's, 0's, and alternating pattern */

          .text                   // executable code follows
          .global _start                  
_start:                             
          MOV     R4, #TEST_NUM   // load the data word ...
          MOV     R5, #0          // R5 will hold the result of longest string of 1's
		  MOV     R6, #0          // R6 will hold the result of longest string of 0's
		  MOV     R7, #0          // R7 will hold the result of longest string of alternating 1's and 0's
		  MOV     R3, #XOR_NUM    // loads the number 2730
		  LDR     R3, [R3]
		  
MLOOP:    LDR 	  R1, [R4]        
		  CMP     R1, #0          // loop until the data contains no more 1's
          BEQ     DISPLAY
		  
		  MOV     R0, #0
		  BL      ONES
		  CMP     R5, R0          // Is R0 the new best result?
		  MOVLT   R5, R0          // Save in R5 iff R0>R5 (Move if less than, checks the flags)
		  
		  LDR     R1, [R4]
		  MVN     R1, R1          // Performs a bitwise logical NOT operation on the value and places it into R1 
		  MOV     R0, #0          // reset R0 to search for zeros
		  BL      ZEROS
		  CMP     R6, R0          // Is R0 the new best result?
		  MOVLT   R6, R0          // Save in R6 iff R0>R6 (move if less than, checks the flags)
		  
		  LDR     R1, [R4]
		  EOR     R1, R1, R3      // XOR R1 with "101010101010" to get a number with all 1's in the place of the pattern
		  MOV     R0, #0          // Reset R0 to search for alternating string
		  BL      ALTERNATE
		  CMP     R7, R0          // If R0 the new best result?
		  MOVLT   R7, R0          // Save in R7 iff R0>R7 (move if less than, checks the flags)
		  
		  ADD     R4, #4
		  LDR     R1, [R4]
		  B 	  MLOOP
		  
/* Display R5 on HEX1-0, R6 on HEX3-2 and R7 on HEX5-4 */
DISPLAY: LDR R8, =0xFF200020 // base address of HEX3-HEX0
	     MOV R0, R5 // display R5 on HEX1-0
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

//code for R6
		 MOV R0, R6
		 BL DIVIDE
		 
		 MOV R9, R1
		 BL SEG7_CODE
		 LSL R0, #16
		 ORR R4, R0
		 
		 Mov R0, R9
		 BL SEG7_CODE
		 LSL R0, #24
		 ORR R4, R0
		 
		 STR R4, [R8] // display the numbers from R6 and R5
		 LDR R8, =0xFF200030 // base address of HEX5-HEX4
//code for R7
		 MOV R0, R7
		 BL  DIVIDE
		 
		 MOV R9, R1 // save the tens digit
	     BL SEG7_CODE
	     MOV R4, R0 // save bit code
	     MOV R0, R9 // retrieve the tens digit, get bit
				    // code
		 BL SEG7_CODE
		 LSL R0, #8
		 ORR R4, R0
		 
         STR R4, [R8] // display the number from R
                   
END:      B       END 

ONES:    
		  CMP 	  R1, #0          // Are we done? Has all the ones been shifted out of the word?
		  BEQ     ONESDONE           // We are done with this word, go back to main loop to get next word
		  LSR     R2, R1, #1      // perform SHIFT, followed by AND
          AND     R1, R1, R2      
          ADD     R0, #1          // count the string length so far
          B       ONES            // Keep looping this sub rountine until all the ones have been found in the word
		  
ONESDONE: MOV     PC, LR

ZEROS:    
		  CMP 	  R1, #0          // Are we done? Has all the ones been shifted out of the word?
		  BEQ     ZEROSDONE           // We are done with this word, go back to main loop to get next word
		  LSR     R2, R1, #1      // perform SHIFT, followed by AND
          AND     R1, R1, R2      
          ADD     R0, #1          // count the string length so far
          B       ZEROS            // Keep looping this sub rountine until all the ones have been found in the word
		          


ZEROSDONE:MOV     PC, LR

ALTERNATE:CMP 	  R1, #0          // Are we done? Has all the ones been shifted out of the word?
		  BEQ     ALTERNATED      // We are done with this word, go back to main loop to get next word
		  LSR     R2, R1, #1      // perform SHIFT, followed by AND
          AND     R1, R1, R2      
          ADD     R0, #1          // count the string length so far
          B       ALTERNATE       // Keep looping this sub rountine until all the ones have been found in the word


ALTERNATED:MOV    PC, LR

			
DIVIDE:     MOV R2, #0
CONT:       CMP R0, #10
            BLT DIV_END
            SUB R0, #10
            ADD R2, #1
            B CONT
DIV_END:    MOV R1, R2 // quotient in R1 (remainder in R0)
            MOV PC, LR

SEG7_CODE: MOV R1, #BIT_CODES
		   ADD R1, R0 // index into the BIT_CODES "array"
	       LDRB R0, [R1] // load the bit pattern (to be returned)
	       MOV PC, LR
		   
BIT_CODES:.byte 0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
		  .byte 0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b0110011

XOR_NUM:  .word   0xaaaaaaaa

TEST_NUM: .word   0x00000001
		  .word   0x00000001
		  .word   0x00000001
		  .word   0xb5100001
		  .word   0x00000001
		  .word   0x00000001
		  .word   0x00000001
		  .word   0x00000001
		  .word   0x00000001
		  .word   0x00000001
		  .word   0x00000001
		  .word   0x00000001
		  .word   0x00000000
          .end                            
