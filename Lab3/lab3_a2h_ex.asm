INCLUDE DOS.MAC
STACK_SEG SEGMENT STACK
    DB 100 DUP(?)
STACK_SEG ENDS
DATA_SEG SEGMENT 'DATA'
OUTM1	DB	'THIS PROGRAM USES LAB3_STR AND LAB3_H2A AND THE A2H PROCEDURE',13,10,'ENTER A NUMBER LESS THAN 256: $'
BUFF	DB	4, ?, 4 DUP(?)
OUTNUM	DB	?
OUTASC	DB	4 DUP(?),'$'
ERRORM1	DB	13,10,'ERROR IN!',13,10,'$'
ERRORM2	DB	13,10,'ERROR OUT!',13,10,'$'
TEN	DB	10
ADDR	DW	?
NEWLIN	DB	13,10,'$'

;outnum is the result of the procedure that converts ascii to hex
;it only needs to be 1 byte because decimal numbers less than 256 only need one byte for storage

DATA_SEG ENDS
CODE_SEG SEGMENT PARA 'CODE'
ASSUME CS:CODE_SEG, DS:DATA_SEG, SS:STACK_SEG
MAIN PROC FAR
	PUSH DATA_SEG		;the following lines are the same as in lab3_string.asm
	POP DS
	PUSH STACK_SEG
	POP SS
	PrintS OUTM1	
	GetS BUFF	
	
	LEA BX, BUFF[2]		;preparing for A2H conversion
	LEA DI, OUTNUM
	MOV CH, 0
	MOV CL, BUFF[1]
	CALL A2H
	CMP CX, 00EEH		;check for error
	JE INPUTERROR

	LEA BX, OUTNUM		
	LEA DI, OUTASC
	CALL H2A
	CMP CX, 00EEH		
	JE OUTPUTERROR
	INC DI
	PRINTS NEWLIN
	MOV DX, DI		
	MOV AH, 9
	INT 21H
	
MRET:	RETDOS
INPUTERROR:
	PRINTS ERRORM1
	JMP MRET
OUTPUTERROR:
	PRINTS ERRORM2
	JMP MRET
MAIN ENDP

A2H PROC NEAR ;bx = address of input, di = address of output, cx = number of characters in input, if error then cx = 00EEh
;;;alex
;       starts w/ ax = 0
;       ex:     1234
;           ax + 1      ax = 1
;           ax * 10     ax = 10
;           ax + 2      ax = 12
;           ax * 10     ax = 120
;           ax + 3      ax = 123
;           ax * 10     ax = 1230
;           ax + 4      ax = 1234
;           done
;;;
	PUSH AX			;want to save / clear ax
	XOR AX, AX
ALOOP1:	CMP BYTE PTR[BX], 30H	;check for below 0
	JB AERROR		;if so, go to error
	CMP BYTE PTR[BX], 39H	;check for above 9
	JA AERROR		;if so, go to error
	SUB BYTE PTR[BX], 30H	;ASCII to BCD
	ADD AL, BYTE PTR[BX]	;add BCD to answer. you will need to program your own 24 bit add procedure
	CMP CX, 1		;check for last loop
	JE ARET1		;if so, jump out of loop
	INC BX			;mov to next ASCII number
	MUL TEN			;multiply answer by 10 to allow space for a new one's place. you will need to program your own 24 bit multiplaction procedure
	LOOP ALOOP1		;if cx > 0, go back to ALOOP1
ARET1:	CMP AH, 0
	JA AERROR
	MOV [DI], AL		;store answer
ARET2:	POP AX			;restore ax
	RET			;return
AERROR: MOV CX, 00EEH		;ERROR
	JMP ARET2		;restore ax and return...
A2H ENDP

H2A PROC NEAR
	MOV CX, 0
	ADD DI, 3
	MOV AL, [BX]
HLOOP1:	MOV AH, 0
	DIV TEN	
	MOV [DI], AH
	ADD BYTE PTR[DI], 48
	DEC DI
	CMP AL, 0
	JE HRET
	CMP DI, 65535
	JE HERROR
	JMP HLOOP1
HERROR:	MOV CX, 00EEH
HRET:	RET
H2A ENDP

CODE_SEG ENDS
END MAIN