%define targetFPS               65
%define tempo                   1193182/256/targetFPS

org 100h
s:
	mov al, 0x13        ; initialization code
	int 0x10
	push 0xa000-10 
	pop  es
	mov ax, 0x251c
	mov dl, timer
	int 0x21  

top:
	mov ax, 0xcccd
	mul di              ; di * 0xcccd -> dx:ax

    ; Call effect: load offset into table
	call fx2

    ; Store AL register in ES:[DI] and increase DI.
	stosb
    inc di
    inc di
	jnz top

; setup frequency of timer
	mov al, tempo
	out 40h, al

; read a character from keyboard into AL
	in al,0x60

; return to top of loop if AL != 1
	dec al
	jnz top

    ret

timer:
    ;inc bp
	iret

;
; Chessboard effect
;
fx2:
	xchg dx,ax
	sub ax,bp
	xor al,ah
	or al,0xDB		; limit to 4 posibble colors
	add al,13h
ret
