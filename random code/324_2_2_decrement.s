.global _start
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
	ans1: .space 40
	ans2: .space 40
	ans3: .space 40
	ans4: .space 40
	ans5: .space 40
	ans6: .space 40
	ans7: .space 40
	ans8: .space 40
	ans9: .space 40
	ans10: .space 40
	
	iw: .word 10 // Image Width   = 10
	ih: .word 10 // Image Height  = 10
	kw: .word 5	 // Kernel Width  = 5
	kh: .word 5  // Kernel Height = 5
	ksw: .word 2 // Kernel Width Stride  = (Kernel Width-1)/2
	khw: .word 2 // Kernel Height Stride = (Kernel Height-1)/2
_start:
	ldr r0, =arr	// address of array
	ldr r1, =ker1	// address of kernel
	
	ldr r2, =ans1	// address of answer (to fill)
	
	ldr r3, =iw		// address of iw
	ldr r3, [r3]	// load iw into r3
	
	ldr r4, =ih		// address of ih
	ldr r4, [r4]	// load ih into r4
	
	ldr r5, =kw		// " kw
	ldr r5, [r5]	// road kw into r5
	
	ldr r6, =kh		// " kh
	ldr r6, [r6]	// load kh into r6
	
	ldr r7, =ksw	// " ksw
	ldr r7, [r7]	// load ksw into r7
	
	ldr r8, =khw	// " khw
	ldr r8, [r8]	// load khw into r8
	
	push {lr}
	bl loop_ih
	
	b end
	
loop_ih:
	// iterate here 10 times using r4
	sub r4, r4, #1
	cmp r4, 0
	beq reload_ih
	
	push {lr}
	bl loop_iw
	
	pop {lr}	// pop to start (and then branch to end)

loop_iw:
	// iterate here 10 times using r3
	sub r3, r3, #1
	cmp r3, #0
	beq reload_iw
	
	mov r9, #0	// sum = 0 every time the loop starts
	
	push {lr}
	bl loop_kw
	
	pop {lr}	// pop to loop_ih
		
loop_kw:
	sub r5, r5, #1	// r5 -> kw
	cmp r5, #0
	beq reload_kw
	
	push {lr}
	bl loop_kh
	
	pop {lr}	// pop to loop_iw
	
loop_kh:
	sub r6, r6, #1	// r6 -> kh
	cmp r6, #0
	beq reload_kh
	
	// push {lr}	// maybe not necessary here?
	
	add r9, r3, 	
	pop {lr}	// pop to loop_kw
	
reload_ih:
	ldr r3, =iw
	ldr r3, [r3]
	bx lr
reload_iw:
	ldr r4, =ih
	ldr r4, [r4]
	bx lr
reload_kw:
	ldr r5, =kw
	ldr r5, [r5]
	bx lr
reload_kh:
	ldr r6, =kh
	ldr r6, [r6]
	bx lr
reload_kw:
	ldr r5, =kw
	ldr r5, [r5]
	bx lr
reload_kh:
	ldr r6, =kh
	ldr r6, [r6]
	bx lr
end:
	.end
	
	
	