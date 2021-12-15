.global _start
	.equ PUSH_DATA, 0xFF200050
	.equ PUSH_DATA_EDGE, 0xFF20005C
	.equ INTERRUPT_MASK, 0xFF200058
_start:
	push {r1, r2}
	mov r2, #0xf
	ldr r1, =INTERRUPT_MASK
	str r2, [r1]
	pop {r1, r2}
	
	b poll
	//mov r0, #1	// enable the first PB
	//push {lr}
	//bl enable_PB_INT_ASM
	//pop {lr}
	
	//mov r0, #1
	//push {lr}
	//bl disable_PB_INT_ASM
	//pop {lr}
poll:
	mov r0, #0x0
	push {lr}
	bl read_PB_data_ASM
	pop {lr}
	
	push {lr}
	bl PB_clear_edgecp_ASM
	pop {lr}
	
	b poll
	
PB_clear_edgecp_ASM:
	// disable all others
	push {r0}
	push {r5}
	
	mov r5, r0
	mvn r0, r0
	push {lr}
	bl disable_PB_INT_ASM
	pop {lr}
	
	push {r1}
	ldr r1, =PUSH_DATA_EDGE
	ldr r0, [r1]
	str r0, [r1]
	pop {r1}
	
	mov r0, r5
	push {lr}
	bl enable_PB_INT_ASM
	pop {lr}
	
	pop {r5}
	pop {r0}
	
	bx lr
read_PB_edgecp_ASM:
	// clear all other interrupts
	push {r0}
	push {r5}
	
	mov r5, r0
	mvn r0, r0
	push {lr}
	bl disable_PB_INT_ASM
	pop {lr}
	
	ldr r1, =PUSH_DATA_EDGE	// read the ones that were released
	ldr r0, [r1]
	cmp r0, #0
	beq read_PB_edgecp_ASM
	
	
	bx lr	// value is now in r0
read_PB_data_ASM:
	ldr r1, =PUSH_DATA
	ldr r0, [r1]
	cmp r0, #0
	beq leave
	b read_PB_edgecp_ASM
leave:
	bx lr
enable_PB_INT_ASM:
	// The subroutine receives pushbuttons indices as an argument. 
	// Then, it enables the interrupt function for the corresponding 
	// pushbuttons by setting the interrupt mask bits to '1'.
	ldr r1, =INTERRUPT_MASK
	str r0, [r1]
	bx lr
	
disable_PB_INT_ASM:
	push {r1, r2}
	ldr r1, =INTERRUPT_MASK
	ldrb r2, [r1]
	sub r2, r2, r0
	str r2, [r1]
	pop {r1, r2}
	bx lr
	
	  
	
	