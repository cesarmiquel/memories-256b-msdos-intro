; "memories" by HellMood/DESiRE
; the tiny megademo, 256 byte msdos intro
; shown in April 2020 @ REVISION
;
;   (= WILL BE COMMENTED IN DETAIL LATER =)
;
; create : nasm.exe memories.asm -fbin -o memories.com
; CHOOSE YOUR TARGET PLATFORM (compo version is dosbox)
; be sure to use the dosbox.conf from this archive!
; only ONE of the defines should be active!
%define dosbox			; size : 256 bytes

; GLOBAL PARAMETERS, TUNE WITH CARE!
%define volume 127	; not used on dosbox (optimization)
%define instrument 11
%define scale_mod -19*32*4;
%define time_mask 7
%define targetFPS 65
%define tempo 1193182/256/targetFPS
%define sierp_color 0x2A
%define tunnel_base_color 20
%define tunnel_pattern 6
%define tilt_plate_pattern 4+8+16
%define circles_pattern 8+16

org 100h                ; program is loaded at 0x0100
s:
	mov al,0x13         ; setup 320x200, 256 color 1 page graphics 0x13 int 0x10
	int 0x10	        ; Assumes AH = 0x00
	xchg bp,ax          ; load BP (0x0000 at start) into AX (efectively clearing it) (BP = 0x0013)
	push 0xa000-10      ; 0xA000:0000 is the begging of VGA Memory (?)
	pop es              ; ES = 0x9FF6 (0xA000 - 0x10)

; Setup interrupt handler
; INT 21h / AH=25h - set interrupt vector;
; input: AL = interrupt number. DS:DX -> new interrupt handler.
; AH = 0x25
; AL = 0x1C
; DS = 0x07FC (? default)
; DX = 0x0145 (offset to timer function)

	mov ax,0x251c

	; assume DH=1, mostly true on DosBox
	mov dl,timer        ; NOT TRUE when running under DEBUGX
	int 0x21            ; AX = 0x251c , DX = 0x0145 (org 0x100 + offset to timer function):
                        ; sets up new interrupt handler to call our timer function. Kills debugx :-(
                        ;
                        ; "The simplest ISR to replace is that of the timer-tick.
                        ; This is because the standard timer-tick routine does nothing.
                        ; The timer-tick routine is called by the CPU approximately
                        ; 18.2 times per second. At boot-up time, this interrupt vector
                        ; points to an IRET instruction, thereby doing absolutely nothing.
                        ; Its quite safe to to redirect this interrupt (1Ch) to points
                        ; to a procedure that the programmer wants executed very frequently."
                        ; (See http://www.husseinsspace.com/teaching/udw/1996/asmnotes/chapsev.htm)


; Seems to be the main loop. Calls each effect one at a time.
; DI starts with 0x0000
; BP starts with 0x0013
; ES starts with 0xA000 - 0x10 (0x9FF6)
top:
    ; Choose which effect to play next. The value is stored in AL and is
    ; an index to the 'table:' entry list. This code seems to be responsible
    ; of fading in / out of effects. This code is basically a function of the
    ; DI and BP registers. Its a very slow, increasing function of both values.
	mov ax,0xcccd
	mul di
	add al,ah
	xor ah,ah               ; Set AH = 0
    add ax,bp
    shr ax,9
	and al,15

	;mov ax,0x0              ; hardcodeo a valuee for AX register

	xchg bx,ax
	mov bh,1                ; Load offset to effect to BX
	mov bl,[byte bx+table]
	call bx                 ; Call effect

	stosb                   ; Store AL register in ES:[DI] and increase DI (or decrease depending on DF flag)
	inc di
	inc di
	jnz top

    ; Do some weird shit with I/O ports....
	mov al,tempo
	out 40h,al              ; This is the 'counter divisor'. I think this controlls how often the
                            ; interrupt is fired. See:
                            ; https://en.wikibooks.org/wiki/X86_Assembly/Programmable_Interval_Timer and                                                ; http://bochs.sourceforge.net/techspec/PORTS.LST
	in al,0x60              ; Read from scan-code from keyboard. ESC has scan code = 1 so when we decrease it
                            ; it will yield zero and will break from this loop.
	dec al
	jnz top

    ; 0xc3 is the OPCODE of RET which marks the end of the program
sounds:
	db 0xc3	; is MIDI/RET
table: ; first index is volume, change order with care!
	db fx2-s,fx1-s,fx0-s,fx3-s,fx4-s,fx5-s,fx6-s,sounds-s,stop-s
stop:
	pop ax
	ret
timer:
	%ifdef safe_segment
		push cs
		pop ds
	%endif
		inc bp
nomuse:
	iret
fx0: ; tilted plane, scrolling
	mov ax,0x1329
	add dh,al
	div dh
	xchg dx,ax
	imul dl
	sub dx,bp
	xor ah,dl
	mov al,ah
	and al,tilt_plate_pattern
ret
fx2: ; board of chessboards
    ; TEST mov ax, di
    ; TEST shr ax, 2
    ; TEST mul di
    ; TEST ret
	xchg dx,ax
	sub ax,bp
	xor al,ah
	or al,0xDB
	add al,13h
ret
fx1: ; circles, zooming
	mov al,dh
	sub al,100
	imul al
	xchg dx,ax
	imul al
	add dh,ah
	mov al,dh
	add ax,bp
	and al,circles_pattern
ret
fx3: ; parallax checkerboards
	mov cx,bp
	mov bx,-16
fx3L:
	add cx,di
	mov ax,819
	imul cx
	ror dx,1
	inc bx
	ja fx3L
	lea ax,[bx+31]
ret
fx4: ; sierpinski rotozoomer
	lea cx,[bp-2048]
	sal cx,3
	movzx ax,dh
	movsx dx,dl
	mov bx,ax
	imul bx,cx
	add bh,dl
	imul dx,cx
	sub al,dh
	and al,bh
	and al,0b11111100
	salc				; VERY slow on dosbox, but ok
	jnz fx4q
	mov al,sierp_color
	fx4q:
ret
fx5: ; raycast bent tunnel
	mov cl,-9
	fx5L:
	push dx
		mov al,dh
		sub al,100
		imul cl
		xchg ax,dx
		add al,cl
		imul cl
		mov al,dh
		xor al,ah
		add al,4
		test al,-8
	pop dx
	loopz fx5L
	sub cx,bp
	xor al,cl
	aam tunnel_pattern; VERY slow on dosbox, but ok
	add al,tunnel_base_color
ret
fx6: ; ocean night / to day sky
	sub dh,120
	js fx6q
	mov [bx+si],dx
	fild word [bx+si]
	fidivr dword [bx+si]
	fstp dword [bx+si-1]
	mov ax,[bx+si]
	add ax,bp
	and al,128
	dec ax
fx6q:
ret
