 
; Lab5.exe
; Alexander Tracy

; progress:
;	runGame						done
;	clearScreen					done
;	drawFields					done
;	makeAsteroid				done
;	random						done
;	drawShip					done
;	scrollField					done
;	updateShipLoc				done
;	delay						done
;	initClock					done
;	endGame						done
;	checkCollision				done
;	updateScore
;	updateLives					done


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
	ascii_score			db		16 dup(' ')
	buffer				db		'$'
	
	; msg data
	msg_start			db		'Use a and d keys to move the ship.', 0dh, 0ah
	cont				db		'Press e to exit game', 0dh, 0ah
	cont2				db		'Press any key to start...', 0dh, 0ah, '$'
	msg_lives			db		'Lives: ', '$'
    msg_score			db		'Score: ', '$'
	
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
		
		; initialize the game
		call startScreen
		call initClock
		call clearScreen
		call drawFields
		
		call runGame
		
		
		done:
		.exit
	main endp
	
	startScreen proc near
		; prints starting message
		
		printString msg_start
		readChar ax
	
		ret
	startScreen endp
	
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
		
		int 65h
		
		mov al, 0h
		mov ah, 4ch
		int 21h
		
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
	
code_seg ends
end main
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Code Segment ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;














