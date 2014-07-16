## immediately after initialization

; sets byte 1 of in_1 to ff as size of available string
		; for dos interrupts
		lea dx, in_1
		mov ax, 00ffh
		mov in_1, al
		lea dx, in_2
		mov ax, 00ffh
		mov in_2, al
		lea dx, in_1_bcd
		mov in_1_bcd, al
		mov in_2_bcd, al
		
## from macro file
print_char macro msg
	; prints the character mychar
	
	push ax
	push dx
	
	; 02h : dos interrupt to print char
	mov ah, 02h
	mov dl, msg
	int 21h
	
	pop dx
	pop ax
endm

read_char macro 
	; read in a character from keyboard and stores
	; it in al register.
	
	mov ah, 01h
	int 21h
endm



getS macro mystring
	; reads in a string and stores it in memory at location mystring.
	
	push ax
	push dx
	
	; 0Ch : flush buffer and read standard input
	; 0Ah : buffered input
	mov ah, 0ah
	lea dx, mystring
	int 21h
	
	pop dx
	pop ax
endm



printS macro mystring
	; prints the msg string to output.

	push ax
	push dx
	
	; 09 h : dos interrupt to print string
	mov ah, 09h 
	lea dx, msg
	int 21h
	
	pop dx
	pop ax
endm