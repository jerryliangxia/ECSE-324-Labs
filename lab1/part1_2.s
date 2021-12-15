 .global _start
	n: .word 6
_start:
	ldr r2, =n
	ldr r2, [r2]
	
	cmp r2, #0	// check if positive
	blt end
	
	push {r2}	// move argument into r2
	push {lr}
	bl fib
	pop {lr}
	
	b end
	
fib:

	push {r11}
	mov r11, sp			// push variables onto the stack
	
	ldr r2, [r11, #8]	// because r11 is accessible
	cmp r2, #0
	bgt else1	// since this is a branch, no need to bl x and bx lr back
	
	mov r0, #0	// return 0 in r0
	
	// de allocate, go back
	mov sp, r11
	pop {r11}
	
	bx lr
	
else1:
	cmp r2, #1
	bgt else2
	
	mov r0, #1	// return 1 in r0
	
	// de allocate, go back
	mov sp, r11
	pop {r11}
	
	bx lr
	
else2:	// in here lies the recursive call
	sub r2, r2, #1
	push {r2}
	
	push {lr}
	bl fib		// recursive call
	pop {lr}
	
	add sp, sp, #4	// or pop {r3}
	
	push {r0}
	
	ldr r2, [r11, #8]
	sub r2, r2, #2
	push {r2}	// access in call
	
	push {lr}
	bl fib		// recursive call
	pop {lr}
	
	add sp, sp, #4
	
	pop {r1}
	
	add r0, r1, r0
	
	mov sp, r11
	pop {r11}

	bx lr
	
end:
	.end