.section .vectors, "ax"
B _start
B SERVICE_UND       // undefined instruction vector
B SERVICE_SVC       // software interrupt vector
B SERVICE_ABT_INST  // aborted prefetch vector
B SERVICE_ABT_DATA  // aborted data vector
.word 0 // unused vector
B SERVICE_IRQ       // IRQ interrupt vector
B SERVICE_FIQ       // FIQ interrupt vector
.text
.global _start
	PB_int_flag: .word 0x0
	tim_int_flag: .word 0x0
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
    /* Set up stack pointers for IRQ and SVC processor modes */
    MOV        R1, #0b11010010      // interrupts masked, MODE = IRQ
    MSR        CPSR_c, R1           // change to IRQ mode
    LDR        SP, =0xFFFFFFFF - 3  // set IRQ stack to A9 onchip memory
    /* Change to SVC (supervisor) mode with interrupts disabled */
    MOV        R1, #0b11010011      // interrupts masked, MODE = SVC
    MSR        CPSR, R1             // change to supervisor mode
    LDR        SP, =0x3FFFFFFF - 3  // set SVC stack to top of DDR3 memory
    BL     CONFIG_GIC           // configure the ARM GIC
		
	push {r0-r5}	// To DO: doesn't work???
	mov r0, #29
	mov r1, #0xff
	BIC R4, R0, #3    // R4 = reg_offset (r0 is the clock)
    LDR R2, =0xFFFED400
    ADD R4, R2, R4    // R4 = word address of ICDIPR
    AND R2, R0, #0x3  // N mod 4
    ADD R4, R2, R4    // R4 = byte address in ICDIPR
	/* Using register address in R4 and the value in R2 write to
	* (only) the appropriate byte */
    STRB R1, [R4]
    POP {R0-R5}		// end To DO
	
    // To DO: write to the pushbutton KEY interrupt mask register
    // Or, you can call enable_PB_INT_ASM subroutine from previous task
    // to enable interrupt for ARM A9 private timer, use ARM_TIM_config_ASM subroutine
    LDR        R0, =0xFF200050      // pushbutton KEY base address
    MOV        R1, #0xF             // set interrupt mask bits
    STR        R1, [R0, #0x8]       // interrupt mask register (base + 8)
    // enable IRQ interrupts in the processor
	
	// enable interrupt for ARM A9 private timer
	push {lr}
	bl ARM_TIM_config_ASM_init
	pop {lr}
	

    MOV        R0, #0b01010011      // IRQ unmasked, MODE = SVC
    MSR        CPSR_c, R0
	
	mov r0, #63
	mov r1, #0x10
	push {lr}				// clear
	bl HEX_clear_ASM
	pop {lr}
	
	// light up all hex
	mov r0, #63	// address of all
	mov r1, #0	// place a 0 in the hex
	push {lr}
	bl HEX_flood_ASM
	pop {lr}
	
	push {lr}
	bl PB_clear_edgecp_ASM
	pop {lr}
	
	/* end set up */
IDLE:
    B IDLE // This is where you write your objective task
/*--- Undefined instructions ---------------------------------------- */
SERVICE_UND:
    B SERVICE_UND
/*--- Software interrupts ------------------------------------------- */
SERVICE_SVC:
	B SERVICE_SVC
/*--- Aborted data reads -------------------------------------------- */
SERVICE_ABT_DATA:
    B SERVICE_ABT_DATA
/*--- Aborted instruction fetch ------------------------------------- */
SERVICE_ABT_INST:
    B SERVICE_ABT_INST
/*--- IRQ ----------------------------------------------------------- */
SERVICE_IRQ:
    PUSH {R0-R7, LR}
/* Read the ICCIAR from the CPU Interface */
    LDR R4, =0xFFFEC100
    LDR R5, [R4, #0x0C] // read from ICCIAR
	cmp r5, #29
	beq Timer_check
	cmp r5, #73
	beq Pushbutton_check
	bne UNEXPECTED

/* To Do: Check which interrupt has occurred (check interrupt IDs)
   Then call the corresponding ISR
   If the ID is not recognized, branch to UNEXPECTED
   See the assembly example provided in the De1-SoC Computer_Manual on page 46 */
ARM_TIM_read_INT_ASM:
	ldr r0, =INTERRUPT_STATUS
	ldr r0, [r0]
	bx lr
Pushbutton_check:
    B KEY_ISR
Timer_check:
	B ARM_TIM_ISR
UNEXPECTED:
	B UNEXPECTED	// if not recognised, stop here
EXIT_IRQ:
/* Write to the End of Interrupt Register (ICCEOIR) */
    STR R5, [R4, #0x10] // write to ICCEOIR
    POP {R0-R7, LR}
	SUBS PC, LR, #4
/*--- FIQ ----------------------------------------------------------- */
SERVICE_FIQ:
    B SERVICE_FIQ
CONFIG_GIC:
    PUSH {LR}
/* To configure the FPGA KEYS interrupt (ID 73):
* 1. set the target to cpu0 in the ICDIPTRn register
* 2. enable the interrupt in the ICDISERn register */
/* CONFIG_INTERRUPT (int_ID (R0), CPU_target (R1)); */
/* To Do: you can configure different interrupts
   by passing their IDs to R0 and repeating the next 3 lines */
   	mov r0, #29            // CLOCK (Interrupt ID = 29)
    mov r1, #1             // this field is a bit-mask; bit 0 targets cpu0
    bl CONFIG_INTERRUPT
	
    MOV R0, #73            // KEY port (Interrupt ID = 73)
    MOV R1, #1             // this field is a bit-mask; bit 0 targets cpu0
    BL CONFIG_INTERRUPT

/* configure the GIC CPU Interface */
    LDR R0, =0xFFFEC100    // base address of CPU Interface
/* Set Interrupt Priority Mask Register (ICCPMR) */
    LDR R1, =0xFFFF        // enable interrupts of all priorities levels
    STR R1, [R0, #0x04]
/* Set the enable bit in the CPU Interface Control Register (ICCICR).
* This allows interrupts to be forwarded to the CPU(s) */
    MOV R1, #1
    STR R1, [R0]
/* Set the enable bit in the Distributor Control Register (ICDDCR).
* This enables forwarding of interrupts to the CPU Interface(s) */
    LDR R0, =0xFFFED000
    STR R1, [R0]
    POP {PC}

/*
* Configure registers in the GIC for an individual Interrupt ID
* We configure only the Interrupt Set Enable Registers (ICDISERn) and
* Interrupt Processor Target Registers (ICDIPTRn). The default (reset)
* values are used for other registers in the GIC
* Arguments: R0 = Interrupt ID, N
* R1 = CPU target
*/
CONFIG_INTERRUPT:
    PUSH {R4-R5, LR}
/* Configure Interrupt Set-Enable Registers (ICDISERn).
* reg_offset = (integer_div(N / 32) * 4
* value = 1 << (N mod 32) */
    LSR R4, R0, #3    // calculate reg_offset
    BIC R4, R4, #3    // R4 = reg_offset
    LDR R2, =0xFFFED100
    ADD R4, R2, R4    // R4 = address of ICDISER
    AND R2, R0, #0x1F // N mod 32
    MOV R5, #1        // enable
    LSL R2, R5, R2    // R2 = value
/* Using the register address in R4 and the value in R2 set the
* correct bit in the GIC register */
    LDR R3, [R4]      // read current register value
    ORR R3, R3, R2    // set the enable bit
    STR R3, [R4]      // store the new register value
/* Configure Interrupt Processor Targets Register (ICDIPTRn)
* reg_offset = integer_div(N / 4) * 4
* index = N mod 4 */
    BIC R4, R0, #3    // R4 = reg_offset
    LDR R2, =0xFFFED800
    ADD R4, R2, R4    // R4 = word address of ICDIPTR
    AND R2, R0, #0x3  // N mod 4
    ADD R4, R2, R4    // R4 = byte address in ICDIPTR
/* Using register address in R4 and the value in R2 write to
* (only) the appropriate byte */
    STRB R1, [R4]
    POP {R4-R5, PC}
ARM_TIM_ISR:
	push {r0, r1}
	ldr r0, =PB_int_flag	// write a 1
	mov r1, #1
	str r1, [r0]
	// then, clear the interrupt status by writing a 1 to it
	push {lr}
	bl ARM_TIM_clear_INT_ASM
	pop {lr}
	
	ldr r0, =PB_int_flag	// write a 0 - is this necessary?
	mov r1, #0
	str r1, [r0]
	pop {r0, r1}
	
	push {lr}
	bl _reset
	pop {lr}
	
	b EXIT_IRQ
KEY_ISR:
    LDR R0, =0xFF200050    // base address of pushbutton KEY port
    LDR R1, [R0, #0xC]     // read edge capture register
    MOV R2, #0xF
    STR R2, [R0, #0xC]     // clear the interrupt
CHECK_KEY0:
    //MOV R3, #0x1
    //ANDS R3, R3, R1        // check for KEY0
	cmp r1, #0x1
	beq start_timer
	b CHECK_KEY1
start_timer:
	push {r0, r1}
	ldr r1, =LOAD
	mov r0, #7				// don't let it start yet
	str r0, [r1, #8]		//  Start the timer continuing with interrupts
	pop {r0, r1}
	
	//beq reset_timer	// should be renamed to stop
	b END_KEY_ISR
CHECK_KEY1:
    //MOV R3, #0x2
    //ANDS R3, R3, R1        // check for KEY1
	cmp r1, #0x2
    beq pause
	b CHECK_KEY2
pause:
	/* stop the timer */
	push {r0, r1}
	ldr r1, =LOAD
	mov r0, #6				// don't let it start yet
	str r0, [r1, #8]		//  Start the timer continuing with interrupts
	pop {r0, r1}
	/* stop the timer */
    b END_KEY_ISR
CHECK_KEY2:
    //MOV R3, #0x4
    //ANDS R3, R3, R1        // check for KEY2
	cmp r1, #0x4
    beq reset_timer
END_KEY_ISR:
	push {lr}
	bl PB_clear_edgecp_ASM
	pop {lr}
	
	b EXIT_IRQ
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
	
	push {lr}
	bl ARM_TIM_config_ASM
	pop {lr}
	
	b EXIT_IRQ
write_LEDs_ASM:
	push {r2}
    ldr r2, =LED_MEMORY
    str r1, [r2]
	pop {r2}
    bx  lr
	
_reset:	// the normal increment
	/* HEX0 display */
	mov r0, #0b10	// clear the second display (from right)
	ldr r1, =count
	ldr r1, [r1]
	
	add r1, r1, #1
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
	
	bx  lr			// go back to the beginning
	
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
	
	bx  lr
	
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
	
	bx  lr
	
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
	
	bx  lr
	
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
	
	bx  lr
	
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
	
	bx  lr	// branches back to the ARM_TIM function
	
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
PB_enable_edgecp_ASM:
	ldr r1, =INTERRUPT_MASK
	str r0, [r1]
	bx lr
PB_clear_edgecp_ASM:
	push {r1}
	ldr r1, =PUSH_DATA_EDGE
	ldr r0, [r1]
	str r0, [r1]
	pop {r1}
	bx lr
ARM_TIM_config_ASM_init:
	push {r0, r1, r2}
	ldr r0, =loadValue
	ldr r1, =LOAD			// r0 contains the base address for the timer 
	str r0, [r1]			// Set the period to be 500,000,000 clock cycles 
	
	mov r0, #6				// don't let it start yet
	str r0, [r1, #8]		//  Start the timer continuing with interrupts 
	pop {r0, r1, r2}
	bx lr

ARM_TIM_config_ASM:
	push {r0, r1, r2}
	movw r0, #0xf080		// load bits - value of 50,000,000 or
	movt r0, #0x02fa    	// 2FAF080 (for 10 ms)
	ldr r1, =LOAD			// r0 contains the base address for the timer 
	str r0, [r1]			// Set the period to be 500,000,000 clock cycles 

	mov r0, #7				// don't let it start yet
	str r0, [r1, #8]		//  Start the timer continuing with interrupts
	pop {r0, r1, r2}
	bx lr
	
ARM_TIM_clear_INT_ASM:
	push {r1}
	ldr r1, =INTERRUPT_STATUS
	mov r0, #1
	str r0, [r1]			// write a 1 to F to reset it
	pop {r1}
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