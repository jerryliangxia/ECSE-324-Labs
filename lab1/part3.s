.global _start
	size: .word 5
	array: .word -1, 23, 0, 12, -7
_start:
	
	ldr r0, =array	// ptr
	
	ldr r1, =array	// ptr + i
	add r1, r1, #4
	
	mov r2, #0		// step
	mov r3, #0		// i
	
	push {lr}
	bl step
	pop {lr}
	
	b end
		
step:
	// reset pointers
	ldr r0, =array	// ptr
	
	ldr r1, =array	// ptr + i
	add r1, r1, #4
	
	mov r3, #0	// reset i
	
	push {lr}
	bl i
	pop {lr}
	
	// increment step
	add r2, r2, #1	// increment step
	push {r9}
	ldr r9, =size
	ldr r9, [r9]
	sub r9, r9, #1
	cmp r2, r9
	pop {r9}
	bne step
	
	bx lr	// branch back to init
i:
	push {lr}
	bl logic
	pop {lr}
	add r3, r3, #1	// increment i
	push {r9}
	ldr r9, =size
	ldr r9, [r9]
	sub r9, r9, #1
	sub r9, r9, r2
	cmp r3, r9
	pop {r9}
	bne i
	
	bx lr
logic:
	push {r5-r7, lr}
	ldr r5, [r0]	// r5 = tmp = *(ptr + i)
	ldr r6, [r1]	// r6 = *(ptr + i + 1)
	sub r7, r6, r5
	cmp r7, #0
	blt logic_2
	bge increment
logic_2:
	str r6, [r0]	// *(ptr + i) = *(ptr + i + 1)
	str r5, [r1]
	b increment
increment:
	add r0, r0, #4	// increment pointers
	add r1, r1, #4	
	pop {r5-r7, lr}
	bx lr
end:
	.end