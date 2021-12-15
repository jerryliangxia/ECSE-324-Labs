.global _start

	n: .word 6	// store the variable n here, pass this into the LOOP
_start:

	// initialize all starter variables
	MOV R0, #0	// f[0] = 0
	MOV R1, #1  // f[1] = 1
	
	// load variable from n into r3, which we will use to decrement and 
	// return final result
	LDR R3, =n
	LDR R3, [R3]
	
	cmp r3, #0
	blt end
	
	push {lr}
	BL LOOP	// go to loop
	pop {lr}
	
	b end
LOOP:
	// if R4 is not equal to 0
	// we have 3 registers to store values
	// r0: prev prev
	// r1: prev
	// r2: is the result of r0 + r1
	// so we: compute r0 + r1, store that into r2 (1)
	// we store r1 into r0, making prev prev contain prev's value (2)
	// we store r2 into r1, making prev's value contain the new value (3)
	// and we start this all from 0 and 1 (r0 and r1, respectively)
	ADD R2, R1, R0 // (1)
	MOV R0, R1 // (2)
	MOV R1, R2 // (3)
	SUB R3, R3, #1 // decrement counter
	CMP R3, #1 // done when n-1 iterations occur
	BNE LOOP // start over if condition above is not met
	// final result is stored into R1 (or R0)
	mov r0, r1
	bx lr
end:	// end of program
	.end
	
	