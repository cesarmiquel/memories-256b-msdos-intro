<?php

/*
 *  mov ax,0xcccd
    mul di
    add al,ah
    xor ah,ah               ; Set AH = 0
    add ax,bp
    shr ax,9
    and al,15
 */

printf("--------------------\n");
printf("   BP     DI    AX\n");
printf("--------------------\n");
for($bp = 0; $bp < 0x2000; $bp += 0x140) {
    for($di = 0; $di < 0xffff; $di += 0x2000) {

        // mov ax, 0xcccd
        $ax = 0xcccd;
        print_regs($ax, $di, $bp);

        // mul di
        $ax *= $di;
        print_regs($ax, $di, $bp);

        $ax &= 0xffff;
        print_regs($ax, $di, $bp);

        // add al, ah
        $al = 0x00ff & $ax;
        $ah = (0xff00 & $ax) >> 8;
        $ax = $al + $ah;
        print_regs($ax, $di, $bp);

        // xor ah, ah
        $ax &= 0x00ff;
        print_regs($ax, $di, $bp);

        // add ax,bp
        $ax += $bp;
        print_regs($ax, $di, $bp);

        // shr ax, 9
        $ax = $ax >> 9;
        print_regs($ax, $di, $bp);

        // and al, 15
        $ax = $ax & 0x000f;
        print_regs($ax, $di, $bp);

        //printf("%d, %d, %d\n", $bp, $di, $ax);
        printf("0x%04x 0x%04x 0x%04x\n", $bp, $di, $ax);
        //exit();
    }
    printf("\n");
}


function print_regs($ax, $di, $bp) {
    return;
    printf("AX: 0x%04x  DI: 0x%04x   BL: 0x%04x\n", $ax, $di, $bp);
}
