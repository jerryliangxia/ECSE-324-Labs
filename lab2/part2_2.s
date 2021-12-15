.global _start
	.equ LOAD, 0xFFFEC600
	.equ CURRENT, 0xFFFEC604
	.equ CONTROL, 0xFFFEC608
	.equ INTERRUPT_STATUS, 0xFFFEC60C
	.equ INTERRUPT_MASK, 0xFF200058
	.equ HEX3_0, 0xFF200020
	.equ HEX5_4, 0xFF200030
	.equ LED_MEMORY, 0xFF200000
	.equ PUSH_DATA, 0xFF200050
	.equ PUSH_DATA_EDGE, 0xFF20005C
	.equ loadValue, 20000000
	h1: .word 0
	h2: .word 0
	m1: .word 0
	m2: .word 0
	s1: .word 0
	count: .word 1
_start:
	/* set up */
	//movw r0, #0xf080	// load bits - value of 50,000,000 or
	//movt r0, #0x02fa    // 2FAF080 (for 10 ms)
	mov r1, #3			// configuration bits
	
	push {lr}
	bl ARM_TIM_config_ASM
	pop {lr}
	
	mov r0, #63
	mov r1, #0x10
	push {lr}				// clear
	bl HEX_clear_ASM
	pop {lr}
	
	// light up all hex
	mov r0, #63	// address of first one
	mov r1, #0
	push {lr}
	bl HEX_flood_ASM
	pop {lr}
	
	push {lr}
	bl PB_clear_edgecp_ASM
	pop {lr}
	/* end set up */
	
	b poll_start
poll_start:
	/* read push button release */
	push {lr}
	bl read_PB_data_ASM	// info is now in r0
	pop {lr}
	
	cmp r0, #1
	beq _start_
	
	b poll_start
read_PB_data_ASM:
	ldr r1, =PUSH_DATA
	ldr r0, [r1]
	cmp r0, #0
	beq leave
	b read_PB_edgecp_ASM
leave:
	bx lr
read_PB_edgecp_ASM:
	ldr r1, =PUSH_DATA_EDGE	// read the ones that were released
	ldr r0, [r1]
	cmp r0, #0
	beq read_PB_edgecp_ASM
	bx lr	// value is now in r0
PB_clear_edgecp_ASM:
	push {r1}
	ldr r1, =PUSH_DATA_EDGE
	ldr r0, [r1]
	str r0, [r1]
	pop {r1}
	bx lr
_start_:
	push {lr}
	bl PB_clear_edgecp_ASM
	pop {lr}
	
	push {lr}
	bl ARM_TIM_read_INT_ASM
	pop {lr}
	
	cmp r0, #1	// if there is a 1
	beq _reset	// branch to ISR
	
	push {lr}
	bl read_PB_data_ASM	// info is now in r0
	pop {lr}
	
	cmp r0, #0b1
	beq start_timer
	cmp r0, #0b10
	beq pause_timer
	cmp r0, #0b100
	beq reset_timer
	
	b _start_
start_timer:
	ldr r1, =LOAD 
	mov r0, #3
	str r0, [r1, #8]
	b _start_
pause_timer:
	ldr r1, =LOAD 
	mov r0, #2
	str r0, [r1, #8]
	b _start_
reset_timer:
	push {r1, r2}
	ldr r2, =count
	ldr r1, [r2]
	mov r1, #0
	str r1, [r2]
	
	ldr r2, =s1
	ldr r1, [r2]
	mov r1, #0
	str r1, [r2]
	
	ldr r2, =m2
	ldr r1, [r2]
	mov r1, #0
	str r1, [r2]
	
	ldr r2, =m1
	ldr r1, [r2]
	mov r1, #0
	str r1, [r2]
	
	ldr r2, =h2
	ldr r1, [r2]
	mov r1, #0
	str r1, [r2]
	
	ldr r2, =h1
	ldr r1, [r2]
	mov r1, #0
	str r1, [r2]
	
	pop {r1, r2}
	
	mov r0, #63
	mov r1, #0x10
	push {lr}				// clear
	bl HEX_clear_ASM
	pop {lr}
	
	// light up all hex
	mov r0, #63	// address of first one
	mov r1, #0
	push {lr}
	bl HEX_flood_ASM
	pop {lr}
	
	push {lr}
	bl PB_clear_edgecp_ASM
	pop {lr}
	
	b _start_
_reset:
	/* HEX0 display */
	mov r0, #0b10
	ldr r1, =count
	ldr r1, [r1]
	
	add r1, r1, #1		// increment r1
	cmp r1, #10			// because you don't want to display "a"
	beq reset_count_m2
	ldr r3, =count		// get count
	str r1, [r3]		// store back
	
	mov r0, #0b10
	mov r1, #0x10
	push {lr}				// clear
	bl HEX_clear_ASM
	pop {lr}
	
	mov r0, #0b10
	ldr r1, =count
	ldr r1, [r1]
	push {lr}
	bl HEX_write_ASM		// write (r1)
	pop {lr}
	/* end HEX0 display */
	
	/* LEDs */
	ldr r1, =count
	ldr r1, [r1]
	push {lr}
	bl write_LEDs_ASM
	pop {lr}
	/* end LEDs */
	
	/* reset F */
	push {lr}
	bl ARM_TIM_clear_INT_ASM
	pop {lr}

	b _start_			// go back to the beginning
	
reset_count_m2:			// r2 is the carry value
	mov r1, #0
	ldr r3, =count
	str r1, [r3]		// store back
	// and then display it!!
	/* write */
	mov r0, #0b10
	mov r1, #0x10
	push {lr}				// clear
	bl HEX_clear_ASM
	pop {lr}
	
	mov r0, #0b10
	ldr r1, =count
	ldr r1, [r1]
	push {lr}
	bl HEX_write_ASM		// write (r1)
	pop {lr}
	
	push {r2}
	ldr r2, =m2
	ldr r2, [r2]
	add r2, r2, #1
	cmp r2, #10
	beq reset_count_m1
	ldr r3, =m2
	str r2, [r3]		// store value and pop
	
	mov r0, #0b100
	mov r1, #0x10
	push {lr}
	bl HEX_clear_ASM
	pop {lr}
	
	mov r0, #0b100
	ldr r1, =m2
	ldr r1, [r1]
	push {lr}
	bl HEX_write_ASM
	pop {lr}
	
	pop {r2}
	
	b _start_
	
reset_count_m1:
	mov r2, #0
	ldr r3, =m2
	str r2, [r3]		// store back
	
	// and then display it!!
	/* write */
	mov r0, #0b100
	mov r1, #0x10
	push {lr}
	bl HEX_clear_ASM
	pop {lr}
	
	mov r0, #0b100
	ldr r1, =m2
	ldr r1, [r1]
	push {lr}
	bl HEX_write_ASM
	pop {lr}
	/* write */
	
	ldr r2, =m1			// get the new address
	ldr r2, [r2]		// get value inside
	add r2, r2, #1
	cmp r2, #6
	beq reset_count_h2
	ldr r3, =m1
	str r2, [r3]		// store back
	pop {r2}
	
	/* write */
	mov r0, #0b1000
	mov r1, #0x10
	push {lr}
	bl HEX_clear_ASM
	pop {lr}
	
	mov r0, #0b1000
	ldr r1, =m1
	ldr r1, [r1]
	push {lr}
	bl HEX_write_ASM
	pop {lr}
	/* write */
	
	b _start_
	
reset_count_h2:
	mov r2, #0
	ldr r3, =m1
	str r2, [r3]		// store back
	
	// and then display it!!
	/* write */
	mov r0, #0b1000
	mov r1, #0x10
	push {lr}
	bl HEX_clear_ASM
	pop {lr}
	
	mov r0, #0b1000
	ldr r1, =m1
	ldr r1, [r1]
	push {lr}
	bl HEX_write_ASM
	pop {lr}
	/* write */
	
	ldr r2, =h2
	ldr r2, [r2]
	add r2, r2, #1
	cmp r2, #10
	beq reset_count_h1
	ldr r3, =h2
	str r2, [r3]
	pop {r2}
	
	/* write */
	mov r0, #0b10000
	mov r1, #0x10
	push {lr}
	bl HEX_clear_ASM
	pop {lr}
	
	mov r0, #0b10000
	ldr r1, =h2
	ldr r1, [r1]
	push {lr}
	bl HEX_write_ASM
	pop {lr}
	/* write */
	
	b _start_
	
reset_count_h1:
	mov r2, #0
	ldr r3, =h2
	str r2, [r3]		// store back
	
	/* write */
	mov r0, #0b10000
	mov r1, #0x10
	push {lr}
	bl HEX_clear_ASM
	pop {lr}
	
	mov r0, #0b10000
	ldr r1, =h1
	ldr r1, [r1]
	push {lr}
	bl HEX_write_ASM
	pop {lr}
	/* write */
	
	ldr r2, =h1
	ldr r2, [r2]
	add r2, r2, #1
	cmp r2, #10
	beq reset_count_all
	ldr r3, =h1
	str r2, [r3]
	pop {r2}
	
	/* write */
	mov r0, #0b100000
	mov r1, #0x10
	push {lr}
	bl HEX_clear_ASM
	pop {lr}
	
	mov r0, #0b100000
	ldr r1, =h2
	ldr r1, [r1]
	push {lr}
	bl HEX_write_ASM
	pop {lr}
	/* write */
	
	b _start_
reset_count_all:
	mov r2, #0
	ldr r3, =h1
	str r2, [r3]
	pop {r2}
	
	/* write */
	mov r0, #0b100000
	mov r1, #0x10
	push {lr}
	bl HEX_clear_ASM
	pop {lr}
	
	mov r0, #0b100000
	ldr r1, =h1
	ldr r1, [r1]
	push {lr}
	bl HEX_write_ASM
	pop {lr}
	/* write */
	
	b _start_
	
write_LEDs_ASM:
	push {r2}
    ldr r2, =LED_MEMORY
    str r1, [r2]
	pop {r2}
    bx  lr
	
ARM_TIM_config_ASM:
	push {r0, r1}
	ldr r0, =loadValue
	ldr r1, =LOAD			// r0 contains the base address for the timer 
	str r0, [r1]			// Set the period to be 500,000,000 clock cycles 

	mov r0, #3
	str r0, [r1, #8]		//  Start the timer continuing no interrupts 
	pop {r0, r1}
	bx lr

ARM_TIM_clear_INT_ASM:
	push {r1}
	ldr r1, =INTERRUPT_STATUS
	mov r0, #1
	str r0, [r1]			// write a 1 to F to reset it
	pop {r1}
	bx lr
	
ARM_TIM_read_INT_ASM:
	ldr r0, =INTERRUPT_STATUS
	ldr r0, [r0]
	bx lr
	
/* old code */
HEX_flood_ASM:
	push {lr}
	bl HEX_write_ASM
	pop {lr}
	bx lr
	
HEX_clear_ASM:
	mov r1, #0x10	// TODO need to account for this
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
	
	
	
	





