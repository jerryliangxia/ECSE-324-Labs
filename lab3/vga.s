.global _start
	.equ pixel_buffer, 0xc8000000
	.equ char_buffer, 0xc9000000
	.equ x_limit, 320
	.equ y_limit, 240
	
	.equ x_limit2, 80
	.equ y_limit2, 60
_start:
        //bl      VGA_draw_point_ASM
		//push {lr}
		//bl      VGA_clear_pixelbuff_ASM
		//pop {lr}
		
		/*
		push {lr}
		bl		VGA_write_char_ASM
		pop {lr}
		
		push {lr}
		bl		VGA_clear_charbuff_ASM
		pop {lr}
		*/
		bl      draw_test_screen
end:
        b       end

@ TODO: Insert VGA driver functions here.
VGA_draw_point_ASM:
	// draws colour on screen as indicated by third argument.
	// input: r0: x, r1: y, r2: colour
	push {r0 - r4}
	ldr r4, =pixel_buffer
	lsl r1, r1, #10
	orr r4, r4, r1
	lsl r0, r0, #1
	// now have obtained address needed, add it to base address
	orr r4, r4, r0
	strh r2, [r4] // Todo: figure out why this works
	pop {r0 - r4}
	bx lr
	
VGA_clear_pixelbuff_ASM:
	push {r0 - r3}
	mov r0, #0
	mov r1, #0
	push {lr}
	bl i_loop_pixbuff
	pop {lr}
	pop {r0 - r3}
	bx lr
	
i_loop_pixbuff:
	mov r1, #0
	push {lr}
	bl j_loop_pixbuff
	pop {lr}
	add r0, r0, #1
	ldr r3, =x_limit
	cmp r0, r3
	bne i_loop_pixbuff
	bx lr	// go outside of VGA_clear_pixelbuff_ASM
j_loop_pixbuff:
	// calls draw_point, knowing that r0 -> i and r1 -> j
	push {lr}
	bl VGA_draw_point_ASM
	pop {lr}
	add r1, r1, #1
	ldr r3, =y_limit
	cmp r1, r3
	bne j_loop_pixbuff
	bx lr
	
VGA_write_char_ASM:
	// check if r0 gte 80 | check if r1 gte 60
	cmp r0, #79
	bgt out_of_bounds
	cmp r0, #0
	blt out_of_bounds
	cmp r1, #59
	bgt out_of_bounds
	cmp r1, #0
	blt out_of_bounds
	push {r0 - r4}
	ldr r4, =char_buffer
	lsl r1, r1, #7
	orr r4, r4, r1
	// now have obtained address needed, add it to base address
	orr r4, r4, r0
	strb r2, [r4]	
	// Todo: add something else here?
	pop {r0 - r4}
	bx lr
out_of_bounds:
	bx lr
	
VGA_clear_charbuff_ASM:
	push {r0 - r3}
	mov r0, #0
	mov r1, #0
	mov r2, #0	// clear bit
	push {lr}
	bl i_loop_charbuff
	pop {lr}
	pop {r0 - r3}
	bx lr
	
i_loop_charbuff:
	mov r1, #0
	push {lr}
	bl j_loop_charbuff
	pop {lr}
	add r0, r0, #1
	ldr r3, =x_limit2
	cmp r0, r3
	bne i_loop_charbuff
	bx lr	// go outside of VGA_clear_pixelbuff_ASM
j_loop_charbuff:
	// calls draw_point, knowing that r0 -> i and r1 -> j
	push {lr}
	bl VGA_write_char_ASM
	pop {lr}
	add r1, r1, #1
	ldr r3, =y_limit2
	cmp r1, r3
	bne j_loop_charbuff
	bx lr

draw_test_screen:
        push    {r4, r5, r6, r7, r8, r9, r10, lr}
        bl      VGA_clear_pixelbuff_ASM
        bl      VGA_clear_charbuff_ASM
        mov     r6, #0
        ldr     r10, .draw_test_screen_L8
        ldr     r9, .draw_test_screen_L8+4
        ldr     r8, .draw_test_screen_L8+8
        b       .draw_test_screen_L2
.draw_test_screen_L7:
        add     r6, r6, #1
        cmp     r6, #320
        beq     .draw_test_screen_L4
.draw_test_screen_L2:
        smull   r3, r7, r10, r6
        asr     r3, r6, #31
        rsb     r7, r3, r7, asr #2
        lsl     r7, r7, #5
        lsl     r5, r6, #5
        mov     r4, #0
.draw_test_screen_L3:
        smull   r3, r2, r9, r5
        add     r3, r2, r5
        asr     r2, r5, #31
        rsb     r2, r2, r3, asr #9
        orr     r2, r7, r2, lsl #11
        lsl     r3, r4, #5
        smull   r0, r1, r8, r3
        add     r1, r1, r3
        asr     r3, r3, #31
        rsb     r3, r3, r1, asr #7
        orr     r2, r2, r3
        mov     r1, r4
        mov     r0, r6
        bl      VGA_draw_point_ASM
        add     r4, r4, #1
        add     r5, r5, #32
        cmp     r4, #240
        bne     .draw_test_screen_L3
        b       .draw_test_screen_L7
.draw_test_screen_L4:
        mov     r2, #72
        mov     r1, #5
        mov     r0, #20
        bl      VGA_write_char_ASM
        mov     r2, #101
        mov     r1, #5
        mov     r0, #21
        bl      VGA_write_char_ASM
        mov     r2, #108
        mov     r1, #5
        mov     r0, #22
        bl      VGA_write_char_ASM
        mov     r2, #108
        mov     r1, #5
        mov     r0, #23
        bl      VGA_write_char_ASM
        mov     r2, #111
        mov     r1, #5
        mov     r0, #24
        bl      VGA_write_char_ASM
        mov     r2, #32
        mov     r1, #5
        mov     r0, #25
        bl      VGA_write_char_ASM
        mov     r2, #87
        mov     r1, #5
        mov     r0, #26
        bl      VGA_write_char_ASM
        mov     r2, #111
        mov     r1, #5
        mov     r0, #27
        bl      VGA_write_char_ASM
        mov     r2, #114
        mov     r1, #5
        mov     r0, #28
        bl      VGA_write_char_ASM
        mov     r2, #108
        mov     r1, #5
        mov     r0, #29
        bl      VGA_write_char_ASM
        mov     r2, #100
        mov     r1, #5
        mov     r0, #30
        bl      VGA_write_char_ASM
        mov     r2, #33
        mov     r1, #5
        mov     r0, #31
        bl      VGA_write_char_ASM
        pop     {r4, r5, r6, r7, r8, r9, r10, pc}
.draw_test_screen_L8:
        .word   1717986919
        .word   -368140053
        .word   -2004318071
