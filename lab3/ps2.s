.global _start
	.equ ps2_driver, 0xff200100
	.equ pixel_buffer, 0xc8000000
	.equ char_buffer, 0xc9000000
	.equ x_limit, 320
	.equ y_limit, 240
	
	.equ x_limit2, 80
	.equ y_limit2, 60
_start:
        bl      input_loop
end:
        b       end

@ TODO: copy VGA driver here.
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

@ TODO: insert PS/2 driver here.
read_PS2_data_ASM:
	// r0 -> address pointer
	// r1 -> address of ps/2
	// r2 -> value at ps/2
	// r3 -> shifted value at ps/2 (only used to compare and branch)
	push {r1 - r3}
	ldr r1, =ps2_driver
	ldr r2, [r1]
	lsr r3, r2, #15	// temporary register
	tst r3, #0x1
	bne data_exists
	b data_dne
data_exists:
	strb r2, [r0]
	mov r0, #1
	pop {r1 - r3}
	bx lr
data_dne:
	mov r0, #0
	pop {r1 - r3}
	bx lr
		
write_hex_digit:
        push    {r4, lr}
        cmp     r2, #9
        addhi   r2, r2, #55
        addls   r2, r2, #48
        and     r2, r2, #255
        bl      VGA_write_char_ASM
        pop     {r4, pc}
write_byte:
        push    {r4, r5, r6, lr}
        mov     r5, r0
        mov     r6, r1
        mov     r4, r2
        lsr     r2, r2, #4
        bl      write_hex_digit
        and     r2, r4, #15
        mov     r1, r6
        add     r0, r5, #1
        bl      write_hex_digit
        pop     {r4, r5, r6, pc}
input_loop:
        push    {r4, r5, lr}
        sub     sp, sp, #12
        bl      VGA_clear_pixelbuff_ASM
        bl      VGA_clear_charbuff_ASM
        mov     r4, #0
        mov     r5, r4
        b       .input_loop_L9
.input_loop_L13:
        ldrb    r2, [sp, #7]
        mov     r1, r4
        mov     r0, r5
        bl      write_byte
        add     r5, r5, #3
        cmp     r5, #79
        addgt   r4, r4, #1
        movgt   r5, #0
.input_loop_L8:
        cmp     r4, #59
        bgt     .input_loop_L12
.input_loop_L9:
        add     r0, sp, #7
        bl      read_PS2_data_ASM
        cmp     r0, #0
        beq     .input_loop_L8
        b       .input_loop_L13
.input_loop_L12:
        add     sp, sp, #12
        pop     {r4, r5, pc}
