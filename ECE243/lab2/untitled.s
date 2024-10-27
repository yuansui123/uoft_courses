.global _start
_start:
MLOOP:  LDR  R1, [R4]
		CMP  R1, #0
		BEQ  DISPLAY
		
		MOV  R0, #0
		BL   ONES
		CMP  R5, R0
		MOVLT R5, R0
		
		LDR  R1, [R4]
		MVN  R1, R1
		MOV  R0, #0
		BL   ZEROS
		CMP  R6, R0
		MOVLT R6, R0
		
		LDR  R1, [R4]
		EOR  R1, R1, R3
		MOV  R0, #0
		BL   ALTERNATE
		CMP  R7, R0
		MOVLT R7, R0
		
		ADD  R4, #4
		LDR  R1, [R4]
		B    MLOOP