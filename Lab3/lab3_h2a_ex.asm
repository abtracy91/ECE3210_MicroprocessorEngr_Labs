INCLUDE DOS.MAC
STACK_SEG SEGMENT STACK
    DB 100 DUP(?)
STACK_SEG ENDS
DATA_SEG SEGMENT 'DATA'
OUTM1	DB	'THE PROGRAM HAS STORED THE NUMBER 87H (135d). IT CONVERTS IT TO ASCII AND PRINTS IT OUT. TRY CHANGING THE NUMBER. SEE WHAT HAPPENS.$'
OUTNUM	DB	87H ; = 135 DECIMAL
OUTASC	DB	4 DUP(?),'$'
ERRORM2	DB	13,10,'ERROR OUT!',13,10,'$'
TEN	DB	10
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
	
	LEA BX, OUTNUM		;preparing for H2A conversion
	LEA DI, OUTASC
	CALL H2A
	CMP CX, 00EEH		;check for error
	JE OUTPUTERROR

	PRINTS NEWLIN
	MOV DX, DI		;PRINTS WON'T WORK, ILLEGAL IMMEDIATE...
	MOV AH, 9
	INT 21H
	
MRET:	RETDOS
OUTPUTERROR:
	PRINTS ERRORM2
	JMP MRET
MAIN ENDP

H2A PROC NEAR ;bx = address of input, di = address of output (in this case 3 bytes, in your case 8 bytes needed), di = address of leftmost written bit of output when you return
	MOV CX, 0		;prepare for error handler
	ADD DI, 3		;prepare to write ascii number backwards (ones place then tens place...)
	MOV AL, [BX]		;prepare for div command
HLOOP1:	MOV AH, 0		;prepare for div command
	DIV TEN		;divides AX by TEN, stores quotient in AL, remainder in AH. you will have to write your own 24 bit division algorithm (use 24 bit subtraction. it is easy)
	MOV [DI], AH		;stores the remainder
	ADD BYTE PTR[DI], 48	;converts from BCD to ASCII
	DEC DI			;makes di point to the previous byte (higher radix power)
	CMP AL, 0		;is the quotient 0?
	JE HRET			;if yes, exit loop and return
	CMP DI, 65535		;check for error
	JE HERROR		;if yes jump to error handler
	JMP HLOOP1		;redo loop
HERROR:	MOV CX, 00EEH		;error!
HRET:	INC DI			;undo the last dec di
	RET
H2A ENDP

CODE_SEG ENDS
END MAIN