.global _start
	.equ HEX5_4, 0xFF200030	// hex5 and hex4
	.equ HEX3_0, 0xFF200020	// hex3 to hex0
	.equ PUSH_DATA, 0xFF200050
	.equ PUSH_DATA_EDGE, 0xFF20005C
	.equ SW_MEMORY, 0xFF200040
	.equ LED_MEMORY, 0xFF200000
	.equ INTERRUPT_MASK, 0xFF200058
_start:
	mov r0, #0
	mov r1, #0
	mov r2, #0
	mov r3, #0
	
	push {lr}
	bl HEX_clear_ASM
	pop {lr}
	
	push {lr}
	bl HEX_flood_ASM
	pop {lr}
	
	push {lr}
	bl PB_clear_edgecp_ASM
	pop {lr}
	
	b _start_
_start_:
	/* read switches */
	push {lr}
	bl read_slider_switches_ASM	// info is now in r0
	pop {lr}
	
	push {lr}
	bl write_LEDs_ASM			// write to LEDs
	pop {lr}
	
	push {r0}				// for later use
	
	/* read push button release */
	push {lr}
	bl read_PB_data_ASM	// info is now in r0
	pop {lr}
	
	// read which button is pressed
	// enable a mask for the other three
	
	pop {r1}				// get read_slider_switches_ASM (digit) into r0
	
	push {lr}
	bl HEX_clear_ASM
	pop {lr}
	
	push {lr}
	bl HEX_write_ASM
	pop {lr}
	
	// disable the bits that were just used
	// enable the bits that are currently pressed
	//push {lr}
	//bl ...
	//pop {lr}
	
	push {lr}
	bl PB_clear_edgecp_ASM
	pop {lr}
	
	b _start_
write_LEDs_ASM:
    ldr r1, =LED_MEMORY
    str r0, [r1]
	tst r0, #0x200
	bne terminate
    bx  lr
terminate:
	push {r3}
	mov r3, #0
	
	ldr r1, =HEX5_4	// clear 5 - 4
	str r3, [r1]
	
	ldr r1, =HEX3_0	// clear 3 - 0
	str r3, [r1]
	
	pop {r3}
	mov r0, #69
	//pop {lr}
	b end
read_slider_switches_ASM:
    ldr r1, =SW_MEMORY
    ldr r0, [r1]
    bx  lr
read_PB_data_ASM:
	//push {r1}
	ldr r1, =PUSH_DATA
	ldr r0, [r1]
	cmp r0, #0
	beq leave
	b read_PB_edgecp_ASM
leave:
	bx lr
read_PB_edgecp_ASM:
	//push {r1}
	ldr r1, =PUSH_DATA_EDGE	// read the ones that were released
	ldr r0, [r1]
	cmp r0, #0
	beq read_PB_edgecp_ASM
	//pop {r1}
	bx lr
PB_clear_edgecp_ASM:
	push {r1}
	ldr r1, =PUSH_DATA_EDGE
	ldr r0, [r1]
	str r0, [r1]
	pop {r1}
	bx lr
enable_PB_INT_ASM:
	ldr r1, =INTERRUPT_MASK
	mov r2, #0xf
	str r2, [r1]
	bx lr
	
disable_PB_INT_ASM:
	push {r1, r2}
	ldr r1, =INTERRUPT_MASK
	ldr r2, [r1]
	sub r2, r2, r0
	str r2, [r1]
	pop {r1, r2}
	
	bx lr
HEX_clear_ASM:
	mov r3, r0
	mov r2, r1
	mov r1, #0x10
	push {lr}
	bl HEX_write_ASM
	pop {lr}
	mov r1, r2
	mov r0, r3
	
	bx lr
	
HEX_flood_ASM:
	mov r0, #0x30	// address of last two
	mov r1, #8
	push {lr}
	bl HEX_write_ASM
	pop {lr}
	
	bx lr

HEX_write_ASM:
	push {r2, r3}
	cmp r1, #0x10	// special case
	beq HEX_write_ASM_2
	cmp r1, #0x0
	beq write_0
	cmp r1, #0x1
	beq write_1
	cmp r1, #0x2
	beq write_2
	cmp r1, #0x3
	beq write_3
	cmp r1, #0x4
	beq write_4
	cmp r1, #0x5
	beq write_5
	cmp r1, #0x6
	beq write_6
	cmp r1, #0x7
	beq write_7
	cmp r1, #0x8
	beq write_8
	cmp r1, #0x9
	beq write_9
	cmp r1, #0xa
	beq write_a
	cmp r1, #0xb
	beq write_b
	cmp r1, #0xc
	beq write_c
	cmp r1, #0xd
	beq write_d
	cmp r1 ,#0xe
	beq write_e
	cmp r1, #0xf
	beq write_f
write_empty:
	mov r1, #0b00000000 // empty
	b HEX_write_ASM_2
write_0:
	mov r1, #0b00111111 // 0
	b HEX_write_ASM_2
write_1:
	mov r1, #0b00000110	// 1
	b HEX_write_ASM_2
write_2:
	mov r1, #0b01011011 // 2
	b HEX_write_ASM_2
write_3:
	mov r1, #0b01001111 // 3
	b HEX_write_ASM_2
write_4:
	mov r1, #0b01100110 // 4
	b HEX_write_ASM_2
write_5:
	mov r1, #0b01101101 // 5
	b HEX_write_ASM_2
write_6:
	mov r1, #0b01111101 // 6
	b HEX_write_ASM_2
write_7:
	mov r1, #0b00000111 // 7
	b HEX_write_ASM_2
write_8:
	mov r1, #0b01111111 // 8
	b HEX_write_ASM_2
write_9:
	mov r1, #0b01101111 // 9
	b HEX_write_ASM_2
write_a:
	mov r1, #0b01110111 // a
	b HEX_write_ASM_2
write_b:
	mov r1, #0b01111100 // b
	b HEX_write_ASM_2
write_c:
	mov r1, #0b01011000 // c
	b HEX_write_ASM_2
write_d:
	mov r1, #0b01011110 // d
	b HEX_write_ASM_2
write_e:
	mov r1, #0b01111011 // e
	b HEX_write_ASM_2
write_f:
	mov r1, #0b01110001 // f
	b HEX_write_ASM_2
HEX_write_ASM_2:
	tst r0, #0b1
	bne write_hex0
	
	tst r0, #0b10
	bne write_hex1
	
	tst r0, #0b100
	bne write_hex2
	
	tst r0, #0b1000
	bne write_hex3
	
	tst r0, #0b10000
	bne write_hex4
	
	tst r0, #0b100000
	bne write_hex5
	
	pop {r2, r3}
	bx lr
	
write_hex0:
	cmp r1, #0x10
	beq write_hex0_remove
	push {r3}
	ldr r3, =HEX3_0
	push {r5}
	ldr r5, [r3]
	add r1, r5, r1
	pop {r5}
	str r1, [r3]
	pop {r3}
	sub r0, r0, #1
	b HEX_write_ASM_2
write_hex0_remove:
	push {r3}
	ldr r3, =HEX3_0
	push {r5}
	ldr r5, [r3]
	and r5, r5, #0xFFFFFF00
	str r5, [r3]
	pop {r5}
	pop {r3}
	sub r0, r0, #1
	b HEX_write_ASM_2
write_hex1:
	cmp r1, #0x10
	beq write_hex1_remove
	push {r3}
	ldr r3, =HEX3_0
	push {r4}
	lsl r4, r1, #8
	push {r5}
	ldr r5, [r3]
	add r4, r5, r4
	pop {r5}
	str r4, [r3]
	pop {r4}
	pop {r3}
	sub r0, r0, #2
	b HEX_write_ASM_2
write_hex1_remove:
	push {r3}
	ldr r3, =HEX3_0
	push {r5}
	ldr r5, [r3]
	and r5, r5, #0xFFFF00FF
	str r5, [r3]
	pop {r5}
	pop {r3}
	sub r0, r0, #2
	b HEX_write_ASM_2
write_hex2:
	cmp r1, #0x10
	beq write_hex2_remove
	push {r3}
	ldr r3, =HEX3_0
	push {r4}
	lsl r4, r1, #16
	push {r5}
	ldr r5, [r3]
	add r4, r5, r4
	pop {r5}
	str r4, [r3]
	pop {r4}
	pop {r3}
	sub r0, r0, #4
	b HEX_write_ASM_2
write_hex2_remove:
	push {r3}
	ldr r3, =HEX3_0
	push {r5}
	ldr r5, [r3]
	and r5, r5, #0xFF00FFFF
	str r5, [r3]
	pop {r5}
	pop {r3}
	sub r0, r0, #4
	b HEX_write_ASM_2
write_hex3:
	cmp r1, #0x10
	beq write_hex3_remove
	push {r3}
	ldr r3, =HEX3_0
	push {r4}
	lsl r4, r1, #24
	push {r5}
	ldr r5, [r3]
	add r4, r5, r4
	pop {r5}
	str r4, [r3]
	pop {r4}
	pop {r3}
	sub r0, r0, #8
	b HEX_write_ASM_2
write_hex3_remove:
	push {r3}
	ldr r3, =HEX3_0
	push {r5}
	ldr r5, [r3]
	and r5, r5, #0x00FFFFFF
	str r5, [r3]
	pop {r5}
	pop {r3}
	sub r0, r0, #8
	b HEX_write_ASM_2
write_hex4:
	cmp r1, #0x10
	beq write_hex4_remove
	push {r3}
	ldr r3, =HEX5_4
	str r1, [r3]
	pop {r3}
	sub r0, r0, #16
	b HEX_write_ASM_2
write_hex4_remove:
	push {r3}
	ldr r3, =HEX5_4
	push {r5}
	ldr r5, [r3]
	and r5, r5, #0xFFFFFF00
	str r5, [r3]
	pop {r5}
	pop {r3}
	sub r0, r0, #16
	b HEX_write_ASM_2
write_hex5:
	cmp r1, #0x10
	beq write_hex5_remove
	push {r3}
	ldr r3, =HEX5_4
	push {r4}
	lsl r4, r1, #8
	push {r5}
	ldr r5, [r3]
	add r4, r5, r4
	pop {r5}
	str r4, [r3]
	pop {r4}
	pop {r3}
	sub r0, r0, #32
	b HEX_write_ASM_2	
write_hex5_remove:
	push {r3}
	ldr r3, =HEX5_4
	push {r5}
	ldr r5, [r3]
	and r5, r5, #0xFFFF00FF
	str r5, [r3]
	pop {r5}
	pop {r3}
	sub r0, r0, #32
	b HEX_write_ASM_2
end:
	.end
	
	
	
	





