/* Program that counts consecutive 1's */

          .text                   // executable code follows
          .global _start                  
_start:   MOV     R3, #TEST_NUM   //R3 keeps the address of the word                           
          MOV     R1, #TEST_NUM   // load the data word ...
          LDR     R1, [R1]        // into R1
          MOV     R0, #0          // R0 will hold the result
		  BL      ONES
		  
LOOP:     ADD     R3, #4
		  LDR     R4, [R3]
		  CMP     R4, #0
		  BEQ     END 
		  MOV     R5, R0
		  BL      ONES
		  CMP     R5, R0
		  BGE     LOOP
		  MOV     R5, R0 
		  B       LOOP

END:      B       END   

ONES:     CMP     R1, #0          // loop until the data contains no more 1's
          BEQ     DONE             
          LSR     R2, R1, #1      // perform SHIFT, followed by AND
          AND     R1, R1, R2      
          ADD     R0, #1          // count the string length so far
          B       ONES
DONE:     MOV     PC,LR  

          

TEST_NUM: .word   0x103fe00f, 0x00000005, 0x00000001, 0xffffffff
		  .word   0x00000002, 0x00000003, 0x00000004, 0x00000005
		  .word   0x00000003, 0x00000004, 0x00000005, 0x00000000

          .end                            
