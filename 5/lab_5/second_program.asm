; ����� ������������ ��������
 
.include "lib.asm"
.def count			= r16 ; �������
.def c_elem			= r20 ; ������� ������� ������� C
.def c_length		= r21 ; ������ ���������� ����� ������� C
.def min_element	= r22 
.set start_max		= 255

.dseg

.org 0x9c
mas_c: .byte 16 ; ������� ��� ������ C 20 ����

.org 0x8a
min_memory: .byte 1

.cseg

START:

LOAD:
	load_x mas_c

	ldi ZL,0
	ldi ZH,0

	E_READ ZH, ZL, c_length
	inc ZL

	mov	count, c_length

	LOOP:	
		E_READ ZH, ZL, c_elem
		st x+, c_elem
		inc ZL
		dec count
		brne LOOP

load_z mas_c

ldi min_element, start_max
mov count, c_length
FIND_MIN:
	ld c_elem, z+
	cp min_element, c_elem

	brlo SAME_OR_HIGHER ; ������� ���� min_element >= c_length
	mov min_element, c_elem

	SAME_OR_HIGHER:
	dec count

brne FIND_MIN
sts min_memory, min_element

ldi r20, 0xff		; ������q�� ����� �  � �������� ���������� ����������
out DDRB, r20
com min_element
out PORTB, min_element	; ��������� ��� ���������� (���������� �����)

WAIT:	
	rjmp WAIT