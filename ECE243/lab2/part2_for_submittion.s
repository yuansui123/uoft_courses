/* Program that counts consecutive 1's */

          .text                   // executable code follows
          .global _start                  
_start:                             
          MOV     R4, #TEST_NUM   // load the data word ...
          MOV     R5, #0          // R5 will hold the result
		  
MLOOP:    LDR 	  R1, [R4], #4    // After loading R1 with R4, get next data for next iteration
		  CMP     R1, #0          // loop until the data contains no more 1's
          BEQ     END
		  MOV     R0, #0
		  BL      ONES
		  CMP     R5, R0          // Is R0 the new best result?
		  MOVLT   R5, R0          // Save in R5 iff R0>R5 (Move if less than, checks the flags)
		  B 	  MLOOP
                   
END:      B       END 

ONES:    
		  CMP 	  R1, #0          // Are we done? Has all the ones been shifted out of the word?
		  BEQ     ONESDONE           // We are done with this word, go back to main loop to get next word
		  LSR     R2, R1, #1      // perform SHIFT, followed by AND
          AND     R1, R1, R2      
          ADD     R0, #1          // count the string length so far
          B       ONES            // Keep looping this sub rountine until all the ones have been found in the word
		  
ONESDONE: MOV PC, LR

TEST_NUM: .word   0x00000001
		  .word   0x000003FF
		  .word   0x00000001
		  .word   0x103fe00f
		  .word   0x00000001
		  .word   0x00000006
		  .word   0x00000001
		  .word   0x00000007
		  .word   0x00000001
		  .word   0x00000009
		  .word   0x00000000
          .end                            
