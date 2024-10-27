.global _start
_start:  
         LDR   R2, =0xFF200000    

MAIN:    MOV   R3, #BIT_CODES
         LDR   SP, =0x40000000    //stack pointer points to last word in memory
		 //   R6, =6          
		 
LOOP:    //STR   R1, [R2, #0x20]
         LDR   R1, =0xFF200020

		 //Check for key presses
		 
		 LDR   R0, [R2, #0x50]    //reads data register 
		 CMP   R0, #1             //if 1 -> go to KEY0 instructions
		 BLEQ  KEY0 
		 CMP   R0, #2
		 BLEQ  KEY1
		 CMP   R0, #4
		 BLEQ  KEY2
		 CMP   R0, #8
		 BLEQ  KEY3
		 CMP   R0, #8
		 BEQ   WAITX
		 CMP   R0, #0             //Is a key pressed?
		 BEQ   LOOP              //if 0 -> keep checking

WAITX:   MOV   R0, #0
		 LDR   R0, [R2, #0x50]    //if key is being pressed, wait for release 
	     CMP   R0, #0
		 BEQ   WAITX
		 B     KEY0

KEY0:    PUSH  {R4, LR}        //push and pop are for preserving values for the caller function
		 BL    WAIT
		 MOV   R3, #BIT_CODES
		 LDRB  R4, [R3]        //R3 has address of bitcodes, to get actual bitcodes have to laod from that address
	     STR   R4, [R1]
		 POP   {R4, LR}
		 MOV   R0, #0
         MOV   PC, LR
		          
KEY1:    PUSH  {R4, LR}
         BL    WAIT
		 LDRB  R4, [R3]
		 CMP   R4, #0b01100111
		 BEQ   RETURN1
		 LDRB  R4, [R3, #1]!     //! adds one to R3 and updates it
		 STR   R4, [R1] 
		 MOV   R0, #0
		 
RETURN1: POP   {R4, LR}
		 MOV   PC, LR
		 
KEY2:    PUSH  {R4, LR}
         BL    WAIT
		 LDRB  R4, [R3]
		 CMP   R4, #0b00111111
		 BEQ   RETURN2
		 SUB   R3, #1
		 LDRB  R4, [R3]
	     STR   R4, [R1]
		 MOV   R0, #0

RETURN2: POP   {R4, LR}
         MOV   PC, LR

KEY3:    PUSH  {R4, LR}
		 BL    WAIT
		 LDR   R4, =#0b00000000
	     STR   R4, [R1]
		 POP   {R4, LR}
		 MOV   R0, #8
         MOV   PC, LR
		 
WAIT:    LDR   R0, [R2, #0x50]    //if key is being pressed, wait for release 
	     CMP   R0, #0
		 BNE   WAIT
		 MOV   PC, LR


BIT_CODES:.byte 0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
		  .byte 0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
          .end 	