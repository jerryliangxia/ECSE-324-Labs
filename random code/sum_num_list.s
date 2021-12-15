	ARRAY: .word 1,2,3,4,5,6,7,8
	N: .word 14
	SUM: .space 4

.global _start
_start: 
	LDR A1, =ARRAY // A1 p oin t s to ARRAY
	LDR A2, N // A2 con t ains number o f elements to add
	PUSH {A1, A2, LR} // push parameters and LR ( A1 i s TOS )
	BL listadd // c a l l sub rou tine
	LDR A1, [SP, #0] // r e t u r n i s a t TOS
	STR A1, SUM // s t o r e i t i n memory
	ADD SP, SP, #8 // cl e a r parameters
	POP {LR} // r e s t o r e LR
stop: 
	B stop
listadd: 
	PUSH {V1−V3} // c all e e − save r e g i s t e r s l i s t a d d uses
	LDR V1, [SP, #16] // load param N from s t a ck
	LDR V2, [SP, #12] // load param ARRAY from s t a ck
	MOV A1, #0 // cl e a r R0 ( sum)
loop: 
	LDR V3, [V2], #4 // ge t nex t value from ARRAY
	ADD A1, A1, V3 // form the p a r t i a l sum
	SUBS V1, V1, #1 // decrement loop coun te r
	BGT loop
	STR A1, [SP, #12] // s t o r e sum on s tack , r e pl a ci n g ARRAY
	POP {V1−V3} // r e s t o r e r e g i s t e r s
	BX LR