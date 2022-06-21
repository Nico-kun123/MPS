//	������� �7
// 
//	������ �������� A � B: 10,
//	��������: �����������,
//	������ ������� C: 10
// ����� ������� C: 0x7B
// �����: MIN ��������
// ����� ��������:	0x8C
// ����������: ��������

//	1) ����������� �������� ������� ���������������, � ���������� ������ � $0060;
//	2) ��������� �������� ������� ������������� ����������.
//	3) ��������� �������� ����������� ��� ��������� A � B � ��������� �������� � ������ � ������ C, ������������� �� ������ 0x7B.
//	4) � ������� C ����� ����������� ������� � �������� ��� �� ������ 0x8C.
//	5) ������������� ������ C �� ��������.

// �������������� ��������� "����������"
.def counter = r16			; �������
.def alt_counter = r17		; ������ �������
.def a_current = r18		; ������� ������� �
.def b_current = r19		; ������� ������� B
.def c_current = r20		; ������� ������� C
.def bool = r21				; ���������� ����������
.def mx = r22				; ���������� ����������
.def counterWorkSize = r23	; ������� ����������� ���� � �������
.set sizeAB = 10			; ������ �������� A � B
.set sizeC = 10				; ������ �������� C
.set false = 0				; ���������� ����
.set true = 1				; ���������� �������

// ������� ������, ������ � �������
.dseg						; ��������� �� ������� ������
	.org 0x60				; ��������� ����� �������
		arr_a: .byte sizeAB ; �������� sizeAB ���� �� ������ �
		arr_b: .byte sizeAB ; �������� sizeAB ���� �� ������ �
	.org 0x7B
		arr_c: .byte sizeC  ; �������� size� ���� �� ������ �
	.org 0x8C
		min_el: .byte 1		; ������� 1 ���� ��� ������������ �������

// ������� ����, ���������� �������
.cseg ; ������ � ������� ����

// ��������� ����������� ����
ldi xl, low(arr_c)	; X
ldi xh, high(arr_c)
ldi yl, low(arr_b)	; Y
ldi yh, high(arr_b)
ldi zl, low(arr_a)	; Z
ldi zh, high(arr_a)

// ���������� �������� A � B
// A = [ 9,10,11,12,13,14,15,16,17,18]
// B = [15,14,13,12,11,10, 9, 8, 7, 6]
// ����� ��������: 9, 10, 11, 12, 13, 14, 15
ldi a_current, 9		; ���������� ��� ���������� ������� a
ldi counter, sizeAB		; ������������� ������ ��������
MASA:					; ��������� ������ a
	st z+, a_current	; ���������� a_current � ����� � � ��������� ���������
	inc a_current
	dec counter
brne MASA				; ������� ���� ���������� ������� a

ldi b_current, 15		; ���������� ��� ���������� ������� B
ldi counter, sizeAB		; ������������� ������ ��������
MASB:					; ��������� ������ B
	st y+, b_current	; ���������� b_current � ����� � � ��������� ���������
	dec b_current
	dec counter
brne MASB				; ������� ���� ���������� ������� �

// �����������.
// ������ C ������ ��������� ��������� �����:
// C = [0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x00, 0x00, 0x00].
// ������������� ������ A �� �������� ����������� � ���������� ������� B
// �������� ��������� ����������� ���� X � Y, �.�. �������� � �� ��������
ldi zl, low(arr_a)		; Z
ldi zh, high(arr_a)
ldi alt_counter, sizeAB
ldi counterWorkSize, 0

FILL1AB:
	ld a_current, z+		; a_current=z, z=z+1
	ldi bool, false			; bool = true
	ldi yl, low(arr_b)		; Y
	ldi yh, high(arr_b)
	ldi counter, sizeAB
 FILL2AB:
		ld b_current, y+		; b_current=y, y=y+1
		cp b_current, a_current ; �������� b_current � a_current
		brne RAZN1				; �������, ���� b_current �� ����� a_current
		ldi bool, true			; ����� bool == true
		inc counterWorkSize
		RAZN1:
			dec counter
			brne FILL2AB		; ������� ���� ���������� �������� a_current � �

	cpi bool, true		; �������� bool � false (true)
	brne RAZN2			; �������, ���� bool �� ����� false
	st x+, a_current	; x = a_current, x = x + 1
	RAZN2:
		dec alt_counter	; ��������� �������� �2
brne FILL1AB

// ����� ������������ ��������.
// �� ������ 0x8C ������ ���������� 0x00 (������ �������), �.�. ������ ������� C (10)
// ������ ���������� ������� ����������� (7),
// � ����������� ��������� ����������� ������ ������� (0x00).
// ��������� ����������� ���� Z
ldi xl, low(arr_c)	; X
ldi xh, high(arr_c)
ld mx,x				; ������������� �������� ������� ��������

mov counter, counterWorkSize
Find_min:
	ld c_current, x+	; �i=x, x=x+1
	cp mx, c_current	; �������� c_current � mx
	BRLO nebol			; ������� ���� c_current ������ mx
	mov mx, c_current	; ����� mx = c_current
	nebol:
	dec counter
brne Find_min

ldi yl, low(min_el)		; Y
ldi yh, high(min_el)
st y, mx

// ���������� �� ��������
// ����� ���������� ��������� ��������� ������:
// C = [0x0F, 0x0E, 0x0D, 0x0C, 0x0B, 0x0A, 0x09, 0x00, 0x00, 0x00]
// 3 ���� � ����� - ������ �������� ��-�� ������� ������� C = 10 ���������, ��� 7 �� ������� �� ��� ���������� ������ ����������� �������� A � B
SORT:
	ldi xl, low(arr_c)	; X
	ldi xh, high(arr_c)
	ldi bool, false		; bool = false
	mov counter, counterWorkSize
	SORT2:
		ld c_current, x+	; �i=x, x=x+1
		ld mx, x			; mx = x
		cp mx, c_current	; �������� mx � c_current
		BRLO SWIP			; ������� ���� ������ (������ brsh)
			ldi bool, true	; bool = true
			mov a_current, c_current	; a_current = c_current//
			
			st -x, mx			; x=x-1, x = mx
			ld r13, x+			; r13 �� �����, ������� ������ ��������� x
			st x, a_current		; x = a_current
		SWIP:
		dec counter		; ��������� ��������
	brne SORT2
	cpi bool, true		; �������� bool � true
breq SORT				; ������� ���� bool ����� true
nop

// ����������� ����
inf:
rjmp inf