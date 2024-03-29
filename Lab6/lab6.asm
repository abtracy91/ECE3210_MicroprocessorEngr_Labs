 
; Lab6.exe
; Alexander Tracy


;
;1) Clear screen. 
;2) Display the game field and the score on the top right corner of the screen. 
;3) Start the game by dropping multiple asteroids from a random column. 
;4) The space ship, controlled by mouse location, can move horizontally to dodge 
;		asteroids. 
;5) If the player is hit by an asteroid, the space ship loses one of 3 life points. 
;6) Game would stop when you get hit 3 times. 
;7) After the game ends it should go back to the game menu. In the next lab we will add 
;		high score functionality here.  ) Before exiting, the game should: 
;	a) Clear the screen, 
;	b) Restore the original interrupt vector table and return to DOS. 
;	9) All BIOS function calls (macros) must be included in a macro, BIOS.MAC, while the 
;		DOS function calls (macros) must be included in DOS.MAC.
;


;;;					Custom Interrupts				;;;
;	int 63:			clear screen
;	int 64:			draw rectangle
;	int 65:			restore original interrupt vector
;;;					End								;;;

include dos.mac
include bios.mac

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Stack Segment ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
stack_seg segment stack
    db 100 dup(?)
stack_seg ends
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Stack Segment ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Data Segment ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
data_seg segment 'data'
	; color data
	scoreBColor			db		40h
	asteroidFColor		db		33h
	asteroidBColor		db		00h
	shipFColor			db		77h
	shipBColor			db		00h
	
	; ship data
	shiploc				dw		0002h
	ship_width			dw		4h
	
	; clock data
	clocka				dw		0h
	clockb				dw		0h
	
	; random number generation data
	rand_a				dw		1337h
	rand_c				dw		3210h
	rand_s				dw		4h
	
	; score data
	lives				dw		3h
	score				dw		0h
	ascii_score			db		16 dup(' '), '$'
	
	; msg data
	msg_start			db		'Use a and d keys to move the ship.', 0dh, 0ah
	cont				db		'Press e to exit game', 0dh, 0ah
	cont2				db		'Press any key to continuea...', 0dh, 0ah, '$'
	msg_lives			db		'Lives: ', '$'
    msg_score			db		'Score: ', '$'
	
	; menu data
	newline				db	0dh, 0ah, '$'
	prompt				db	'Would you like to:', 0dh, 0ah
						db	'a. Play the game?', 0dh, 0ah
						db	'b. See the high scores?', 0dh, 0ah
						db	'c. Exit the program?', 0dh, 0ah, '$'
	msg_a				db	'Starting game...', 0dh, 0ah, '$'
	msg_exit			db	'Exiting game...', 0dh, 0ah, '$'
	enterName			db	'Enter your name: ', 0dh, 0ah, '$'
	
	; high scores data
	; variables for file ops
	file        		db      'lab6.bin', 0, '$'
    fileHandle  		dw      0
    buffer      		db      255     dup('$')
	
	msg1				db		'The high scores are:', 0dh, 0ah, '$'
	tab					db		'     $'
	
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
	
	; temp locations for high scores
	test_tl1			db		0aah
	temp_score			db		20 dup('$')
	test_tl2			db		0bbh
	temp_name			db		20 dup('$')
	test_tl3			db		0cch
	temp_combined		db		40 dup('$')
	
	; errors for high scores
	error2				db		'File Error: file not found.', 0dh, 0ah, '$'
    error4				db		'File Error: too many open files.', 0dh, 0ah, '$'
	error5				db		'File Error: access denied.', 0dh, 0ah, '$'
	error12				db		'File Error: invalid access.', 0dh, 0ah, '$'
	error0				db		'File Error: unknown file error.', 0dh, 0ah, '$'
	
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
		
		call read
		
		call menu
		
		;call save
		
		
		
		done:
		.exit
	main endp
	
	menu proc near
		; starting menu for the game.
		
		menu_l:
			call clearScreen
			setCursor 0,0
			setCursor 0,0
			printString prompt			; displays the menu prompt
			readChar					; reads choice to al
			cmp al, 'a'
			je playGame
			cmp al, 'b'
			je highScores
			cmp al, 'c'
			je exitGame
			printString newline
			jmp menu_l
		
		playGame:
			printString newline
			printString msg_a
			call startGame
			jmp menu_l
		highScores:
			printString newline
			call sort
			call display0
			printString cont2
			readChar
			printString newline
			jmp menu_l
		exitGame:
			printString newline
			printString msg_exit
			call save
			
			int 65h			; restore original interrupt vector
			
			mov al, 0h
			mov ah, 4ch
			int 21h
		
		
		ret
	menu endp
	
	startScreen proc near
		; prints starting message
		
		printString msg_start
		readChar ax
	
		ret
	startScreen endp
	
	startGame proc near
		; initializes and starts the game.
		
		push ax
		push cx
		push si
		mov ax, 3
		mov lives, ax
		mov ax, 0
		mov score, ax
		mov al, ' '
		mov cx, 15d
		mov si, 0
		loopef:
			mov ascii_score[si], al
			inc si
			loop loopef
		
		pop si
		pop cx
		pop ax
		
		; initialize the game
		call startScreen
		call initClock
		call clearScreen
		call drawFields
		
		; run the game
		call runGame
		
		ret
	startGame endp
	
	addHighScore proc near
		; after game exits, prompts user for name, then adds score to list.
		
		printString enterName
		readString temp_name
		
		call combine
		
		lea bx, temp_combined
		call add_score
		
		call clearScreen
		setCursor 0,0
		
		
		ret
	addHighScore endp
	
	runGame proc near
		; runs the game
		
		loopgame:
			call makeAsteroid
			call scrollField
			call updateShipLoc
			call drawShip
			call checkCollision
			call updateScore
			call updateLives
			call delay
			jmp loopgame
		
		ret
	runGame endp
	
	clearScreen proc near
		; clears the screen using int 63
		
		push ax
		mov ah, 1
		int 63h
		pop ax
		
		ret
	clearScreen endp
	
	drawFields proc near
		; draw the score, asteroid, and ship fields.
		
		; score from 0 - 0
		; asteroids from 1 - x
		; ship from x - x
		
		push ax
		push cx
		push dx
		push si
		push di
		
		mov ah, 03h								; score field
		mov al, scoreBColor
		mov cx, 0h
		mov dx, 0h
		mov si, 4fh
		mov di, 0h
		int 64h
		
		mov ah, 03h								; asteroid field
		mov al, asteroidBColor
		mov cx, 0h
		mov dx, 1h
		mov si, 4fh
		mov di, 17h
		int 64h
		
		mov ah, 03h								; ship field
		mov al, shipBColor
		mov cx, 0h
		mov dx, 18h
		mov si, 4fh
		mov di, 18h
		int 64h
		
		pop di
		pop si
		pop dx
		pop cx
		pop ax
	
		ret
	drawFields endp
	
	makeAsteroid proc near
		; draw an asteroid at a random x value along top of asteroid field
		
		push ax
		push cx
		push dx
		push si
		push di
		
		call random
		
		; cx random x starting location
		mov ah, 03h
		mov al, asteroidFColor
		; cx contains random start
		mov dx, 1h
		mov si, cx
		add si, 0
		mov di, 1h
		int 64h
		
		pop di
		pop si
		pop dx
		pop cx
		pop ax

		ret
	makeAsteroid endp
	
	random proc near
		; puts a random number in the 0 - 4eh range into cx
		
		; uses linear congruential generator algorithm to generate a random number
		
		push ax
		push bx
		push dx
		
		mov ax, rand_s
		mov cx, rand_a
		mov bx, rand_c
		
		mul cx
		add ax, bx
		mov rand_s, ax
		
		ror ax, 4
		
		sub dx, dx
		mov bx, 4eh
		div bx
		mov cx, dx
		
		pop dx
		pop bx
		pop ax
		
		ret
	random endp
	
	drawShip proc near
		; clears ship field and draws the ship at shiploc
		
		push ax
		push cx
		push dx
		push si
		push di
		
		mov ah, 03h						; clears ship field
		mov al, shipBColor
		mov cx, 0h
		mov dx, 18h
		mov si, 4fh
		mov di, 18h
		int 64h
		
		mov ah, 03h						; draws ship
		mov al, shipFColor
		mov cx, shiploc
		mov dx, 18h
		mov si, cx
		add si, ship_width
		mov di, 18h
		int 64h
		
		pop di
		pop si
		pop dx
		pop cx
		pop ax
		
		ret
	drawShip endp
	
	scrollField proc near
		; scrolls the asteroid field by 1 line
		
		push ax
		push bx
		push cx
		push dx
		
		mov ah, 07h
		mov al, 1h
		mov bh, asteroidBColor	; color code
		mov ch, 1h				; upper y
		mov cl, 0h				; left x
		mov dh, 17h				; lower y
		mov dl, 4fh				; right x
		
		int 10h
		
		pop dx
		pop cx
		pop bx
		pop ax
		
		ret
	scrollField endp
	
	updateShipLoc proc near
		; updates the location of the ship based on keyboard input
		;  then redraws ship
		
		push ax
		push cx
		push dx
		
		mov cx, shiploc
		
		
		mov ah, 01h
		int 16h
		jz end_updateShipLoc					; zero if no keys in buffer
		cmp al, 'a'
		je move_left
		cmp al, 'd'
		je move_right
		cmp al, 'e'
		je finish
		jmp end_updateShipLoc
		
		move_left:								; moves the ship left 1 location
			cmp cx, 0
			je end_updateShipLoc
			sub cx, 1
			mov shiploc, cx
			jmp end_updateShipLoc
			
		move_right:								; moves the ship right 1 location
			mov dx, cx
			add dx, ship_width
			cmp dx, 4eh
			jg end_updateShipLoc
			inc cx
			mov shiploc, cx
			jmp end_updateShipLoc
			
		finish:
			; clear keyboard buffer
			mov ah, 1h
			int 16h
			jz end_endGame
			mov ah, 0h
			int 16h
			jmp finish
		end_endGame:
			call endGame

		
		end_updateShipLoc:
		; clear keyboard buffer
		mov ah, 1h
		int 16h					; check for keys in buffer
		jz end_end
		mov ah, 0h
		int 16h
		jmp end_updateShipLoc
		
		end_end:
		
		pop dx
		pop cx
		pop ax
		
		ret
	updateShipLoc endp
	
	delay proc near
		; delays game
		
		push ax
		push cx
		push dx
		
		continue:					; checks if the tick clock has changed
			mov ah, 0h
			int 1ah
			
			cmp cx, clocka
			jne done_delay
			
			push dx
			sub dx, clockb
			cmp dx, 1h
			pop dx
			jg done_delay
			jmp continue
			
		done_delay:					; enough time has passed
			mov clocka, cx
			mov clockb, dx
		
		pop dx
		pop cx
		pop ax
		
		ret
	delay endp
	
	initClock proc near
		; sets the clock variable to current time
		
		push ax
		push cx
		push dx
		
		mov ah, 0
		int 1ah
		
		mov clocka, cx
		mov clockb, dx
		
		pop dx
		pop cx
		pop ax
		
		ret
	initClock endp
	
	endGame proc near
		; code to close the game
		
		call clearScreen
		setCursor 0,0
		
		; uncomment for final version
		;int 65h
		
		call addHighScore
		
		call menu
		
		;mov al, 0h
		;mov ah, 4ch
		;int 21h
		
		ret
	endGame endp
	
	checkCollision proc near
		; checks for a collision with the ship and changes score and lives accordingly.
		
		; loop start at shiploc end at shiploc + shipwidth
		; 	set cursor position at shiploc + i
		;	int 10h, 06h
		;		ah contains color code
		;		if color == asteroidFColor, lives --
		;		set flag
		;
		; if not flag
		;	score ++
		; flag = 0
		
		mov bx, 0h
		mov dx, shiploc
		mov cx, dx
		add cx, ship_width
		add cx, 1
		
		loopa:
			mov ah, 02h
			mov dh, 17h
			; dl set at shiploc
			int 10h					; set cursor location
			
			mov ah, 08h
			int 10h					; get character attributes
			
			; ah contains color
			cmp ah, asteroidFColor
			je hit
			jmp not_hit
			
		hit:								; an asteroid is directely above ship
			mov ax, lives
			dec ax
			mov lives, ax
			cmp ax, 0
			je finish_game					; out of lives, so finish game
			jmp end_checkCollision
			
		not_hit:
			jmp finish_loop
			
		finish_loop:
			inc dx
			cmp dl, cl
			je end_checkCollision
			jmp loopa
		
		finish_game:
			call endGame
		
		end_checkCollision:					; collision has not occurred. inc score
			mov ax, score
			inc ax
			mov score, ax
		
		ret
	checkCollision endp
	
	updateScore proc near
		; updates the score on screen
		
		setCursor 30h, 0h
		printString msg_score
		
		; converts score to ascii to be displayed
		mov al, 0
		mov bx, score
		lea di, ascii_score
		
		call hex2ascii
		
		printString ascii_score
		
		
		
		ret
	updateScore endp
	
	updateLives proc near
		; updates the number of lives on screen
		
		setCursor 1h, 0h
		printString msg_lives
		
		mov dx, lives
		add dl, 30h
		printChar dl
		
		ret
	updateLives endp
	
	hex2ascii proc near
		; from lab3
		
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
	
	div248 proc
		; from lab3
		
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
	
	sub248 proc near
		; from lab3
		
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
	
	read proc near
		; from lab4
		
    	; reads the score file into memory at list.
		; 	calls error if necessary
	
		; call open file
		;	carry is set if error
		;	ax contains fileHandle or error code
		;	fileHandle is stored in memory in no error
		
		openFile file
		jc errora
		jmp read_read
	
    	errora:
										; error has occurred
			cmp ax, 2					; cmp error code to 2
				jne errorb				; error code != 2 -> call error
										; error code == 2 -> file doesnt exit
										;	=> create file
				
				
				createFile file
				jc errorb				; error has occurred
				;jmp end_read			; file has been created and fileHandle set
				jmp end_read
	
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
	
	error proc near
		; from lab4
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
	
	sort proc near
		; from lab4
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
	
	nextItem_m proc near
		; from lab4
		
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
	
	getScore proc near
		; from lab4
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
		; from lab4
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
	
	display0 proc near
		; from lab4
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
	
	nextItem proc near
		; from lab4
		
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
	
	combine proc near
		; from lab4
		; this procedure combines temp_name and temp_score into a single
		; string at temp_combined.
		
		; combine name and score to one string
		
		push ax
		push bx
		push cx
		push dx
		push si
		push di
		
		mov si, 0
		mov di, 2
		mov cx, 0
		
		
		; put score into temp_combined
		combinea:
			mov dl, ascii_score[si]
			cmp dl, ' '
			je space
			;cmp dl, 0dh
			cmp dl, '$'
			je breaka
			mov temp_combined[di], dl
			inc cx
			inc si
			inc di
			jmp combinea
		space:
			inc si
			jmp combinea
			
		breaka:
		
		; put score into temp_combined
		;combinea:
		;	mov dx, score
		;	mov temp_combined[di], dh
		;	inc di
		;	mov temp_combined[di], dl
		;	inc cx
		;	inc cx
			
		
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
	
	add_score proc near
		; from lab4
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














