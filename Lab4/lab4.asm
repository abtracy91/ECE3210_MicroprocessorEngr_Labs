 
; Lab4.exe
; Alexander Tracy

; progress:
;   main
;   read				done
;   display0			done
;	menu				done
;	combine				done
;   sort				done
;	swap				done
;   error				done
;   add_score			done
;   save				done
;	nextItem			done

include lab4.mac

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Stack Segment ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
stack_seg segment stack
    db 500 dup(?)
stack_seg ends
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Stack Segment ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Data Segment ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
data_seg segment 'data'

    ; variables for file ops
	file        		db      'lab4.bin', 0, '$'
    fileHandle  		dw      0
    buffer      		db      255     dup('$')
	
	; storage for linked list in memory
	list				db		400 dup(0)
	next				dw		0
	
	; temp locations for swap
	swap_temp1			dw		0
	swap_temp2			dw		0
	
	; temp locations for sort
	swapped				db		0
	sort_numa			db		8 dup('0')
	sort_numb			db		8 dup('0')
	
	; messages
	msg1				db		'The high scores are:', 0dh, 0ah, '$'
	newline				db		0dh, 0ah, '$'
	tab					db		'     $'
	msg2				db		'Do you want to:', 0dh, 0ah
						db		'a. Add a new score to the list?', 0dh, 0ah
						db		'b. Exit', 0dh, 0ah, '$'
	msg3				db		0dh, 0ah, 'Enter name: $'
	msg4				db		0dh, 0ah, 'Enter score: $'
	
    ; errors
	error2				db		'File Error: file not found.', 0dh, 0ah, '$'
    error4				db		'File Error: too many open files.', 0dh, 0ah, '$'
	error5				db		'File Error: access denied.', 0dh, 0ah, '$'
	error12				db		'File Error: invalid access.', 0dh, 0ah, '$'
	error0				db		'File Error: unknown file error.', 0dh, 0ah, '$'
	
	; temp locations
	test_tl1			db		0aah
	temp_score			db		20 dup('$')
	test_tl2			db		0bbh
	temp_name			db		20 dup('$')
	test_tl3			db		0cch
	temp_combined		db		40 dup('$')

data_seg ends
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Data Segment ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Code Segment ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
code_seg segment para 'code'
	assume cs:code_seg, ds:data_seg, ss:stack_seg
	main proc far
		; main procedure
		
		; initialize the segment registers
		mov ax, data_seg
		mov ds, ax
		mov ax, stack_seg
		mov ss, ax
        
		; read file into memory
		call read
		
		; display the menu
		call menu
		
		; save the file
		call save
		
		;call sort
		
		
        ;call display0
		
		
		done:
		.exit
	main endp
	
    read proc near
    	; reads the score file into memory at list.
		; 	calls error if necessary
	
		; call open file
		;	carry is set if error
		;	ax contains fileHandle or error code
		;	fileHandle is stored in memory in no error
		
		openFile file
		jc errora
		jmp read_read
	
    	errora:							; error has occurred
			cmp ax, 2					; cmp error code to 2
				jne errorb				; error code != 2 -> call error
										; error code == 2 -> file doesnt exit
										;	=> create file
				createFile file
				jc errorb				; error has occurred
				jmp end_read			; file has been created and fileHandle set
	
		errorb:
			call error
		
		read_read:
			; at this point, file has been opened, fileHandle is set
			; read in file to memory at list
			
			readFile fileHandle
			jc errorb
		
		end_read:
			closeFile fileHandle
			ret
    read endp
	
	menu proc near
		; displays the dos menu
		
		menua:
		
		; displays the high scores
		call sort
		call display0
		
		; print menu
		printString msg2
		
		; jumps to code based on choice
		readChar
		cmp al, 'a'
		je addScore
		cmp al, 'A'
		je addScore
		jmp end_menu
		
		addScore:
			; get name and score from input
			printString msg3
			readString temp_name
			printString msg4
			readString temp_score
			
			; combine name and score to one string
			call combine
			
			
			; temp_combined should now be correct
			
			; add temp_combined to list
			lea bx, temp_combined
			call add_score
			
			jmp menua
			

		
		end_menu:
			ret
	menu endp
	
	combine proc near
		; this procedure combines temp_name and temp_score into a single
		; string at temp_combined.
		
		; combine name and score to one string
		
		push ax
		push bx
		push cx
		push dx
		push si
		push di
		
		mov si, 2
		mov di, 2
		mov cx, 0
		
		; put score into temp_combined
		combinea:
			mov dl, temp_score[si]
			cmp dl, 0dh
			je breaka
			mov temp_combined[di], dl
			inc cx
			inc si
			inc di
			jmp combinea
		breaka:
		
		; put a : into temp_combined
		mov temp_combined[di], ':'
		inc di
		inc cx
		
		mov si, 2
		combineb:
			mov dl, temp_name[si]
			cmp dl, 0dh
			je breakb
			mov temp_combined[di], dl
			inc cx
			inc si
			inc di
			jmp combineb
		breakb:
		
		; put a $ into temp_combined just in case
		mov temp_combined[di], '$'
		inc di
		inc cx
		
		; put length of string into temp_combined[0 & 1]
		mov temp_combined[0], cl
		mov temp_combined[1], cl
		

		end_combine:
		
			pop di
			pop si
			pop dx
			pop cx
			pop bx
			pop ax
		
			ret
	combine endp
    
    display0 proc near
    	; displays the contents of the binary file.
		
		; combined string:
		; 1234:Tom  2345:Ben  .
		
		push ax
		push bx
		push cx
		push dx
		push si
		push di
		
		mov cx, 10								; only display the top 10 scores
		
		mov word ptr next, 0					; start at beginning of list
		
		printString msg1
		
		print:
			
			; clear temp_name and temp_score
			push cx
			push di
			mov cx, 10
			mov di, 0
			loopcl:
				mov temp_score[di], '$'
				mov temp_name[di], '$'
				inc di
				loop loopcl
			pop di
			pop cx
		
			call nextItem						; get the next item of the list
			cmp ax, 0							; if ax=0, end of list
			je end_display0
			
			; printString list[bx]
			; split string into name and score, then print it
			mov si, 0
			mov di, 0
			split:
				mov dl, list[bx+si]
				cmp dl, ':'
				je break
				mov temp_score[di], dl
				inc si
				inc di
				jmp split
			break:
			
			inc si
			mov di, 0
			split2:
				mov dl, list[bx+si]
				cmp dl, '$'
				je break2
				mov temp_name[di], dl
				inc si
				inc di
				jmp split2
			break2:
			
			; now we have a split string in temp_score and temp_name
			printString temp_name
			printString tab
			printString temp_score
			printString newline
			
			dec cx
			cmp cx, 0
			je end_display0
			
			jmp print
    	
		
		end_display0:
			pop di
			pop si
			pop dx
			pop cx
			pop bx
			pop ax
		
			ret
    display0 endp
    
    sort proc near
    	; sorts the entries in numerical order.
		
		mov cx, 0
		mov word ptr next, 0				; start at beginning of list
    	
		lb:									; outer loop of bubble sort
		
		inc cl
		cmp cl, 24
		je done_lb_t
		
		
		mov word ptr next, 0
		mov swapped, 0						; swapped starts at 0, becomes 1 when swap
											; occurs
		
		call nextItem_m						; gets next item from list
		cmp ax, 0							; if 0, end of list
		je done_lb_t
		
		la:									; inner loop of bubble sort
		
		push ax
		lea dx, sort_numa					; temporarily stores the score here for
		cleartempvar sort_numa				; comparison
		
		; check for end of list
		push ax
		push bx
		mov bx, ax
		mov ax, word ptr list[bx]
		cmp ax, 0
		je done_lb_t2a
		pop bx
		pop ax
		
		; gets the score of the next person in the list
		call getScore

		; Temporary jump used to prevent
		;	jump out of range errors
		jmp lb_2
		lb_t:
		jmp lb
		lb_2:
		jmp lb_trbc
		done_lb_t:
		jmp done_lb
		done_lb_t2:
		jmp done_lb2
		done_lb_t2a:
		jmp done_lb2a
		lb_trbc:
		
		; gets the next item from the list
		call nextItem_m
		cmp ax, 0									; check for end of list
		je done_la
		push ax
		lea dx, sort_numb
		cleartempvar sort_numb
		
		; check for end of list
		push ax
		push bx
		mov bx, ax
		mov ax, word ptr list[bx]
		cmp ax, 0
		je done_lbr
		pop bx
		pop ax
		call getScore
		
		; sort_numa and sort_numb  are set
		; now do the comparison loop
		
		mov si, 0
		loopdd:
			mov al, sort_numa[si]
			mov bl, sort_numb[si]
			cmp al, bl
			je equal
			jb below
			jmp above
		
		; Temporary jump used to prevent
		; 	jump out of range errors
		jmp lb_trjb
		lb_trja:
		jmp lb
		lb_trjb:
		
		equal:
			inc si
			cmp si, 7			; if si = 8, then sort_numa == sort_numb
			je above			; so don't swap
			jmp loopdd
		below:
			; set ax, bx
			mov swapped, 1
			pop bx
			pop ax
			call swap			; swaps the items of the list
			;mov ax, bx
			jmp lb
			;jmp end_sort
		above:
			; done
			pop bx
			pop ax
			mov ax, bx
			jmp la
			
		done_la:
			pop ax
			mov al, swapped
			cmp al, 0
			jne lb_trja						; if swapped, got to beginning of 2nd loop
			jmp end_sort

		
		done_lb2a:
			pop ax
			jmp end_sort
		done_lbr:
			pop ax
			pop ax
			pop ax
			pop ax
			jmp end_sort
		done_lb2:
			pop bx
			pop ax
		done_lb:
			
		
		; pseudocode
		; next = 0
		; nextItem_m >> a
		; nextItem_m >> b
		; cmp a[i], b[i]
		;	if a[i] == b[i]
		;		inc i
		;		jmp cmp
		;	if a[i] != b[i]
		;		jb swap
		; 
		
		end_sort:
			ret
    sort endp
	
	getScore proc near
		; loads the score from pointer+string ax
		; to memory location dx
		push ax
		push bx
		push cx
		push dx
		push si
		push di
		
		mov bx, ax
		add bx, 2
		; bx points to beginning of first string

		; mov string to temp_numa
		; loop through string to find number of chars before ':'
		mov cx, 0
		mov si, 0
		loops:
			mov al, list[bx+si]
			cmp al, ':'
			je dones
			inc cx
			inc si
			jmp loops
		dones:
			; cx contains number of chars in score

		;	temp_numa[0-7]
		; loop to put string in num
		mov di, 7
		mov si, cx
		loopsb:
			mov al, list[bx+si-1]
			push bx
			mov bx, dx
			mov [bx+di], al
			pop bx
			dec si
			dec di
			cmp si, 0
			je donesb
			jmp loopsb
		donesb:
			; num now contains the score of item ax
			
			pop di
			pop si
			pop dx
			pop cx
			pop bx
			pop ax
			ret
	getScore endp
	
	swap proc near
		; swaps the list entries in ax and bx
		push ax
		push bx
		push cx
		push dx
		
		mov next, 0								; start at beginning of list
		
		mov cx, ax								; stores 1st item in cx
		mov dx, bx								;		2nd in dx
		
		; similar to nextItem, but modified
		traverse:
			mov bx, next							; bx contains next pointer to try
			mov ax, word ptr list[bx]				; mov that ptr to ax
			mov next, ax
			
			cmp ax, cx								; compares current item to item we're
													;	searching for
			je found
			jmp traverse
		
		found:
			; matched the first item we're looking for
			
			mov swap_temp1, ax
			;mov word ptr list[bx], dx
			
		; traverse again
		mov bx, next
		mov ax, word ptr list[bx]
		mov next, ax
		
		mov swap_temp2, ax
		;mov ax, swap_temp1
		;mov word ptr list[bx], cx
		
		; last traverse
		mov bx, next
		mov ax, word ptr list[bx]
		; ax = 20
		mov swap_temp2, ax
		mov next, ax
		
		;mov ax, swap_temp2
		;mov word ptr list[bx], ax
		
		
		; done (?)
		mov next, 0
		
		traverse2:
			mov bx, next
			mov ax, word ptr list[bx]
			mov next, ax
			
			cmp ax, cx
			
			je found2
			jmp traverse2
		found2:
			mov word ptr list[bx], dx		; location 02, put 16
			mov bx, swap_temp1				; 0c -> bx
			mov ax, swap_temp2				; 20 -> ax
			mov word ptr list[bx], ax		; location 0c, put 20
			mov bx, dx						; 16 -> bx
			mov ax, swap_temp1				; 0c -> ax
			mov word ptr list[bx], ax		; location 16, put 0c
			
			
			mov next, 0
		
		
		
		
		end_swap:
			pop dx
			pop cx
			pop bx
			pop ax
			ret
	swap endp

	error proc near
    	; handles file errors.
	
    	cmp ax, 2
    		je mfileNotFound
    	cmp ax, 4
    		je mtooManyOpenFiles
    	cmp ax, 5
    		je maccessDenied
    	cmp ax, 12
    		je minvalidAccess
    	jmp mrandomError
    
    	mfileNotFound:
			printString error2
			jmp mexit
    	mtooManyOpenFiles:
			printString error4
			jmp mexit
    	maccessDenied:
			printString error5
			jmp mexit
    	minvalidAccess:
        	printString error12
			jmp mexit
    	mrandomError:
			printString error0
			jmp mexit
    
    	mexit:
			; after displaying error message, end program
			mov ah, 4ch
			int 21h
    
    		ret
    error endp
	
	nextItem proc near
		; returns:
		;	ax: next pointer
		;	bx: pointer to string
		
		; 	*****  treats head differently;			*****
		;	*****	for printing list only			*****
		;	*****	use nextItem_m for sort/swap	*****
		
		; uses next dw to keep track of which item of the list is next
		
		push cx
		
		mov bx, next				; bx contains the next pointer in list
		
		cmp bx, 0
		je first
		jmp second
		
		first:
			mov ax, word ptr list[bx]		; ax contains head
			push ax
			mov bx, ax						; bx contains head
			mov ax, word ptr list[bx]		; ax contains nextptr
			
			pop bx
			add bx, 2
			; bx points to first character of string
			; ax points to nextptr
			mov next, ax
			jmp end_nextItem
			
			
		second:
			mov ax, word ptr list[bx]		; ax contains nextptr
			;	if ax == 0 last item has been reached
			add bx, 2
			mov next, ax
			
			; bx points to string
			; ax points to nextptr
			
			jmp end_nextItem
		
		end_nextItem:
			pop cx
			ret
	nextItem endp
	
	nextItem_m proc near
		; this procedure is a modified nextItem proc
		; that only returns the next pointer
		; 	for use in swap and sort
		; 	does not skip over head
		
		; returns:
		; 	ax: next pointer
		push bx
		push cx
		
		
		mov bx, next
		mov ax, word ptr list[bx]
		mov next, ax
		
		end_nextItem_m:
			pop cx
			pop bx
			ret
	nextItem_m endp
    
    add_score proc near
    	; adds a new score to the list.
		;	adds the string addressed by bx to list
		
		; adds a string to the list, formatted as a dos string:
		;		maxlength, length, string, '$'
		
		; input data needs to be combined to a single dos string somewhere else
		
		mov cx, 0
		mov cl, [bx+1]		; cx now contains the length of the string
		
		mov ax, word ptr list	; ax now contains the head of the list
		
		cmp ax, 0
		je empty
		jmp not_empty
		
		empty:
			; the list is empty
			mov ax, 02h
			mov word ptr list, ax		; set the head to point to offset 2 of the list
			mov ax, 0h
			mov word ptr list[2], ax	; put 0 in byte 2/3 of list,
										;	showing that entry is the last one

			; put combined string  in list[4+]
			lea ax, list
			push cx
			mov si, 2
			mov di, 4
			loopm:
				; bx addresses the string
				; ax addresses the list
				mov dl, [bx+si]			; moves each item in bx to dl
				
				push bx
				mov bx, ax
				mov [bx+di], dl			; movs each item from dl to ax
				pop bx
				
				inc si
				inc di
				
				loop loopm
				
				
			pop cx
			
			add cx, 4					; not 100% sure of 4, but i think its right
			mov word ptr list[2], cx	; put length of string + 2 into list[2]
			sub cx, 4					; so that length[2] points to the first empty
										; location in array
			
			jmp end_add_score
			
		
		not_empty:
			; list is not currently empty, to add score to end of list
			
			push bx						; stack now has old bx
										; which is location of string
			
			mov bx, word ptr list		; bx now contains head
			
			lr:								; loops through next ptrs
				mov ax, word ptr list[bx]	;	until next == 0
				cmp ax, 0					;	which is the end of the list
				je rrr
				mov bx, ax
				jmp lr
			rrr:
										; at this point,
										;	bx contains the offset of the next ptr
										;	which is 0

			push cx
			add cx, 2
			add cx, bx
			mov word ptr list[bx], cx		; next ptr now set
			
			
			pop cx
			mov ax, bx						; ax has offset of list to add to
			pop bx							; bx now has location of string to add
			
			; put combined string in bx+2 on
			push cx
			mov si, 2
			mov di, 2
			loopn:
				; bx addresses the string
				; ax addresses the list
				mov dl, [bx+si]			; moves each item in bx to dl
				
				push bx
				mov bx, ax
				mov list[bx+di], dl			; movs each item from dl to ax
				pop bx
				
				inc si
				inc di
				
				loop loopn
			
			pop cx
			
			jmp end_add_score
			
		; pseudocode
		;	add a string located in memory to the end of the linked list
		
		; combined string from name and score
		;	score in bcd / hex from last lab
		
		; word ptr list[0]
		;	if == 0, list is empty
		;		put 0002 in list[0] (0/1)
		;		put 0000 in list[2] (2/3)	; next is 0
		;		put combined string in list[4+]
		;		put string length + 2 in list[2] (2/3)
		;			; make list[2] point to first empty byte after string
		;	if != 0,
		;		mov word ptr list[0] into bx
		; 		word ptr list[bx]
		;		if != 0
		;			mov word ptr list[bx] into bx
		;			continue until list[bx] == 0
		;		word ptr list[bx] == 0
		;			put string length + 2 in word ptr list[bx] (0/1)
		;			put combined string in list[bx+2+] (2+)
		
		; each item in list has:
		;	1) score
		;	2) name
		; format:
		;	(ptr to next item)data:name
		;	_2 bytes__________unk:unk
    
    
    	end_add_score:
			ret
    add_score endp
    
    save proc near
		; consolidates the file;
    	; saves the list into the file, in numerical order.
			
		; call open file
		;	carry is set if error
		;	ax contains fileHandle or error code
		;	fileHandle is stored in memory in no error
		
		call sort

		openFile2 file
		jc errord
		jmp write
	    
		errord:							; error has occurred
			cmp ax, 2					; cmp error code to 2
				jne errore				; error code != 2 -> call error
										; error code == 2 -> file doesnt exit
										;	=> create file
				createFile2 file
				jc errore				; error has occurred
				jmp end_read			; file has been created and fileHandle set

		errore:
			call error

		write:
			; at this point, file has been opened, fileHandle is set
			; write the list to file

			writeFile fileHandle
			jc errore

			end_write:
			closeFile fileHandle
			ret
		
		
    
    
    
    save endp
	
code_seg ends
end main
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Code Segment ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;