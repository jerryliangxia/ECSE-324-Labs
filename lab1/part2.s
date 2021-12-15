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
	ans1: .space 400
	
	y: .word 0
		
	iw: .word 10 // Image Width   = 10
	ih: .word 10 // Image Height  = 10
	kw: .word 5	 // Kernel Width  = 5
	kh: .word 5  // Kernel Height = 5
	ksw: .word 2 // Kernel Width Stride  = (Kernel Width-1)/2
	khw: .word 2 // Kernel Height Stride = (Kernel Height-1)/2
_start:

	//ldr r0, =arr1	// address of array (use temp register)
	//ldr r1, =ker1	// address of kernel (use temp register)
	
	//ldr r2, =ans1	// address of answer (to fill) (use temp register)
	
	//mov r0, #0		// (y)
	mov r1, #0		// (x)
	mov r2, #0		// (i)
	mov r3, #0		// (j)
	mov r4, #0		// (j)
	mov r5, #0		// (j)
	mov r6, #0		// (j)
	mov r7, #0		// (j)
	mov r8, #0		// (j)
	mov r9, #0		// (j)
	mov r10, #0
	mov r11, #0
	mov r12, #0

	
	//ldr r7, =ksw	// use temp register
	//ldr r7, [r7]	// use temp register
	
	//ldr r8, =khw	// use temp register
	//ldr r8, [r8]	// use temp register
	
	push {lr}
	bl y_loop
	pop {lr}
	
	b end
y_loop:
	// reset x
	mov r1, #0
	
	push {lr}
	bl x
	pop {lr}
	
	push {r7, r8}	// push onto stack
	ldr r8, =y	// get y's address
	mov r7, r8		// store r8's address into r7
	ldr r8, [r8]	// store y's value into r8
	add r8, r8, #1	// increment y's value
	push {r9}
	ldr r9, =ih
	ldr r9, [r9]
	cmp r8, r9	// compare
	pop {r9}
	str r8, [r7]	// store back r8 into =y with it's new value
	pop {r7, r8}	// pop off stack
	bne y_loop	// restart program
	
	bx lr

x:
	// reset i, sum
	mov r2, #0
	mov r0, #0
	
	push {lr}
	bl i
	pop {lr}
	
	
	// store
	push {r5,r6,r7}
	ldr r5, =y	// get y's address
	ldr r5, [r5]
	lsl r5, r5, #2	// multiply y by 4
	ldr r6, =ans1	// get ans address
	ldr r7, =iw	// get 10
	ldr r7, [r7]
	mul r7, r1, r7
	lsl r7, r7, #2
	add r7, r7, r5	// here we have y*10*4 + x*4
	str r0, [r6, r7]
	pop {r5,r6,r7}
	// store

	
	add r1, r1, #1	// lastly, increment (x++)
	push {r9}
	ldr r9, =iw
	ldr r9, [r9]
	cmp r1, r9
	pop {r9}
	bne x
		
	bx lr	// go back to y
		
i:
	// reset variables
	mov r3, #0
	push {lr}
	bl j
	pop {lr}
	
	add r2, r2, #1
	push {r9}
	ldr r9, =kw
	ldr r9, [r9]
	cmp r2, r9
	pop {r9}
	bne i

	
	
	bx lr	// go back to x
	
j:
	// logic
	push {lr}
	bl logic_1
	pop {lr}
	
	add r3, r3, #1	// increment
	push {r9}
	ldr r9, =kh
	ldr r9, [r9]
	cmp r3, r9
	pop {r9}
	bne j
	
	bx lr
	
logic_1:
	/* LOGIC */
	// compute and store temp1, temp2
	push {r11, r12}
	add r11, r1, r3		// temp1 = x + j
	push {r9}
	ldr r9, =ksw
	ldr r9, [r9]
	sub r11, r11, r9 	// temp1 = x + j - ksw
	pop {r9}
	
	push {r4}
	push {r9}
	ldr r4, =y
	ldr r4, [r4]
	add r12, r4, r2		// temp2 = y + i
	ldr r9, =khw
	ldr r9, [r9]
	sub r12, r12, r9	// temp2 = y + i - khw
	pop {r9}
	pop {r4}
	
	// if statement
	cmp r11, #0
	blt out
	cmp r11, #9
	bgt out
	
	cmp r12, #0
	blt out
	cmp r12, #9
	bgt out
	
	// get fx [temp1][temp2]
	// use r9, the temporary variable
	push {r9}
	push {r8}	// the memory variable
	
	ldr r8, =arr1	// address of array
	
	ldr r9, =iw
	ldr r9, [r9]		// get 10
	lsl r9, r9, #2		// multiply 10 by 4 to get 40
	mul r11, r11, r9	// mul temp1, temp1, #40
	add r11, r11, r12, lsl#2	// add temp1, temp1, temp2 (lsl #4)
	ldr r12, [r8, r11]	// mov temp2, [arr1, temp1]
	
	pop {r8}
	pop {r9}
	// fin
	
	// get kx[j][i]
	push {r9}
	push {r8}
	
	ldr r8, =ker1	// address of array
	
	ldr r9, =kw
	ldr r9, [r9]
	lsl r9, r9, #2	// intermediate step
	mul r9, r3, r9		// mul r9, j, #20
	add r9, r9, r2, lsl#2		// add r9, j*4*kw, i*4 (don't modify j!)
	ldr r11, [r8, r9]	// mov temp1, [ker1, r9]
	
	mul r11, r11, r12	// mul temp1 = temp1, temp2 (kx * fx)
	
	add r0, r0, r11		// store into return value (sum)
	
	pop {r8}
	pop {r9}
	/* LOGIC */ // calculates correctly!
	
	pop {r11, r12}
	
	bx lr	// go back to incrementing j
out:
	pop {r11, r12}
	bx lr	// go back to incrementing j
end:
	.end
	