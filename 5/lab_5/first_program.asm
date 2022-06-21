.include "lib.asm"

.def counter = r16 // �������
.def alt_counter = r17 // ������ �������
.def a_current = r18 // ������� ������ �
.def b_current = r19 // ������� ������ B
.def c_current = r20 // ������� ������ B
.def bool = r21 // ���������� ����������
.def mx = r22 // ���������� ����������
.def counterWorkSize = r23 // ������� ����������� ���� � �������
.set sizeAB = 10 // ������ �������� A � B
.set sizeC = 10 // ������ �������� C
.set false = 0 // ���������� ����
.set true = 1 // ���������� �������

.dseg // ��������� �� ������� ������
.org 0x60 // ��������� ����� �������
arr_a: .byte sizeAB // �������� sizeAB ���� �� ������ �
arr_b: .byte sizeAB // �������� sizeAB ���� �� ������ �

.org 0x7b
arr_c: .byte sizeC // �������� size� ���� �� ������ �

.org 0x8c
min_el: .byte 1 // ������� 1 ���� ��� ������������ �������

.cseg // ��������� �� ������� ����
//ldi xl, low(arr_c) // X
//ldi xh, high(arr_c)

//ldi yl, low(arr_b) // Y
//ldi yh, high(arr_b)

//ldi zl, low(arr_a) // Z
//ldi zh, high(arr_a)

START:
	load_x arr_c
	load_y arr_b
	load_z arr_a


ldi a_current, 4 // ���������� ��� ���������� ������� a
ldi counter, sizeAB // ������������� ������ ��������
MASA: // ��������� ������ a
	st z+, a_current // ���������� a_current � ����� �a� ��������� ���������
	inc a_current
	dec counter
brne MASA // ������� ���� ���������� ������� a

// ���������� ����� �
ldi b_current, 16 // ���������� ��� ���������� ������� B
ldi counter, sizeAB // ������������� ������ ��������
MASB: // ��������� ������ B
	st y+, b_current // ���������� b_current � ����� � � ��������� ���������
	dec b_current
	dec counter
brne MASB // ������� ���� ���������� ������� �


// �������� ������ � ��������� �������� � � �
//ldi zl, low(arr_a) // Z
//ldi zh, high(arr_a)
load_z arr_a
ldi alt_counter, sizeAB
ldi counterWorkSize, 0
FILL1AB:
		ld a_current, z+ // a_current=z, z=z+1
		ldi bool, false // bool = true
		//ldi yl, low(arr_b) // Y
		//ldi yh, high(arr_b)
		load_y arr_b
		ldi counter, sizeAB 
		FILL2AB:
				ld b_current, y+ // b_current=y, y=y+1
				cp b_current, a_current // �������� b_current � a_current
				brne RAZN1 // ������� ���� b_current �� ����� a_current
				ldi bool, true // ����� bool == true
				inc counterWorkSize
				RAZN1:
				dec counter
				brne FILL2AB // ������� ���� ���������� �������� a_current � �

			cpi bool, true // �������� bool � false (true)
			brne RAZN2 // ������� ���� bool �� ����� false
			st x+, a_current // x = a_current, x = x + 1
			RAZN2:
			dec alt_counter // ��������� ��������2
brne FILL1AB


; ������ � ������

SAVE:
	ldi r20,low(ramend)
	out spl,r20
	ldi r20, high(ramend)
	out sph,r20

	load_x arr_c

	ld c_current, x+
	mov	counter, counterWorkSize

	ldi ZL,0
	ldi ZH,0

	E_WRITE ZH, ZL, counterWorkSize
	inc ZL

	LOOP:	
			E_WRITE ZH, ZL,c_current
			inc ZL
     	ld c_current, x+
			dec counter
			brne LOOP

	WAIT:	
		rjmp WAIT