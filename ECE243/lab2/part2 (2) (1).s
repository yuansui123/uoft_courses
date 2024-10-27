/* Program that counts consecutive 1's */

          .text                   // executable code follows
          .global _start                  
_start:   
		  MOV     R3, #TEST_NUM   //holds address
		  MOV     R5, #0          //holds largest data

loop:     LDR     R4, [R3]
		  CMP     R4, #0
		  BEQ     END
		  LDR     R1, [R3]
		  MOV     R0, #0
		  BL      ONES
		  ADD     R3, #4
		  CMP 	  R5, R0
		  BGE 	  loop
	      MOV 	  R5, R0
	      B		  loop
		  
		  

END:      B       END   

ONES:     CMP     R1, #0          // loop until the data contains no more 1's
          BEQ     DONE             
          LSR     R2, R1, #1      // perform SHIFT, followed by AND
          AND     R1, R1, R2      
          ADD     R0, #1          // count the string length so far
          B       ONES
DONE:     MOV     PC,LR  

          

TEST_NUM: .word   0x103fe00f, 0x00000001, 0x00000001, 0x00000001
		  .word   0x00000001, 0x00000001, 0x00000001, 0x00000001
		  .word   0x00000001, 0x00000001, 0xffffffff, 0x00000000

          .end                            
