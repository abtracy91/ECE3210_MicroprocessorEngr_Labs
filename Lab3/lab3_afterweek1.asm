; Lab3.exe

;	current progress:
;		all macros done
;		checknum proc done
;		a2h proc
;		a2bcd
;		add248 done
;		add2424 done
;		sub
;		sub
;		mul
;		div


include lab3.mac

stack_seg segment stack
db 100 dup(?)
stack_seg ends

data_seg segment 'data'
	msg_a			db		00h, 00h, 'ENTER A NUMBER: ', '$'
	msg_b			db		00h, 00h, 'The string you entered is: ', 0dh, 0ah, '$'
	msg_error		db		00h, 00h, 'Error! please enter only numbers. ', 0dh, 0ah, '$'
	in_1			db		255		dup('$')
	in_2			db		255		dup('$')
	in_1_bcd		db		255		dup('$')
	in_2_bcd		db		255		dup('$')
	newline			db		00h, 00h, 0dh, 0ah, '$'
	testa			db		00h, 00h, 'This string is inside checknum.', 0dh, 0ah, '$'
	testb			db		00h, 00h, 'Testb.', 0dh, 0ah, '$'
	testc			db		00h, 00h, 'Both strings are numbers.', 0dh, 0ah, '$'
data_seg ends

code_seg segment para 'code'
	assume cs:code_seg, ds:data_seg, ss:stack_seg
	main proc far
		; initialize the segment registers
		mov ax, data_seg
		mov ds, ax
		mov ax, stack_seg
		mov ss, ax
		
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
		
		; get inputs
		print_str msg_a
		read_str in_1
		print_str newline
		print_str msg_a
		read_str in_2
		print_str newline
		
		; call checknum proc to check if all characters are numbers
		lea bx, in_1
		call checknum
		cmp al, 01h ; after running checknum, if (al == 1) then string is not just numbers.
		je error
		lea bx, in_2
		call checknum
		cmp al, 01h
		je error
		
		; at this point:
		;	all numbers are valid
		; next step:
		;	convert numbers to bcd
		lea bx, in_1
		lea dx, in_1_bcd
		call ascii2bcd
		lea bx, in_2
		lea dx, in_2_bcd
		
		; at this point, both numbers are in bcd
		
		; test add24
		
		
		
		
		
		jmp exit
		error:
			print_str msg_error
		exit:
		.exit
	main endp
	
	checknum proc near
		; checks the string at memory location addressed by bx
		; to make sure all characters are ascii numbers (ascii values 30h<x<39h)
		;	returns:
		; al = 0 if valid
		; al = 1 if invalid
		
		mov si, 1
		mov cx, 0
		mov cl, [bx + si]
		
		loopa:
			inc si
			mov al, [bx+si]
			cmp al, 30h
			jb end_1		; jump below
			
			cmp al, 39h
			ja end_1		; jump above
			
			loop loopa		; continue for each character in string
			
			; if code gets here, it passed
			jmp end_0
		
		
		end_0:
			mov al, 00h
			jmp end_all
		end_1:
			mov al, 01h
			jmp end_all
		end_all:
		ret
	checknum endp
	
	add248 proc near
		; this will take a 24 bit number,
		;	with top 8 bits in al and bottom 16 bits in bx
		; and add it to an 8 bit number in cl
		; result will be stored as a 24 bit number
		; 	with top 8 bits in al, and bottom 16 bits in bx
		; cl will contain the overflow flag
		;	if cl is 01, an overflow occurred
		;	if cl is 00, no overflow occurred
		
		add bx, cx
		adc a1, 0
		jc carry2
		mov cl, 0
		jmp done
		
		carry2:
			mov cl, 1
			jmp done
		
		done:
			ret
	add248 endp
	
	add2424 proc near
		; this will take a 24 bit number, 
		;	with top 8 bits in al and bottom 16 bits in bx
		; and add it to another 24 bit number,
		;	with top 8 bits in cl and bottom 16 bits in dx
		; result will be stored as a 24 bit number
		;	with top 8 bits in al and bottom 16 bits in bx
		; cl will contain the overflow flag
		;	if cl is 01, an overflow occurred
		;	if cl is 00, no overflow occurred
		
		add bx, dx
		adc al, cl
		jc carrya
		mov cl, 00
		jmp done
		
		carrya:
			mov cl, 01
			jmp done
		
		done:
			ret
	add2424 endp
	
	sub248 proc near
		; this proc will take a 24 bit number, with top 8 bits in al
		;	and bottom 16 bits in bx
		; and subtract from it an 8 bit number stored in cl
		; result will be stored in al(8) and bx(16).
		; sign flag will be stored in cl
		;	if cl is 00, result is non-negative
		;	if cl is 01, result is negative
		
		; psc
		; 
		; sub bx, cx
		; if (-)
		;	dec al
		;	
		;	....
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		done:
			ret
	sub248 endp
	
	ascii2bcd proc near
		; converts the string at memory location addressed by bx
		; to bcd string stored at memory location addressed by dx
		
		mov si, 1
		mov cx, 0
		mov cl, [bx+si]
		
		loopb:
			inc si
			mov al, [bx+si]
			
			sub al, 30h		; subtract 30 from al to get bcd
			
			push bx
			mov bx, dx
			
			mov [bx+si], cl
			pop bx
			
			loop loopb
		
		
		
		ret
	ascii2bcd endp
	
	
	a2h proc near
		; converts an ascii number to a hex number
		
		ret
	a2h endp
code_seg ends
end main