;
; Laba7.asm
;
; Author : 413
;
.include "m32adef.inc"

.def temp  = r16
.def temp2 = r17
.def diods = r18
.def mode  = r19
.def countADC  = r20
.def countWait = r21
.set number_of_samples = 10	// 10 ���������

.dseg
	.org 0x95
		mas_ADC: .byte number_of_samples

.cseg
.org $000	  rjmp INIT
.org INT0addr rjmp INT_0
.org INT1addr rjmp INT_1
.org OVF0addr rjmp T_OWF0	// ���������� �� ������� 0
.org ADCCaddr rjmp Int_ADC

.macro mas				// ����� ��������� X,Y � Z ������� �� ������
	ldi @0, low(@2)
	ldi @1, high(@2)
.endmacro

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
INIT:

	; ��������� ��������� �����
	ldi temp, low(RAMEND)
	out SPL, temp
	ldi temp, high(RAMEND)
	out SPH, temp

	clr mode

	ldi temp,0x7F ; ����������� 7� ��� ���...
	out DDRA,temp ; ...�� ����

	; ��������� ����� B �� ����� ����������
	ser temp
	out DDRB, temp
	out PORTB, temp

	; ��������� ����������
	; ����������� �� ������������ INT0 � INT1 �� ��������� (������������) ������
	ldi temp, (1<<ISC11)|(1<<ISC10)|(1<<ISC01)|(1<<ISC00)
	out MCUCR, temp

	; ���������� ������� (����������) ����������
	ldi temp, (1<<INT1)|(1<<INT0)
	out GICR, temp

	; ��������� ������� 0
	; ���������� ���������� �� ������������ �����
	ldi temp, (1<<TOIE0)|(1<<TOIE1)
	out TIMSK, temp
	ldi temp, 0 ; ������ ����� ���������� �����
	out TCNT0,temp

	; ��������� ADC �� 7 �����(MUX), ������������ �� ������(ADLAR) ���� ��������
	; REFS1:REFS0. ���� ������ �������� ����������. ������ ����� ������������? �� ����������� ���������� �������� ��������
	; ADLAR - ������������ ���������� �� ������-�� (������) ����
	; MUX0, MUX1, MUX2 - ���� �������� ADMUX. � ������ ������ ���������?
	ldi temp, (0<<REFS1)|(0<<REFS0)|(1<<ADLAR)|(1<<MUX2)|(1<<MUX1)|(1<<MUX0)
	out ADMUX, temp
	ldi temp, (1<<ADEN)|(0<<ADSC)|(0<<ADATE)|(0<<ADIF)|(1<<ADIE)|(1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0)
	out ADCSRA,temp

	; ��������� �������
	mas xl, xh, mas_ADC
	ldi countADC, number_of_samples

	sei ; ��������� ����������

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
main:
	rjmp main		; ����������� ����

INT_0:
	; ��������� �������
	mas xl, xh, mas_ADC
	ldi countADC, number_of_samples
    
	; �������� ������
	ldi temp, (1<<CS02)|(0<<CS01)|(1<<CS00) ; �0 � ��������
	out TCCR0, temp                         ; � ������� �������� ��/1024

    ldi countWait, 4 ; ������� ����� ���������� �������������� ��������
reti

INT_1:
	sbi ADCSRA, ADSC ; ����� ADC
reti

T_OWF0: // �������� �/� ������� ��������
	; ����������� ��� �������
	dec countWait
	BRNE END_T_OWF
	ldi countWait, 4

	; ����� ����� ������ �� �����
	ld diods, x+
	com diods
	out PORTB, diods

	; ���� ��������� �������
	dec countADC
	BRNE END_T_OWF ; ���� ������ �����, ��������� ����������

	; ��������� ����������
	ser diods ; ��������� ����������
	out PORTB, diods

	; ��������� Timer 0
	clr temp	   ; Timer 0
	out TCCR0,temp ; ���� ������

	END_T_OWF:
		reti

Int_ADC:	// ���������� �� ��������� ������ ��� �� ������� (������)
	; ����� ��������� ADC
    in diods, ADCL ; 
	in diods, ADCH

	; ���� ����� � ������
	st x+, diods

	;�����
	com diods
	out PORTB, diods 

	; ���� ��������� �������
	dec countADC
	BRNE END_Int_ADC ; ���� ��������� ������, ��������� ����������

	; ��������� ����������
    cbi ADCSRA,ADSC ; ���� ADC
	
    ; ����� �������
	mas xl, xh, mas_ADC
	ldi countADC, number_of_samples

	ser diods
	out PORTB, diods

	END_Int_ADC:
		reti

//inf:
//	rjmp inf

