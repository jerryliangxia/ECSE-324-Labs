.global _start
	.equ LOAD, 0xFFFEC600
	.equ CURRENT, 0xFFFEC604
	.equ CONTROL, 0xFFFEC608
	.equ INTERRUPT_STATUS, 0xFFFEC60C
	.equ HEX3_0, 0xFF200020
	.equ LED_MEMORY, 0xFF200000
	.equ loadValue, 200000000
_start:
	/* set up */
	//movw r0, #0x6500	// load bits - value of 500,000,000
	//movt r0, #0x1dcd
	mov r1, #3	// configuration bits
	
	push {lr}
	bl ARM_TIM_config_ASM
	pop {lr}
	
	mov r1, #0
	/* end set up */
	
	b _start_
_start_:
	push {lr}
	bl ARM_TIM_read_INT_ASM
	pop {lr}
	
	cmp r0, #1	// if there is a 1
	beq _reset	// branch to ISR
	
	b _start_
_reset:
	/* HEX0 display */
	push {lr}				// clear
	bl HEX_clear_ASM
	pop {lr}
	
	push {lr}
	bl HEX_write_ASM		// write (r1)
	pop {lr}
	/* end HEX0 display */
	
	/* LEDs */
	push {lr}
	bl write_LEDs_ASM
	pop {lr}
	/* end LEDs */
	
	/* reset F */
	push {lr}
	bl ARM_TIM_clear_INT_ASM
	pop {lr}
	
	add r1, r1, #1	// increment r1
	cmp r1, #16
	beq reset_count
		
	b _start_	// go back to the beginning
	
reset_count:
	mov r1, #0
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
	ldr r1, =LOAD		// r0 contains the base address for the timer 
	str r0, [r1]		// Set the period to be 500,000,000 clock cycles 

	mov r0, #3
	str r0, [r1, #8]	//  Start the timer continuing no interrupts 
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
HEX_clear_ASM:
	push {r3}
	mov r3, #0x10
	push {lr}
	bl HEX_write_ASM
	pop {lr}
	pop {r3}
	bx lr
	
HEX_write_ASM:
	cmp r3, #0x10	// special case
	beq write_empty
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
	mov r2, #0b00000000 // empty
	b write_hex0
write_0:
	mov r2, #0b00111111 // 0
	b write_hex0
write_1:
	mov r2, #0b00000110	// 1
	b write_hex0
write_2:
	mov r2, #0b01011011 // 2
	b write_hex0
write_3:
	mov r2, #0b01001111 // 3
	b write_hex0
write_4:
	mov r2, #0b01100110 // 4
	b write_hex0
write_5:
	mov r2, #0b01101101 // 5
	b write_hex0
write_6:
	mov r2, #0b01111101 // 6
	b write_hex0
write_7:
	mov r2, #0b00000111 // 7
	b write_hex0
write_8:
	mov r2, #0b01111111 // 8
	b write_hex0
write_9:
	mov r2, #0b01101111 // 9
	b write_hex0
write_a:
	mov r2, #0b01110111 // a
	b write_hex0
write_b:
	mov r2, #0b01111100 // b
	b write_hex0
write_c:
	mov r2, #0b01011000 // c
	b write_hex0
write_d:
	mov r2, #0b01011110 // d
	b write_hex0
write_e:
	mov r2, #0b01111011 // e
	b write_hex0
write_f:
	mov r2, #0b01110001 // f
	b write_hex0
write_hex0:
	ldr r3, =HEX3_0
	str r2, [r3]
	bx lr
/* end old code */