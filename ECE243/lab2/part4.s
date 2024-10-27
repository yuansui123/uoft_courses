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
          BEQ     END
		  
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
