//.include "m32adef.inc"

.def temp = r16
.def diods = r17
.def interruption_count = r18

.cseg
.org 0x00 rjmp INIT
.org 0x02 rjmp P_INT0 ; настраиваем вектора прерываний
.org 0x04 rjmp P_INT1

INIT:
	clr interruption_count ; очищаем количество прерываний

	ldi temp, low(RAMEND) ; настраиваем стек
	out SPL, temp
	ldi temp, high(RAMEND)
	out SPH, temp

	ser temp ; устанавливаем temp в единицы

	out DDRB, temp ; настраиваем порт B на вывод
	out PORTB, temp
	
	sei

	ldi temp, 0b00001011 ; настраиваем прерывания по нарастающиму и падающему фронту
	out MCUCR, temp

	ldi temp, 0b11000000 ; разрешаем внешние прерывания 0 и 1
	out GICR, temp

	ldi diods, 0xff ; гасим светодиоды
	ldi r21,120 ; задаем начальную задержку для моргания

MAIN:
	COM diods
	
	out PORTB, diods ; вывод на светодиоды
	rcall Delay
	MOV r20, r21
	rjmp MAIN

Delay:
m20:ldi r30,255
m10:dec r30
	brne m10
	dec r20
	brne m20
	ret
P_INT0:
	ldi r21,255
	reti
P_INT1:
	ldi r21,50
		reti