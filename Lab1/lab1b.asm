; program 2 of lab 1
; lab1b.asm
; .exe

stack_seg segment stack
db 100 dup(?)
stack_seg ends

data_seg segment 'DATA'
message		db	'ECE4270 LAB1', 0dh, 0ah
mess2		db	'ENTER A CHARACTER FROM KEYBOARD: $'
outmsg		db	0dh, 0ah, 'THE CHARACTER YOU JUST ENTERED IS $'
inchar		db	?
newline		db	0dh, 0ah, '$'
data_seg ends

code_seg segment para 'CODE'
assume cs:code_seg, ds:data_seg, ss:stack_seg
main proc far
	mov ax, data_seg
	mov ds, ax
	mov ax, stack_seg
	mov ss, ax

	lea dx, message ; print message
	mov ah, 9
	int 21h
	mov ah, 1
	int 21h
	mov inchar, al
	lea dx, outmsg  ; print message
	mov ah, 9
	int 21h
	mov dl, inchar  ; output a char to screen
	mov ah, 2
int 21h
	mov dx, offset newline
	mov ah, 9
	int 21h

.exit
main endp
code_seg ends
end main















	