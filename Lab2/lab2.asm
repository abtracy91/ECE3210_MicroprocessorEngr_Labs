; Lab2.exe
; Alexander Tracy

include lab2.mac

stack_seg segment stack
db 100 dup(?)
stack_seg ends

data_seg segment 'data'
	prompt1		db	'Would you like to:', 0dh, 0ah
				db	'a. Play the game?', 0dh, 0ah
				db	'b. See the high scores?', 0dh, 0ah
				db	'c. Access options menu?', 0dh, 0ah
				db	'd. Exit the program?', 0dh, 0ah, '$'
	msg_a 		db	'Haven', 27h, 't made the game yet.', 0dh, 0ah, '$'
	msg_b		db	'Haven', 27h, 't made the file yet.', 0dh, 0ah, '$'
	msg_c		db	'Do you want to: a. edit high scores, b. change color scheme, c. exit submenu?', 0dh, 0ah, '$'
	msg_d		db	'Bye.', 0dh, 0ah, '$'
	msg_error	db	'What?', 0dh, 0ah ,'$'
	newline		db	0dh, 0ah, '$'
	

data_seg ends

code_seg segment para 'code'
	assume cs:code_seg, ds:data_seg, ss: stack_seg
	main proc far
		;initialize the registers
		mov ax, data_seg
		mov ds, ax
		mov ax, stack_seg
		mov ss, ax
		
		
		menu:
			print_str prompt1
			read_char		; reads char into al
			print_str newline
			cmp al, 61h		; compares al to a (61h), b, c, d and redirects the program to the appropriate label.
			je opt_a
			cmp al, 62h	
			je opt_b
			cmp al, 63h		
			je opt_c
			cmp al, 64h		
			je opt_d
			print_str msg_error		; if al is not equal to any of the above comparisons, it is not recognized
			jmp menu				; so the program prints the error message and returns to menu.
			
		opt_a:					; prints msg_a and jumps back to menu.
			print_str msg_a
			jmp menu
		opt_b:					; prints msg_b and jumps back to menu.
			print_str msg_b
			jmp menu
		menu1:					; dummy label to correct for jmp menu below being too far away.
			jmp menu
		opt_c:
			jmp submenu
		opt_d:					; prints msg_d then calls dos to close program.
			print_str msg_d
			mov al, 00h			; al is 00h since there were no erros on close.
			mov ah, 4ch
			int 21h
		submenu:				; prints submenu then compares the input character and redirects the program to the 
			print_str msg_c		; appropriate label.
			read_char
			print_str newline
			cmp al, 'a'
			je submenu_a
			cmp al, 'b'
			je submenu_b
			cmp al, 'c'
			je menu1
			print_str msg_error
			jmp menu
		submenu_a:				; prints msg_b then jumps back to submenu.
			print_str msg_b
			jmp submenu
		submenu_b:				; prints msg_a then jumps back to submenu.
			print_str msg_a
			jmp submenu
	
	.exit
	main endp
code_seg ends
end main








