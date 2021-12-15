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
	.equ ps2_driver, 0xff200100
	.equ pixel_buffer, 0xc8000000
	.equ char_buffer, 0xc9000000
	.equ x_limit, 320
	.equ y_limit, 240
	.equ x_limit2, 80
	.equ y_limit2, 60
	
	.equ oneposition, 3372222103
	.equ twoposition, 3372222119
	.equ threeposition, 3372222135
	.equ fourposition, 3372224151
	.equ fiveposition, 3372224167
	.equ sixposition, 3372224183
	.equ sevenposition, 3372226199
	.equ eightposition, 3372226215
	.equ nineposition, 3372226231
	.equ playertracker, 3372221002
	.equ diagonal, 273

	cur_player: .word 1	// initial player is x
	one_hot_x: .word 0
	one_hot_o: .word 0
	detected: .word 0
	
	count: .word 0
	
_start:
	// poll the keyboard
	
	mov r0, #0
	mov r1, #0
	mov r2, #1584	// black -> or -> 1584
	push {lr}
	bl VGA_clear_pixelbuff_ASM
	pop {lr}
	
	push {lr}
	bl VGA_clear_charbuff_ASM
	pop {lr}
	
	ldr r2, =playertracker
	mov r1, #0x50	//P
	strb r1, [r2, #-14]
	mov r1, #0x72	//r
	strb r1, [r2, #-13]
	mov r1, #0x65	//e
	strb r1, [r2, #-12]
	mov r1, #0x73	//s
	strb r1, [r2, #-11]
	mov r1, #0x73	//s
	strb r1, [r2, #-10]
	mov r1, #0x30	//0
	strb r1, [r2, #-7]
	mov r1, #0x21	//!
	strb r1, [r2, #-6]

poll:
	
	ldr r0, =ps2_driver
	ldrh r0, [r0]
	cmp r0, #0x45
	beq _start_
	
	b poll
_start_:

	push {lr}
	bl VGA_clear_charbuff_ASM
	pop {lr}
	
	mov r0, #0
	mov r1, #0
	mov r2, #1020	// blue
	push {lr}
	bl VGA_clear_pixelbuff_ASM
	pop {lr}
	
	ldr r2, =playertracker
	push {lr}
	bl VGA_clear_charbuff_ASM
	pop {lr}
	
	mov r0, #125
	mov r1, #16
	mov r2, #0
	push {lr}
	bl j_loop_pixbuff2
	pop {lr}
	
	mov r0, #124
	mov r1, #16
	mov r2, #0
	push {lr}
	bl j_loop_pixbuff2
	pop {lr}
	
	mov r0, #194
	mov r1, #16
	push {lr}
	bl j_loop_pixbuff2
	pop {lr}
	mov r0, #193
	mov r1, #16
	push {lr}
	bl j_loop_pixbuff2
	pop {lr}
	
	mov r0, #56
	mov r1, #85
	push {lr}
	bl i_loop_pixbuff2
	pop {lr}
	mov r0, #56
	mov r1, #86
	push {lr}
	bl i_loop_pixbuff2
	pop {lr}
	
	mov r0, #56
	mov r1, #154
	push {lr}
	bl i_loop_pixbuff2
	pop {lr}
	mov r0, #56
	mov r1, #155
	push {lr}
	bl i_loop_pixbuff2
	pop {lr}
	
	ldr r2, =playertracker
	
	push {lr}
	bl clear_corner
	pop {lr}
	
	push {lr}
	bl write_player_1_turn
	pop {lr}
	// player 1 is 1 -> X. Player 2 is 0 -> O.
	
    /* Set up stack pointers for IRQ and SVC processor modes */
    MOV        R1, #0b11010010      // interrupts masked, MODE = IRQ
    MSR        CPSR_c, R1           // change to IRQ mode
    LDR        SP, =0xFFFFFFFF - 3  // set IRQ stack to A9 onchip memory
    /* Change to SVC (supervisor) mode with interrupts disabled */
    MOV        R1, #0b11010011      // interrupts masked, MODE = SVC
    MSR        CPSR, R1             // change to supervisor mode
    LDR        SP, =0x3FFFFFFF - 3  // set SVC stack to top of DDR3 memory
    BL     CONFIG_GIC           // configure the ARM GIC
	
    // To DO: set the enable bit for interrupts to true
    ldr        r0, =0xFF200104      // keyboard KEY base address
    mov        r1, #0x1             // set interrupt mask bit
    str        r1, [r0]       		// interrupt mask register
    // enable IRQ interrupts in the processor
	
    MOV        R0, #0b01010011      // IRQ unmasked, MODE = SVC
    MSR        CPSR_c, R0
	
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
	
	// check for key
	cmp r5, #79
	beq PS2_ISR
/* To Do: Check which interrupt has occurred (check interrupt IDs)
   Then call the corresponding ISR
   If the ID is not recognized, branch to UNEXPECTED
   See the assembly example provided in the De1-SoC Computer_Manual on page 46 */
UNEXPECTED:
	B UNEXPECTED	// if not recognised, stop here
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
   
   // interrupt for keyboard
   	mov r0, #79            // PS/2 (Interrupt ID = 79)
    mov r1, #1             // this field is a bit-mask; bit 0 targets cpu0
    bl CONFIG_INTERRUPT

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
	
PS2_ISR:
// first, clear the interrupt. r1 has the value
    ldr r0, =0xFF200100    	// base address of pushbutton KEY port
	/* */
    ldrb r1, [r0]     		// get first 8 bits of PS2_DATA
	ldr r2, =detected
	ldr r0, [r2]
	cmp r0, #2
	beq CHECK_KEY0
	add r0, r0, #1
	str r0, [r2]
	b EXIT_IRQ
	/* */
	
CHECK_KEY0:
	/* */
	ldr r2, =detected
	mov r0, #0
	str r0, [r2]
	/* */
	cmp r1, #0x45
	beq reset_everything
CHECK_KEY1:
	cmp r1, #0x16
	mov r0, #1
	ldreq r2, =oneposition
	beq draw_symbol_at_pos
CHECK_KEY2:
	cmp r1, #0x1e
	mov r0, #2
	ldreq r2, =twoposition
	beq draw_symbol_at_pos
CHECK_KEY3:
	cmp r1, #0x26
	mov r0, #3
	ldreq r2, =threeposition
	beq draw_symbol_at_pos
CHECK_KEY4:
	cmp r1, #0x25
	mov r0, #4
	ldreq r2, =fourposition
	beq draw_symbol_at_pos
CHECK_KEY5:
	cmp r1, #0x2e
	mov r0, #5
	ldreq r2, =fiveposition
	beq draw_symbol_at_pos
CHECK_KEY6:
	cmp r1, #0x36
	mov r0, #6
	ldreq r2, =sixposition
	beq draw_symbol_at_pos
CHECK_KEY7:
	cmp r1, #0x3d
	mov r0, #7
	ldreq r2, =sevenposition
	beq draw_symbol_at_pos
CHECK_KEY8:
	cmp r1, #0x3e
	mov r0, #8
	ldreq r2, =eightposition
	beq draw_symbol_at_pos
CHECK_KEY9:
	cmp r1, #0x46
	mov r0, #9
	ldreq r2, =nineposition
	beq draw_symbol_at_pos
draw_symbol_at_pos:
// r2 -> coordinates, need to check if correct
// check if player 1 or player 2
	ldrb r3, [r2]
	cmp r3, #0
	bne EXIT_IRQ	// leave if already has data
	
	push {r4}
	ldr r4, =cur_player
	ldr r3, [r4]
	cmp r3, #1
	beq draw_x
	// draw an O
	push {lr}
	bl draw_an_O
	pop {lr}
	// draw an O
	mov r1, #1	// change to X
	str r1, [r4]
	mov r1, #0x79
	push {r0}
	ldr r2, =playertracker
	push {lr}
	bl write_player_1_turn
	pop {lr}
	pop {r0}
	pop {r4}
	b UPDATE_ONE_HOT_O
draw_x:	
	// draw an X
	push {lr}
	bl draw_an_X
	pop {lr}
	// draw an X
	mov r1, #0	// change to O's turn
	str r1, [r4]
	mov r1, #0x43
	push {r0}
	ldr r2, =playertracker
	push {lr}
	bl write_player_2_turn
	pop {lr}
	pop {r0}
	pop {r4}
	b UPDATE_ONE_HOT_X
UPDATE_ONE_HOT_O:
	push {r4, r5}
	ldr r2, =one_hot_o
	ldr r5, [r2]
	mov r1, #1
	sub r0, r0, #1
	lsl r1, r1, r0
	add r5, r5, r1
	str r5, [r2]
	mov r2, r5
	b test_match
UPDATE_ONE_HOT_X:
	push {r4, r5}
	ldr r2, =one_hot_x
	ldr r5, [r2]
	mov r1, #1
	sub r0, r0, #1
	lsl r1, r1, r0
	add r5, r5, r1
	str r5, [r2]
	mov r2, r5
	
	ldr r4, =count
	ldr r3, [r4]
	add r3, r3, #1
	str r3, [r4]
	
	b test_match
	
test_match:
	and r4, r5, #0b001001001	// works
	cmp r4, #0b001001001
	beq found_winner
	
	and r4, r5, #0b010010010	// works
	cmp r4, #0b010010010
	beq found_winner
	
	and r4, r5, #0b100100100	// works
	cmp r4, #0b100100100
	beq found_winner
	
	and r4, r5, #0b000000111	// works
	cmp r4, #0b000000111
	beq found_winner
	
	and r4, r5, #0b000111000	// works
	cmp r4, #0b000111000
	beq found_winner
	
	and r4, r5, #0b111000000	// works
	cmp r4, #0b111000000
	beq found_winner
	
	ldr r3, =diagonal			// works
	and r4, r5, r3
	cmp r4, r3
	beq found_winner
	
	and r4, r5, #0b001010100	// works
	cmp r4, #0b001010100
	beq found_winner
	
	ldr r5, =count
	ldr r5, [r5]
	cmp r5, #5
	beq draw_between_players
	
	pop {r4, r5}
	b EXIT_IRQ
draw_between_players:
	ldr r2, =playertracker
	push {lr}
	bl clear_corner
	pop {lr}
	mov r1, #0x44
	strb r1, [r2, #-14]
	mov r1, #0x72
	strb r1, [r2, #-13]
	mov r1, #0x61
	strb r1, [r2, #-12]
	mov r1, #0x77
	strb r1, [r2, #-11]
	mov r1, #0x21
	strb r1, [r2, #-10]
	pop {r4, r5}
	b EXIT_IRQ
	
found_winner:
// get player who just played, so:
// if 0 -> display player O (2) as winner -> player 2 wins!
// if 1 -> display player X (1) as winner -> player 1 wins!
	pop {r4, r5}
	ldr r0, =cur_player
	ldr r2, [r0]
	cmp r2, #1
	ldr r2, =playertracker
	bne found_x
// O WINS
	push {lr}
	bl clear_corner_2
	pop {lr}
	push {lr}
	bl write_winner_o
	pop {lr}
	b EXIT_IRQ
	
found_x:
// X WINS
	push {lr}
	bl clear_corner_2
	pop {lr}
	push {lr}
	bl write_winner_x
	pop {lr}
	//mov r1, #0x79 // an X
	//strb r1, [r0]
	b EXIT_IRQ
write_winner_x:
	push {lr}
	bl VGA_clear_charbuff_ASM
	pop {lr}
	
	mov r1, #0x50	//P
	strb r1, [r2, #-14]
	mov r1, #0x6c	//l
	strb r1, [r2, #-13]
	mov r1, #0x61	//a
	strb r1, [r2, #-12]
	mov r1, #0x79	//y
	strb r1, [r2, #-11]
	mov r1, #0x65	//e
	strb r1, [r2, #-10]
	mov r1, #0x72	//r
	strb r1, [r2, #-9]
	mov r1, #0x31	//1
	strb r1, [r2, #-7]
	mov r1, #0x0
	strb r1, [r2, #-6]
	mov r1, #0x77
	strb r1, [r2, #-5]
	mov r1, #0x69
	strb r1, [r2, #-4]
	mov r1, #0x6e
	strb r1, [r2, #-3]
	mov r1, #0x73
	strb r1, [r2, #-2]
	mov r1, #0x21
	strb r1, [r2, #-1]
	mov r1, #0x0
	strb r1, [r2]
	
	mov r0, #0
	mov r1, #0
	mov r2, #768	// black -> or -> 1584
	push {lr}
	bl VGA_clear_pixelbuff_ASM
	pop {lr}
	
	bx lr
write_winner_o:
	push {lr}
	bl VGA_clear_charbuff_ASM
	pop {lr}
	
	mov r1, #0x50	//P
	strb r1, [r2, #-14]
	mov r1, #0x6c	//l
	strb r1, [r2, #-13]
	mov r1, #0x61	//a
	strb r1, [r2, #-12]
	mov r1, #0x79	//y
	strb r1, [r2, #-11]
	mov r1, #0x65	//e
	strb r1, [r2, #-10]
	mov r1, #0x72	//r
	strb r1, [r2, #-9]
	mov r1, #0x32	//2
	strb r1, [r2, #-7]
	mov r1, #0x0
	strb r1, [r2, #-6]
	mov r1, #0x77
	strb r1, [r2, #-5]
	mov r1, #0x69
	strb r1, [r2, #-4]
	mov r1, #0x6e
	strb r1, [r2, #-3]
	mov r1, #0x73
	strb r1, [r2, #-2]
	mov r1, #0x21
	strb r1, [r2, #-1]
	mov r1, #0x0
	strb r1, [r2]
	
	mov r0, #0
	mov r1, #0
	mov r2, #768	// black -> or -> 1584
	push {lr}
	bl VGA_clear_pixelbuff_ASM
	pop {lr}
	
	bx lr
reset_everything:
	// loads new values into all variables at the global start
	ldr r0, =count
	mov r1, #0
	str r1, [r0]
	
	ldr r0, =one_hot_x
	mov r1, #0
	str r1, [r0]
	
	ldr r0, =one_hot_o
	mov r1, #0
	str r1, [r0]
	
	ldr r0, =cur_player
	mov r1, #1
	str r1, [r0]
	
	STR R5, [R4, #0x10] // write to ICCEOIR
    POP {R0-R7, LR}
	b _start_
	
EXIT_IRQ:
/* Write to the End of Interrupt Register (ICCEOIR) */
    STR R5, [R4, #0x10] // write to ICCEOIR
    POP {R0-R7, LR}
	SUBS PC, LR, #4
clear_corner_2:
	mov r1, #0x0
	strb r1, [r2, #-7]
	strb r1, [r2, #-6]
	strb r1, [r2, #-5]
	strb r1, [r2, #-4]
	strb r1, [r2, #-3]
	strb r1, [r2, #-2]
	strb r1, [r2, #-1]
	strb r1, [r2]
	bx lr
clear_corner:
	mov r1, #0x0
	strb r1, [r2, #-14]
	strb r1, [r2, #-13]
	strb r1, [r2, #-12]
	strb r1, [r2, #-11]
	strb r1, [r2, #-10]
	strb r1, [r2, #-9]
	strb r1, [r2, #-8]
	strb r1, [r2, #-7]
	strb r1, [r2, #-6]
	strb r1, [r2, #-5]
	strb r1, [r2, #-4]
	strb r1, [r2, #-3]
	strb r1, [r2, #-2]
	strb r1, [r2, #-1]
	strb r1, [r2]
	bx lr
write_player_1_turn:
	mov r1, #0x50	//P
	strb r1, [r2, #-14]
	mov r1, #0x6c	//l
	strb r1, [r2, #-13]
	mov r1, #0x61	//a
	strb r1, [r2, #-12]
	mov r1, #0x79	//y
	strb r1, [r2, #-11]
	mov r1, #0x65	//e
	strb r1, [r2, #-10]
	mov r1, #0x72	//r
	strb r1, [r2, #-9]
	mov r1, #0x31	//1
	strb r1, [r2, #-7]
	mov r1, #0x27	//'
	strb r1, [r2, #-6]
	mov r1, #0x73	//s
	strb r1, [r2, #-5]
	mov r1, #0x74	//t
	strb r1, [r2, #-3]
	mov r1, #0x75	//u
	strb r1, [r2, #-2]
	mov r1, #0x72	//r
	strb r1, [r2, #-1]
	mov r1, #0x6e	//n
	strb r1, [r2]
	bx lr
write_player_2_turn:
	mov r1, #0x50	//P
	strb r1, [r2, #-14]
	mov r1, #0x6c	//l
	strb r1, [r2, #-13]
	mov r1, #0x61	//a
	strb r1, [r2, #-12]
	mov r1, #0x79	//y
	strb r1, [r2, #-11]
	mov r1, #0x65	//e
	strb r1, [r2, #-10]
	mov r1, #0x72	//r
	strb r1, [r2, #-9]
	mov r1, #0x32	//1
	strb r1, [r2, #-7]
	mov r1, #0x27	//'
	strb r1, [r2, #-6]
	mov r1, #0x73	//s
	strb r1, [r2, #-5]
	mov r1, #0x74	//t
	strb r1, [r2, #-3]
	mov r1, #0x75	//u
	strb r1, [r2, #-2]
	mov r1, #0x72	//r
	strb r1, [r2, #-1]
	mov r1, #0x6e	//n
	strb r1, [r2]
	bx lr
	
draw_an_X:
	// draw an X
	mov r1, #0xf
	strb r1, [r2]
	mov r1, #0x5c
	strb r1, [r2, #-129]
	strb r1, [r2, #129]
	mov r1, #0x2f
	strb r1, [r2, #-127]
	strb r1, [r2, #127]
	bx lr
	// draw an X
	
draw_an_O:
	// draw an O
	mov r1, #0x2b
	strb r1, [r2, #-129]
	strb r1, [r2, #-127]
	strb r1, [r2, #129]
	strb r1, [r2, #127]
	mov r1, #0x21
	strb r1, [r2, #-1]
	strb r1, [r2, #1]
	mov r1, #0x2d
	strb r1, [r2, #-128]
	strb r1, [r2, #128]
	// draw an O
	bx lr
	
@ TODO: copy VGA driver here.
VGA_draw_point_ASM:
	// draws colour on screen as indicated by third argument.
	// input: r0: x, r1: y, r2: colour
	push {r0 - r4}
	ldr r4, =pixel_buffer
	lsl r1, r1, #10
	orr r4, r4, r1
	lsl r0, r0, #1
	// now have obtained address needed, add it to base address
	orr r4, r4, r0
	strh r2, [r4] // Todo: figure out why this works
	pop {r0 - r4}
	bx lr
	
VGA_clear_pixelbuff_ASM:
	push {r0 - r3}
	mov r0, #0
	mov r1, #0
	push {lr}
	bl i_loop_pixbuff
	pop {lr}
	pop {r0 - r3}
	bx lr
	
i_loop_pixbuff:
	mov r1, #0
	push {lr}
	bl j_loop_pixbuff
	pop {lr}
	add r0, r0, #1
	ldr r3, =x_limit
	cmp r0, r3
	bne i_loop_pixbuff
	bx lr	// go outside of VGA_clear_pixelbuff_ASM
j_loop_pixbuff:
	// calls draw_point, knowing that r0 -> i and r1 -> j
	push {lr}
	bl VGA_draw_point_ASM
	pop {lr}
	add r1, r1, #1
	ldr r3, =y_limit
	cmp r1, r3
	bne j_loop_pixbuff
	bx lr
	
i_loop_pixbuff2:
// helper that assists in creating tile
	push {lr}
	bl VGA_draw_point_ASM
	pop {lr}
	add r0, r0, #1
	movw r3, #263
	cmp r0, r3
	bne i_loop_pixbuff2
	bx lr
j_loop_pixbuff2:
	// helper that assists in creating tile
	push {lr}
	bl VGA_draw_point_ASM
	pop {lr}
	add r1, r1, #1
	mov r3, #223
	cmp r1, r3
	bne j_loop_pixbuff2
	bx lr
	
VGA_write_char_ASM:
	// check if r0 gte 80 | check if r1 gte 60
	cmp r0, #79
	bgt out_of_bounds
	cmp r0, #0
	blt out_of_bounds
	cmp r1, #59
	bgt out_of_bounds
	cmp r1, #0
	blt out_of_bounds
	push {r0 - r4}
	ldr r4, =char_buffer
	lsl r1, r1, #7
	orr r4, r4, r1
	// now have obtained address needed, add it to base address
	orr r4, r4, r0
	strb r2, [r4]	
	// Todo: add something else here?
	pop {r0 - r4}
	bx lr
	
out_of_bounds:
	bx lr
	
VGA_clear_charbuff_ASM:
	push {r0 - r3}
	mov r0, #0
	mov r1, #0
	mov r2, #0
	push {lr}
	bl i_loop_charbuff
	pop {lr}
	pop {r0 - r3}
	bx lr
	
i_loop_charbuff:
	mov r1, #0
	push {lr}
	bl j_loop_charbuff
	pop {lr}
	add r0, r0, #1
	ldr r3, =x_limit2
	cmp r0, r3
	bne i_loop_charbuff
	bx lr	// go outside of VGA_clear_pixelbuff_ASM
j_loop_charbuff:
	// calls draw_point, knowing that r0 -> i and r1 -> j
	push {lr}
	bl VGA_write_char_ASM
	pop {lr}
	add r1, r1, #1
	ldr r3, =y_limit2
	cmp r1, r3
	bne j_loop_charbuff
	bx lr

@ TODO: insert PS/2 driver here.
read_PS2_data_ASM:
	// r0 -> address pointer
	// r1 -> address of ps/2
	// r2 -> value at ps/2
	// r3 -> shifted value at ps/2 (only used to compare and branch)
	push {r1 - r3}
	ldr r1, =ps2_driver
	ldr r2, [r1]
	lsr r3, r2, #15	// temporary register
	tst r3, #0x1
	bne data_exists
	b data_dne
data_exists:
	strb r2, [r0]
	mov r0, #1
	pop {r1 - r3}
	bx lr
data_dne:
	mov r0, #0
	pop {r1 - r3}
	bx lr
end:
	.end