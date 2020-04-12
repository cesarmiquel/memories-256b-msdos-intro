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

; DON'T TOUCH THESE UNLESS YOU KNOW WHAT YOU'RE DOING
	%define music
	;%define safe_dx ; sometimes needed

; GLOBAL PARAMETERS, TUNE WITH CARE!
%define volume 127	; not used on dosbox (optimization)
%define instrument 11
%define scale_mod -19*32*4; 
%define time_mask 7
%define targetFPS 95
%define tempo 1193182/256/targetFPS		
%define sierp_color 0x2A
%define tunnel_base_color 20
%define tunnel_pattern 6
%define tilt_plate_pattern 4+8+16
%define circles_pattern 8+16

org 100h                ; program is loaded at 0x0100
s:
	mov al,0x13         ; setup 320x200 graphics 0x13 int 0x10
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
	%ifdef safe_dx	
		mov dx,timer	
	%else ; assume DH=1, mostly true on DosBox
		mov dl,timer    ; NOT TRUE when running under DEBUGX
	%endif
	int 0x21            ; AX = 0x251c , DX = 0x0145 (org 0x100 + offset to timer function): sets up new interrupt handler to call our timer function. Kills debugx :-(

; Seems to be the main loop. Calls each effect one at a time.
; DI starts with 0x0000
; BP starts with 0x0013 
; ES starts with 0xA000 - 0x10 (0x9FF6)
top:                    
	mov ax,0xcccd
	mul di
	add al,ah
	xor ah,ah
	add ax,bp
	shr ax,9
	and al,15
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
	out 40h,al
	in al,0x60
	dec al
	jnz top

sounds:
	db 0xc3	; is MIDI/RET
%ifdef music
	db instrument,0x93
	%ifdef switch_uart
		db volume		; without switch, volume is in table
		db 0x3f 
	%endif
%endif
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
	%ifdef music	
		test bp, time_mask
		jnz nomuse
		mov dx,0x330
		mov si,sounds
		outsb
		outsb
		outsb
		imul ax,bp,scale_mod
		shr ax,10
		add al,22
		out dx,al
		outsb
		%ifdef switch_uart
			inc dx
			outsb
		%endif
	%endif
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
