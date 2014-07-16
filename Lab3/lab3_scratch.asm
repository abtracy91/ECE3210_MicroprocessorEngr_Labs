; Last updated:
; 02/28/2012 2:57 pm

; needed from sample code:
;   24bit division  (using 24bit subtraction) (divide 24bit number by 10)
;   24bit add
;   24bit multiply  (multiply 24bit number by 10)


; mul24
;   usage:
;       

; div24
;   usage:

; add248 (using memory)
;   var db 3 dup(0)
;   usage:
;       *needs var defined in .data*
;       add248
;       

push bx
lea bx, var

; clear registers
mov cx, 0
mov dx, 0

; load var to cl, dx
mov cl, byte ptr[bx]
mov dh, byte ptr[bx+1]
mov dl, byte ptr[bx+2]

pop bx


; lea bx, offset in_bcd
; byte ptr[bx] contains first number in in_bcd

; use cl, dx to store 24 bit number
add dx, byte ptr[bx]
adc cl, 0

; put result in memory at var
push bx

lea bx, var
mov [bx], cl
mov [bx+1], dh
mov [bx+2], dl

pop bx

; end add248

; mul2410

push bx
lea bx, var
mov cl, byte ptr[bx]
mov dh, byte ptr[bx+1]
mod dl, byte ptr[bx+2]
pop bx

; right now, cl, dh, dl contain the 24 bit number
; needs to be multiplied by 10
; proc:
;   shl cl
;   and dh 11110000 >> result
;   shr result, 4
;   add cl, result

; now cl, dh, dl has the 24bit number after being multiplied by 10
; save cl, dh, dl to var

push bx
lea bx, var
mov cl, byte ptr[bx]
mov dh, byte ptr[bx+1]
mov dl, byte ptr[bx+2]
pop bx

; now var in .data has the result

; end mu2410

; sub24
;   usage:

; end sub24

; input 355
; ascii value 33 35 35
; bcd_u value 03 05 05

pack_bcd proc near
    ; takes an unpacked bcd string stored at memory location bx
    ; and converts it to a packed bcd string stored at memory location dx
    
    ; multiplier: 
    ; result:
    ;
    ;
    ; ax:   stores string value
    ; bx:   memory location of input
    ; cx:   counter for loop
    ; dx:   memory location of output, accumulator
    ; di:   multiplier (?)
    
    ;   done before procedure
    ;   lea bx, input
    ;   lea dx, output
    

    mov cx, 0               ; clears cx
    mov cl, [bx+1]          ; movs the length of input into cl
                            ;   which is the number of runs for the loop
    
    mov si, cl              ; now si also has the length of the string,
                            ;   which will count down to 0
    
    mov di, 1               ; sets di to 1, as multiplier

    push dx                 ; puts the location of output on the stack
    mov dx, 0               ;   for now so that dx can be used as accumulator
    
    
    loopd:
        mov ax, [bx+si]     ; ax now has the lsd of string
        
        mul di              ; multiplies ax by di
                            ;   stores result in ax(?)
        
        push ax             ; this block of code will multiply the multiplier
        mov ax, di          ;   by 10
        mul 10
        mov di, ax
        pop ax
        
        
        sub si              ; subtracts 1 from si
        
        ; dx += ax
        add dx, ax          ; adds ax to dx
        
        loop loopd

    
    ; at this point, dx holds the result
    ;       the location of output is on the stack
    ;       the location of input is no longer needed
    
    pop bx                  ; bx now holds the location of output
    
    ; now we need to write the result in dx
    ;   to [bx]      
    
    ret
pack_bcd endp