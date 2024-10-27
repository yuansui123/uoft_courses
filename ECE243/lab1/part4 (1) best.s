/* Program that converts a binary number to decimal */
           
           .text               // executable code follows
           .global _start
_start:
            MOV    R4, #N
            MOV    R5, #Digits  // R5 points to the decimal digits storage location
            LDR    R4, [R4]     // R4 holds N
            MOV    R0, R4       // first parameter for DIVIDE goes in R0
			MOV	   R1, #1000    // second parameter for DIVIDE goes in R1
            BL     DIVIDE
            STRB   R3, [R5, #3] // Thousand digit
			MOV	   R1, #100
            BL     DIVIDE
            STRB   R3, [R5, #2] // Hundred digit
			MOV	   R1, #10
            BL     DIVIDE
            STRB   R3, [R5, #1] // Tens digit
            STRB   R0, [R5]     // Ones digit is in R0
END:        B      END

/* Subroutine to perform the integer division R0 / 10.
 * Returns: quotient in R1, and remainder in R0 */
DIVIDE:     MOV    R2, #0
CONT:       CMP    R0, R1
            BLT    DIV_END
            SUB    R0, R1
            ADD    R2, #1
            B      CONT
DIV_END:    MOV    R3, R2     // quotient in R3 (remainder in R0)
            MOV    PC, LR
			
N:          .word  9876         // the decimal number to be converted
Digits:     .space 4          // storage space for the decimal digits

            .end
