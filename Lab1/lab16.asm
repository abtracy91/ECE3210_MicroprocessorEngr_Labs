; program 1 of lab 1
; lab1a.asm
; .com

.model tiny

.data


.code
.startup
	mov ax, 3202h
	mov bl, al
	mov cx, ax
	mov dl, ch
	int 21h

.exit
end