; program 1 of lab 1
; lab1a.asm
; .com

.model tiny

.data
message		db	'ECE4270 LAB1', 0dh, 0ah
mess2		db	'ENTER A CHARACTER FROM KEYBOARD: $'
outmsg		db	0dh, 0ah, 'THE CHARACTER YOU JUST ENTERED IS $'
inchar		db	?
newline		db	0dh, 0ah, '$'

.code
.startup
	lea dx, message
	mov ah, 9
	int 21h
	mov ah, 1
	int 21h
	mov inchar, al
	lea dx, outmsg
	mov ah, 9
	int 21h
	mov dl, inchar
	mov ah, 2
	int 21h
	lea dx, newline
	mov ah, 9
	int 21h

.exit
end