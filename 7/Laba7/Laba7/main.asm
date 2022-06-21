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
.set number_of_samples = 10	// 10 оцифровок

.dseg
	.org 0x95
		mas_ADC: .byte number_of_samples

.cseg
.org $000	  rjmp INIT
.org INT0addr rjmp INT_0
.org INT1addr rjmp INT_1
.org OVF0addr rjmp T_OWF0	// Прерывание по таймеру 0
.org ADCCaddr rjmp Int_ADC

.macro mas				// ЧТОБЫ УКАЗАТЕЛИ X,Y И Z ВРУЧНУЮ НЕ КЛАСТЬ
	ldi @0, low(@2)
	ldi @1, high(@2)
.endmacro

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
INIT:

	; настройка указателя стека
	ldi temp, low(RAMEND)
	out SPL, temp
	ldi temp, high(RAMEND)
	out SPH, temp

	clr mode

	ldi temp,0x7F ; настраиваем 7й пин АЦП...
	out DDRA,temp ; ...на ввод

	; настройка порта B на вывод светодиода
	ser temp
	out DDRB, temp
	out PORTB, temp

	; настройка прерываний
	; настраиваем на срабатывание INT0 и INT1 по переднему (нарастающему) фронту
	ldi temp, (1<<ISC11)|(1<<ISC10)|(1<<ISC01)|(1<<ISC00)
	out MCUCR, temp

	; разрешение внешних (глобальных) прерываний
	ldi temp, (1<<INT1)|(1<<INT0)
	out GICR, temp

	; настройка таймера 0
	; Разрешение прерываний по переполнению счета
	ldi temp, (1<<TOIE0)|(1<<TOIE1)
	out TIMSK, temp
	ldi temp, 0 ; задать число начального счета
	out TCNT0,temp

	; настройка ADC на 7 канал(MUX), выравнивание по левому(ADLAR) краю включить
	; REFS1:REFS0. Биты выбора опорного напряжения. Откуда брать тактирования? От встроенного генератора тактовых сигналов
	; ADLAR - выравнивания результата по какому-то (левому) краю
	; MUX0, MUX1, MUX2 - биты регистра ADMUX. С какого канала считываем?
	ldi temp, (0<<REFS1)|(0<<REFS0)|(1<<ADLAR)|(1<<MUX2)|(1<<MUX1)|(1<<MUX0)
	out ADMUX, temp
	ldi temp, (1<<ADEN)|(0<<ADSC)|(0<<ADATE)|(0<<ADIF)|(1<<ADIE)|(1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0)
	out ADCSRA,temp

	; настройка массива
	mas xl, xh, mas_ADC
	ldi countADC, number_of_samples

	sei ; разрешить прерывания

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
main:
	rjmp main		; бесконечный цикл

INT_0:
	; настройка массива
	mas xl, xh, mas_ADC
	ldi countADC, number_of_samples
    
	; включаем таймер
	ldi temp, (1<<CS02)|(0<<CS01)|(1<<CS00) ; Т0 – включить
	out TCCR0, temp                         ; с опорной частотой СК/1024

    ldi countWait, 4 ; счетчик чтобы обеспечить дополнительную задержку
reti

INT_1:
	sbi ADCSRA, ADSC ; старт ADC
reti

T_OWF0: // ЗАДЕРЖКА М/У ПОКАЗОМ ЗНАЧЕНИЙ
	; отчитывание для секунды
	dec countWait
	BRNE END_T_OWF
	ldi countWait, 4

	; вывод числа масива на диоды
	ld diods, x+
	com diods
	out PORTB, diods

	; счет элементов массива
	dec countADC
	BRNE END_T_OWF ; если прошли масив, закончить выполнения

	; окончание выполнения
	ser diods ; выключаем светодиоды
	out PORTB, diods

	; выключить Timer 0
	clr temp	   ; Timer 0
	out TCCR0,temp ; стоп таймер

	END_T_OWF:
		reti

Int_ADC:	// ПРЕРЫВАНИЕ ПО ОКОНЧАНИЮ РАБОТЫ АЦП СО СНИМКОМ (числом)
	; вывод отработки ADC
    in diods, ADCL ; 
	in diods, ADCH

	; ввод числа в массив
	st x+, diods

	;вывод
	com diods
	out PORTB, diods 

	; счет элементов массива
	dec countADC
	BRNE END_Int_ADC ; если заполнили массив, закончить выполнения

	; закончить выполнения
    cbi ADCSRA,ADSC ; выкл ADC
	
    ; сброс массива
	mas xl, xh, mas_ADC
	ldi countADC, number_of_samples

	ser diods
	out PORTB, diods

	END_Int_ADC:
		reti

//inf:
//	rjmp inf

