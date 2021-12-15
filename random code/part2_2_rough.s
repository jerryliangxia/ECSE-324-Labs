.global _start
	
	// array
	arr1: .word 183, 207, 128, 30, 109, 0, 14, 52, 15, 210
	arr2: .word 228, 76, 48, 82, 179, 194, 22, 168, 58, 116
	arr3: .word 228, 217, 180, 181, 243, 65, 24, 127, 216, 118
	arr4: .word 64, 210, 138, 104, 80, 137, 212, 196, 150, 139
	arr5: .word 155, 154, 36, 254, 218, 65, 3, 11, 91, 95
	arr6: .word 219, 10, 45, 193, 204, 196, 25, 177, 188, 170
	arr7: .word 189, 241, 102, 237, 251, 223, 10, 24, 171, 71
	arr8: .word 0, 4, 81, 158, 59, 232, 155, 217, 181, 19
	arr9: .word 25, 12, 80, 244, 227, 101, 250, 103, 68, 46
	arr10: .word 136, 152, 144, 2, 97, 250, 47, 58, 214, 51
	
	
	// kernel
	ker1: .word 1,   1,  0,  -1,  -1
    ker2: .word 0,   1,  0,  -1,   0
    ker3: .word 0,   0,  1,   0,   0
    ker4: .word 0,  -1,  0,   1,   0
    ker5: .word -1, -1,  0,   1,   1
	
	// answer - allotted space
	//ans1: .space 40
	//ans2: .space 40
	//ans3: .space 40
	//ans4: .space 40
	//ans5: .space 40
	//ans6: .space 40
	//ans7: .space 40
	//ans8: .space 40
	//ans9: .space 40
	//ans10: .space 40
	ans1: .word 400
	
	iw: .word 10 // Image Width   = 10
	ih: .word 10 // Image Height  = 10
	kw: .word 5	 // Kernel Width  = 5
	kh: .word 5  // Kernel Height = 5
	ksw: .word 2 // Kernel Width Stride  = (Kernel Width-1)/2
	khw: .word 2 // Kernel Height Stride = (Kernel Height-1)/2
_start:

	ldr r0, =arr1	// address of array
	ldr r1, =ker1	// address of kernel
	
	ldr r2, =ans1	// address of answer (to fill)
	
	mov r3, #0		// address of ih (y)
	mov r4, #0		// address of iw (x)
	mov r5, #0		// " kw (i)
	mov r6, #0		// " kh (j)
	
	ldr r7, =ksw	// " ksw	// these are constants, so don't change!
	ldr r7, [r7]	// load ksw into r7
	
	ldr r8, =khw	// " khw	// these are constants, so don't change!
	ldr r8, [r8]	// load khw into r8
	
	// r9 is temporary
	
	// r10 is sum used in loop_iw
	push {pc}
	b loop_ih
		
loop_ih:
	// iterate here 10 times using r4
	//push {pc}	// starting point, always push to reach here
	bl loop_iw
	
	add r3, r3, #1
	ldr r9, =ih
	ldr r9, [r9]
	cmp r3, r9	// replace with r9 after
	push {pc}
	beq end
	pop {r9}	// junk
	
	pop {lr}	// pop to lr
	bx lr

loop_iw:
	// iterate here 10 times using r3
	push {lr}	// starting point
	
	mov r10, #0
	bl loop_kw
	
	
	/* LOGIC */
	// can use r11, r12 now
	mov r11, #40					// intermediate step
	mul r11, r4, r11	// mul temp1, x, #40
	add r11, r11, r3	// add temp1, temp1, y
	str r10, [r2, r11]	// str sum [ans1, temp1]
	/* LOGIC */

	// after process
	add r4, r4, #1
	ldr r9, =iw
	ldr r9, [r9]
	cmp r4, r9
	push {pc}
	beq reload_iw
	pop {r9}	// junk
	
	pop {lr}	// pop to loop_ih
	bx lr
		
loop_kw:
	push {lr}
	bl loop_kh
	
	add r5, r5, #1	// r5 -> kw
	ldr r9, =kw
	ldr r9, [r9]
	cmp r5, r9
	push {pc}
	beq reload_kw
	pop {r9}	// junk
	
	pop {lr}	// pop to loop_iw
	bx lr
	
loop_kh:
	push {lr}
	
	/* LOGIC */
	// compute and store temp1, temp2
	add r11, r4, r6		// temp1 = x + j
	sub r11, r11, r7 	// temp1 = x + j - ksw
	
	add r12, r3, r5		// temp2 = y + i
	sub r12, r12, r8	// temp2 = y + i - khw
	
	// if statement
	cmp r11, #0
	blt out
	cmp r11, #9
	bgt out
	
	cmp r12, #0
	blt out
	cmp r12, #9
	bgt out
	
	// use r9, the temporary variable
	mov r9, #40
	mul r11, r11, r9	// mul temp1, temp1, #40
	add r11, r11, r12	// add temp1, temp1, temp2
	ldr r12, [r0, r11]	// mov temp2, [r0, temp1]
	
	mov r9, #20
	mul r9, r6, r9		// mul r9, j, #20
	add r9, r6, r5		// add r9, j, i (don't modify j!)
	ldr r11, [r1, r9]	// mov temp1, [r1, r9]
	
	mul r11, r11, r12	// mul temp1, temp1, temp2 (kx * fx)
	add r10, r10, r11	// add sum, sum, temp1 -> all to compute sum, done now
	/* LOGIC */
	
	
	// after process
	add r6, r6, #1	// r6 -> kh
	ldr r9, =kw
	ldr r9, [r9]
	cmp r6, r9
	push {pc}
	beq reload_kh
	pop {r9}	// junk
	
	pop {lr}	// go to start
	bx lr
reload_ih:
	mov r3, #0
	pop {lr}
	push {lr}
	bx lr
reload_iw:
	mov r4, #0
	pop {lr}
	push {lr}
	bx lr
reload_kw:
	mov r5, #0
	pop {lr}
	push {lr}
	bx lr
reload_kh:
	mov r6, #0
	pop {lr}
	push {lr}
	bx lr
out:
	// after process
	add r6, r6, #1	// r6 -> kh
	ldr r9, =kw
	ldr r9, [r9]
	cmp r6, r9
	push {pc}
	beq reload_kh
	pop {r9}	// junk
	
	pop {lr}
	bx lr
end:
	.end
	