;
; Laba6.asm
;
; Created: 31.05.2022 15:13:48
; Author : 413
;

.def count			= r16	; �������
.def count2			= r17	; ������ �������
.def a_elem			= r18	; ������� ������� ������� A
.def b_elem			= r19	; ������� ������� ������� B
.def c_length		= r20	; ����� ����������� ����� ������� C
.def previous_elem	= r21
.def current_elem	= r22
.def index			= r23

.set start_max	= 255
.set sizeAB		= 10	; ������� �������� A � B

.dseg ; ��������� �� ������� ������

.org 0x60	; ��������� �����
	mas_a:	.byte sizeAB
	mas_b:	.byte sizeAB

.org 0x7b	; ������� ��� ������ C 10 ����
	mas_c:	.byte 10

;------------------------------------------------------;

.macro load_x
	ldi xl, low(@0) ;  X
	ldi xh, high(@0)
.endm

.macro load_y
	ldi yl, low(@0) ;  Y
	ldi yh, high(@0)
.endm

.macro load_z
	ldi zl, low(@0) ;  Z
	ldi zh, high(@0)
.endm

;------------------------------------------------------;

.cseg ; ��������� �� ������� ����

.org $000 rjmp INIT
.org INT0addr rjmp P_INT0
.org INT1addr rjmp P_INT1
.org OC0addr rjmp T_OC_SECOND
.org OVF0addr rjmp T_OWF_Select

INIT:

load_x mas_a

ldi a_elem, 4		; ���������� ��� ���������� ������� �
ldi count, sizeAB
MASA:
	st x+, a_elem
	inc a_elem
	dec count
	brne MASA 

load_y mas_b

ldi b_elem, 16
ldi count, sizeAB � 5	; ���������� ���� ��������� ����� ������� ����������
MASB:				; ��������� ������ B
	st y+, b_elem
	dec b_elem
	dec count
	brne MASB

;------------------------------------------------------;
; ��������� ����������� ����
load_x mas_a
load_y mas_b
load_z mas_c

ldi c_length, 0
ldi count, sizeAB

A_LOOP:
ld	a_elem, x+
	ldi	count2, sizeAB
	load_y	mas_b
	B_LOOP:
		ld	b_elem, y+
		cp	a_elem, b_elem
		brne	NOT_EQUAL
		st	z+, a_elem
		inc	c_length

	NOT_EQUAL:
		dec	count2
		brne	B_LOOP
		dec	count
		brne	A_LOOP

;------------------------------------------------------;
; ���������� ��������
load_z mas_c

SORT:
	ld	previous_elem, z+
	ld	current_elem, z
	inc	index
	cp	 previous_elem, current_elem
	brsh PREVIOUS_NOT_LESS	; ���� previous_elem >= current_elem

PREVIOUS_LESS:	
	st	 z, previous_elem	; �������� �������� ������� � ������
	st	 -z, current_elem
	sbiw z, 1		; ��������� ��������� �� 1
	subi index, 2
	brcc PREVIOUS_NOT_LESS	; ���� ������� ���������� (������ ������ 0), �� ��������
	ldi  index, 0
	adiw z, 1		; ��������� ��������� �� 1

PREVIOUS_NOT_LESS:

	cp index, c_length
	brlo SORT		; ���� ������ ������ ������, �� ����� ��������

.undef a_elem
.undef b_elem
.undef previous_elem
.undef current_elem

;------------------------------------------------------;
.def mode           = r18
.def flags			= r19
.def compare_number = r21
.def start_number   = r22
.def temp           = r24
.def temp2          = r25

.set is_running_bit_index    = 0
.set is_decreasing_bit_index = 1

.set is_running_flag    = 1 << is_running_bit_index
.set is_decreasing_flag = 1 << is_decreasing_bit_index

clr temp		; ���� ������
out TCCR0, temp

ldi temp, low(RAMEND)	; ��������� �����
out SPL, temp
ldi temp, high(RAMEND)
out SPH, temp

ser temp
out DDRB, temp	; ��������� �����������
out PORTB, temp
clr temp
out DDRD, temp	; ��������� ������

sei				; ��������� ����������
ldi temp, 0b00001111	; ���������� �� ������������ ������ ��� INT0 � INT1
out MCUCR, temp
ldi temp, 0b11000000	; ��������� ���������� INT0 � INT1
out GICR, temp

clr flags
ldi mode, 1 ; ��������� ����� ������
out PORTB, mode

MAIN:
	out PORTB, mode
    sbrs flags, is_running_bit_index
    rjmp main

	sbrc mode, 0	
    call FIRST
	sbrc mode, 1    
    call SECOND
	sbrc mode, 2	
    call THIRD

    rjmp MAIN

FIRST:
	ldi temp, (1<<TOIE0)	; ��� ���������� ��� ������� 0
	out TIMSK, temp

	mov count, c_length
    load_z mas_c
	
	// CLK/1024
	ldi temp,(1<<CS02)|(1<<CS00) ; ������������
	out TCCR0,temp

	loop_1:
		sbrc flags, is_running_bit_index	; ����������
		rjmp loop_1
		clr temp ; ���� ������
		out TCCR0, temp
		ret

;------------------------------------------------------;
; ������������ ���
SECOND:
    ldi temp, 0x01  ; �������� ����� ���������
    out OCR0, temp

    ldi temp, (1<<OCIE0)|(1<<TOIE0) ; ��������� ���������� �� ��������� � ������������
    out TIMSK, temp

    ldi temp, (1<<CS01) | (0<<CS00) ; ������������
    out TCCR0, temp ; ����� �������

    clr count ; ��������� �������� ������
    clr compare_number ; ����� ���������
    loop_2:
		sbrc flags, is_running_bit_index ; ����������
		rjmp loop_2
		clr temp ; ���� ������
		out TCCR0, temp
		ret

; ����������� ���
THIRD:
    clr count ; ��������� �������� ������
    clr start_number ; ��������� ����� �������
	clr temp
    out TCNT0, temp

    ldi temp, (1<<TOIE0) ; ��������� ���������� �� ������������
    out TIMSK, temp

    ldi temp, (1<<CS02) | (0<<CS00) ; ������������
    out TCCR0, temp ; ����� �������

    loop_3:
		sbrc flags, is_running_bit_index ; ����������
		rjmp loop_3
	    clr temp ; ���� ������
		out TCCR0, temp
		ret


P_INT0: ; ������ X ����� ������
	lsl mode
	andi flags, ~is_running_flag
	sbrc mode, 3
    ldi mode, 1
	reti

P_INT1: ; ������ Y ������/��������� ������
    ; ���� �������, �� ��������� � ��������
    ori flags, is_running_flag
	reti

T_OWF_Select:
	sbrc mode, 0
	rjmp T_OWF_FIRST
	sbrc mode, 1
	rjmp T_OWF_SECOND
	sbrc mode, 2
	rjmp T_OWF_THIRD

T_OWF_FIRST:
	ld temp, z+ ; ��������� ������� ������� �
	com temp
	out PORTB, temp ; ������� ��� �� ����������

	dec count
    breq RESTART 
    reti

    ; ���� ����� �������, �� �������� ������
    RESTART:
	mov count, c_length 
    load_z mas_c
    reti


T_OC_SECOND:
    com count ; ��������� �����������
    out PORTB, count
    reti

; ������������ ���
T_OWF_SECOND:
    com count ; ���������� �����������
    out PORTB, count
    dec compare_number
    out OCR0, compare_number
    reti

; ����������� ���
T_OWF_THIRD:
    com count ; ���������/���������� �����������
    out PORTB, count

    cpi start_number, 0x00
    in temp2, SREG
    sbrc temp2, SREG_Z  ; ����������, ���� �� ����� 0
    sbr flags, is_decreasing_flag

    cpi start_number, 0xff
    in temp2, SREG
    sbrc temp2, SREG_Z ; ����������, ���� �� ����� 255
    cbr flags, is_decreasing_flag

    sbrs flags, is_decreasing_bit_index
    dec start_number
    sbrc flags, is_decreasing_bit_index
    inc start_number

    out TCNT0, start_number
    reti

; ����������� ����
inf:
	rjmp inf
