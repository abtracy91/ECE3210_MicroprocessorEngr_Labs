 
; lab6tsr.com
; Alexander Tracy

; link using:
;	tlink /t lab6tsr.obj

; progress:
; main					done
; int63					done
; int64					done
; int65					done

include dos.mac
include bios.mac


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Code Segment ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
code segment
	assume cs:code, ds:code, ss:code
	org 100h
	
	begin:
	jmp initialize
	
	; needed memory data here
	oInt63es		dw		?
	oInt63bx		dw		?
	oInt64es		dw		?
	oInt64bx		dw		?
	oInt65es		dw		?
	oInt65bx		dw		?
	
	; begin resident program here
	
	int63 proc far
		;  clear screen
		
		cmp ah, 1
		je clearScreen
		jmp done_int63
		
		
		clearScreen:
			; preserve previous state
			push ax
			push bx
			push cx
			push dx
			
			mov ah, 07h				; scroll down window
			mov al, 0h				; lines to scroll: 0 => clear screen
			
			mov bh, 07h				; color scheme: black bkg, gray fgnd
			
			mov ch, 0
			mov cl, 0
			mov dl, 4fh
			mov dh, 80h
			
			int 10h
			
			pop dx
			pop cx
			pop bx
			pop ax
		
		done_int63:
		iret
	int63 endp
	
	int64 proc far
		;  draw a rectangle
		
		cmp ah, 03h
		je drawRect
		jmp done_int64
		
		drawRect:
			push ax
			push bx
			push cx
			push dx
			push si
			push di
			
			mov ah, 06h			; function 7
			
			; function 03h
			; 	ah: 03h
			;	al: color code
			;	cx: x coord of start
			;	dx: y coord of start
			;	si: x coord of end
			;	di: y coord of end
			
			; dos int 10h fn 06/07
			;	al: lines to scroll
			;	bh: color code
			;	ch: upper row number		(y start)
			;	cl: left column number		(x start)
			;	dh: lower row number		(y end)
			;	dl: right column number		(x end)
			
			; adjusting coordinates
			
			
			mov bh, al			; sets color code for dos
			mov ch, dl			; mov ystart
								; cl already xstart
			push ax
			mov ax, di
			mov dh, al			; set yend in dh from di
			mov ax, si
			mov dl, al			; set xend in dl from si
			pop ax
			
			mov al, 0
			
			int 10h				; call interrupt
			
			
			
			pop di
			pop si
			pop dx
			pop cx
			pop bx
			pop ax
			
		done_int64:
		iret
	int64 endp
	
	int65 proc far
		;  restore original interrupt vector
		
		mov ah, 25h
		mov al, 63h
		lea dx, oInt63bx
		int 21h
		
		mov ah, 25h
		mov al, 64h
		lea dx, oInt64bx
		int 21h
		
		mov ah, 25h
		mov al, 65h
		lea dx, oInt65bx
		int 21h
		
		
		iret
	int65 endp
	
	; end resident program here
	
	initialize:
	
	assume cs:code, ds:code, ss:code
	
	; save original interrupt vector
	mov ah, 35h
	mov al, 63h
	int 21h
	mov [oInt63es], es
	mov [oInt63bx], bx
	
	mov ah, 35h
	mov al, 64h
	int 21h
	mov [oInt64es], es
	mov [oInt64bx], bx
	
	mov ah, 35h
	mov al, 65h
	int 21h
	mov [oInt65es], es
	mov [oInt65bx], bx
	
	
	; int 21h, 25h function
	; sets the interrupt vector to point to the procedures
	mov ah, 25h					; function 25
	mov al, 63h
	lea dx, int63
	int 21h
	
	mov ah, 25h
	mov al, 64h
	lea dx, int64
	int 21h
	
	mov ah, 25h
	mov al, 65h
	lea dx, int65
	int 21h
	
	
	
	lea dx, initialize							; terminates program, while
	int 27h										; 	keeping it in memory

code ends
end begin
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Code Segment ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;