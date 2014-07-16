; Lab3.exe
; Alexander Tracy

include lab3.mac

stack_seg segment stack
	db 100 dup(?)
stack_seg ends

data_seg segment 'data'
	msg_a			db		00h, 00h, 'ENTER A NUMBER: ', '$'
	msg_b			db		00h, 00h, 'The string you entered is: ', 0dh, 0ah, '$'
	msg_c			db		00h, 00h, 'Result: $'
	msg_error		db		00h, 00h, 'Error! please enter only numbers. ', 0dh, 0ah, '$'
	in_1			db		10h, 11 		dup('$')
	in_2			db		10h, 11 		dup('$')
	in_1_bcd		db		10h, 11 		dup('$')
	in_2_bcd		db		10h, 11 		dup('$')
	in_1_hex		db		10h, 11 		dup('$')
	in_2_hex		db		10h, 11 		dup('$')
	result_hex		db		10h, 11			dup('$')
	result_ascii	db		16			dup(' ')
	newline			db		00h, 00h, 0dh, 0ah, '$'
	carry_error		db		00h, 00h, 'With carry', 0dh, 0ah, '$'
data_seg ends

code_seg segment para 'code'
	assume cs:code_seg, ds:data_seg, ss:stack_seg
	main proc far
		; initialize the segment registers
		mov ax, data_seg
		mov ds, ax
		mov ax, stack_seg
		mov ss, ax		
		
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
		je error_dd
		lea bx, in_2
		call checknum
		cmp al, 01h
		je error_dd
		
		; at this point:
		;	all numbers are valid
		; next step:
		;	convert numbers to bcd
		lea bx, in_1
		lea dx, in_1_bcd
		call ascii2bcd
		lea bx, in_2
		lea dx, in_2_bcd
		call ascii2bcd
		
		; at this point, both numbers are in bcd
		
		lea bx, in_1_bcd
		lea dx, in_1_hex
		call bcd2hex
		lea bx, in_2_bcd
		lea dx, in_2_hex
		call bcd2hex
		
		; this block of code is a jump redirect to prevent jump too far errors.
		; temp jump loc for error
		jmp continue
		error_dd:
			jmp error
		continue:
		; end temp jump loc
		
		; at this point, both numbers are in hex
		; this block of code loads the first hex number into the 24 bits at al,dx
		lea bx, in_1_hex
		mov ah, 0
		mov al, [bx]
		mov dh, [bx+1]
		mov dl, [bx+2]
		push ax
		push dx
		
		; this block of code loads the address of the second hex number into bx
		lea bx, in_2_hex
		mov al, [bx]
		mov dh, [bx+1]
		mov dl, [bx+2]
		mov cl, al
		; the second number is currently in the 24 bits at cl,dx
		pop bx
		pop ax
		; now al, bx contains the 1st 24bit hex number
		
		; now call the add2424 procedure to add the two numbers together
		call add2424
		; al, bx contains result
		cmp cl, 01h ; check for carry
		je carry_e
		mov dx, bx
		; al, dx contains result
		lea bx, result_hex
		mov [bx], al
		mov [bx+1], dh
		mov [bx+2], dl
		; result_hex now contains the hex value of the result
		
		; now just need to convert result_hex to result_ascii
		; and print it out
		
		; load result_hex
		lea bx, result_hex
		mov al, [bx]
		mov dh, [bx+1]
		mov dl, [bx+2]
		mov bx, dx
		; al, bx now contains result_hex
		lea di, result_ascii
		; di contains memory address of result_ascii
		
		call hex2ascii
		
		; result now in result_ascii
		
		print_str msg_c
		print_str_2 result_ascii
		
		
		
		jmp exit
		carry_e:
			print_str carry_error
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
		
		loopa:					; loops through each value of the string at bx, and checks to make sure each number is between 30 and 39.
								;  sets error flag if any of the numbers is outside that range.
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
		
		add bx, cx	; adds the least significant 16 bits
		adc al, 0	; if there is a carry, al (most significant 8 bits) needs to be incremented by one.
		jc carry2	; if there is a carry from the al addition, the number is too big to fit in 24 bits, set carry flag.
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
		
		add bx, dx	; adds the least significant 16 bits
		adc al, cl	; adds the most significant 8 bits, plus the carry flag
		jc carrya
		mov cl, 00	; since there is no carry from the al,cl addition, sets carry flag to zero.
		jmp done_add2424
		
		carrya:
			mov cl, 01	; sets carry flag to 1
			jmp done_add2424
		
		done_add2424:
			ret
	add2424 endp
	
	mul248 proc near
		; takes a 24 bit number, al, bx
		; and multiplies it by cl
		
		mov ah, al
		mov dx, bx
		mov al, 0
		mov bx, 0
		
		
		looprd:		; each pass of the loop will add the original number to the result one more time.
			; al, bx
			; ah, dx
			; ======
			; al, bx
			; each pass al bx will get bigger
			push cx
			
			mov cx, 0
			mov cl, ah
			call add2424
			
			pop cx
			loop looprd
		
		; at this point the multiplication is done
		; result in al, bx
		
		
		mov ah, 0
		
		ret
	mul248 endp
	
	sub2424 proc near
		; al, bx - cl, dx >> al, bx; cl overflow flag
		
		sub bx, dx	; subtracts the least significant 16 bits
		sbb al, cl	; subtracts the most significant 8 bits, plus the borrow(carry) flag
		jc carry_s	; if there is a carry here, set the carry flag to 1 and exit
		mov cl, 0	; since there is no carry here, set the carry flag to 0 and exit
		jmp done_sub2424
		
		carry_s:
			mov cl, 01
			jmp done_sub2424
		adc ah, 0
		done_sub2424:
			ret
	sub2424 endp
	
	sub248 proc near
		; al, bx - cl >> al, bx; cl overflow
		; takes al,bx (24 bit) and subtracts from it cl (8 bit),
		;   and stores the result back in al,bx (24 bit), with cl as the overflow flag.
		
		push dx	; dx, si used temporarily
		push si

		mov dx, bx
		mov si, ax
		
		mov ch, 0
		
		sub bx, cx		; subtracts the least significant 16 bits
		sbb al, 0		; if there is a borrow, subtract 1 from al
		jc carry_2		; sets the carry flag and exits
		mov cl, 0		; clears the carry flag and exits
		jmp done_sub248
		
		carry_2:
			mov cl, 1	; mov 1 into carry register to indicate an overflow/borrow result
			mov bx, dx
			mov ax, si

			jmp done_sub248
		
		done_sub248:
			pop si
			pop dx
		
			ret
	sub248 endp
	
	div248 proc
		; al, bx / cl >> al, bx; remainder cl
		
		mov ah, 0
		mov dx, 0	; ah dx to store result
		
		loopr:
			push cx
			call sub248
			cmp cl, 0	; if cl is 0, result was nonnegative, so continue looping
			jne theta	; if cl is 1, result was negative, so exit loop
			
			pop cx
			incahdx		; macro that increments the 24bit register ah, dx
						; 	which stores the number of times the subtraction has happened
			jmp loopr
		
		theta:
			; al, bx < cl
			; -> al = 0
			; bx < cl
			; bx contains remainder
			
			pop cx	; get rid of cx.. not needed
			mov cx, 0
			
			mov cl, bl
			; cl now contains remainder
			mov bx, dx
			; bx now contains bottom part of result
			mov al, ah
			; al now contains top part of result
			
		
		ret
	div248 endp
	
	hex2ascii proc near
		; converts 24 bit hex number in al, bx
		; to a bcd string at memory location di
		
		mov cx, 0
		add di, 8
		
		hloop1:
			mov cl, 0ah
			; al, bx contains 24bit number, cl contains ah
			call div248
			; al, bx reduced number, cl remainder
			mov [di], cl
			add byte ptr[di], 30h
			dec di
			; cmp albx, 0
			cmp al, 0
			je step2
			jmp tdone
			step2:
				cmp bx, 0
				je h2a_done
				jmp tdone
			tdone:
			;je h2a_done
			cmp di, 65535	; check for error
			je herror
			jmp hloop1
		
		herror:
			mov cx, 00eeh

		h2a_done:
			;inc di

			ret
	hex2ascii endp
	
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
			
			mov [bx+si], al
			pop bx
			
			loop loopb
		
		; si should hold the size of the bcd string
		;  put that into the first/2nd byte of dx
		push bx
		push cx
		mov bx, dx
		mov cx, si
		dec cx
		mov si, 1
		mov [bx+si], cl
		pop cx
		pop bx
		
		ret
	ascii2bcd endp

	errorc:
		jmp error
	
	bcd2hex proc near
		; converts the bcd string at memory location addressed by bx
		; to a 24bit hex number stored at memory location addressed by dx
		mov di, dx
		
		; temporarily store 24 bit result
		; in al, dx
		mov ax, 0
		mov dx, 0
		
		mov si, 1
		mov cx, 0
		mov cl, [bx+si]
		
		loopdd:
			inc si
			
			push cx
			push bx
			
			mov cl, [bx+si]
			mov bx, dx
			; al, bx
			; +	  cl
			; >> al, bx
			call add248
			; now result is in al, bx
			mov dx, bx
			; now result is in al, dx
			
			pop bx
			pop cx
			
			cmp cx, 1
			je outofloop
			;inc bx
			push bx
			push cx
			
			; top 8 in al
			mov bx, dx
			; bottom 16 in bx
			mov cx, 0
			mov cl, 0ah
			; mul (al, bx) by cl(10(0xa))
			call mul248
			
			pop cx
			mov dx, bx
			; result now in al, dx
			pop bx

			loop loopdd
		outofloop:
			cmp ah, 0
			ja errorc
			
			mov cx, dx
			; result in al, cx
			
			mov [di], al
			mov [di+1], ch
			mov [di+2], cl
			
		
		ret
	bcd2hex endp
	
	
	a2h proc near
		; converts an ascii number to a hex number
		
		ret
	a2h endp
code_seg ends
end main