;
; Laba6.asm
;
; Created: 31.05.2022 15:13:48
; Author : 413
;

.def count			= r16	; счетчик
.def count2			= r17	; второй счетчик
.def a_elem			= r18	; текущий элемент массива A
.def b_elem			= r19	; текущий элемент массива B
.def c_length		= r20	; длина заполненной части массива C
.def previous_elem	= r21
.def current_elem	= r22
.def index			= r23

.set start_max	= 255
.set sizeAB		= 10	; размеры массивов A и B

.dseg ; указатель на сегмент данных

.org 0x60	; начальный адрес
	mas_a:	.byte sizeAB
	mas_b:	.byte sizeAB

.org 0x7b	; выделим под массив C 10 байт
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

.cseg ; указатель на сегмент кода

.org $000 rjmp INIT
.org INT0addr rjmp P_INT0
.org INT1addr rjmp P_INT1
.org OC0addr rjmp T_OC_SECOND
.org OVF0addr rjmp T_OWF_Select

INIT:

load_x mas_a

ldi a_elem, 4		; переменная для заполнения массива А
ldi count, sizeAB
MASA:
	st x+, a_elem
	inc a_elem
	dec count
	brne MASA 

load_y mas_b

ldi b_elem, 16
ldi count, sizeAB – 5	; пропускаем парк элементов чтобы массивы отличались
MASB:				; заполняем массив B
	st y+, b_elem
	dec b_elem
	dec count
	brne MASB

;------------------------------------------------------;
; Формируем регистровые пары
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
; Сортировка убывание
load_z mas_c

SORT:
	ld	previous_elem, z+
	ld	current_elem, z
	inc	index
	cp	 previous_elem, current_elem
	brsh PREVIOUS_NOT_LESS	; если previous_elem >= current_elem

PREVIOUS_LESS:	
	st	 z, previous_elem	; поменять значения местами в памяти
	st	 -z, current_elem
	sbiw z, 1		; декремент указателя на 1
	subi index, 2
	brcc PREVIOUS_NOT_LESS	; если перенос установлен (индекс меньше 0), то обнулить
	ldi  index, 0
	adiw z, 1		; инкремент указателя на 1

PREVIOUS_NOT_LESS:

	cp index, c_length
	brlo SORT		; если индекс меньше длинны, то новая итерация

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

clr temp		; выкл таймер
out TCCR0, temp

ldi temp, low(RAMEND)	; настройка стека
out SPL, temp
ldi temp, high(RAMEND)
out SPH, temp

ser temp
out DDRB, temp	; настройка светодиодов
out PORTB, temp
clr temp
out DDRD, temp	; настройка кнопок

sei				; разрешить прерывания
ldi temp, 0b00001111	; прерывания по нарастающему фронту для INT0 и INT1
out MCUCR, temp
ldi temp, 0b11000000	; разрешить прерывания INT0 и INT1
out GICR, temp

clr flags
ldi mode, 1 ; начальный номер режима
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
	ldi temp, (1<<TOIE0)	; вкл прерывания для таймера 0
	out TIMSK, temp

	mov count, c_length
    load_z mas_c
	
	// CLK/1024
	ldi temp,(1<<CS02)|(1<<CS00) ; предделитель
	out TCCR0,temp

	loop_1:
		sbrc flags, is_running_bit_index	; выключение
		rjmp loop_1
		clr temp ; выкл таймер
		out TCCR0, temp
		ret

;------------------------------------------------------;
; Пилообразный ШИМ
SECOND:
    ldi temp, 0x01  ; загрузка числа сравнения
    out OCR0, temp

    ldi temp, (1<<OCIE0)|(1<<TOIE0) ; разрешить прерывание по сравнению и переполнению
    out TIMSK, temp

    ldi temp, (1<<CS01) | (0<<CS00) ; предделитель
    out TCCR0, temp ; старт таймера

    clr count ; начальное значение диодов
    clr compare_number ; число сравнения
    loop_2:
		sbrc flags, is_running_bit_index ; выключение
		rjmp loop_2
		clr temp ; выкл таймер
		out TCCR0, temp
		ret

; Треугольный ЧИМ
THIRD:
    clr count ; начальное значение диодов
    clr start_number ; начальное число отсчёта
	clr temp
    out TCNT0, temp

    ldi temp, (1<<TOIE0) ; разрешить прерывание по переполнению
    out TIMSK, temp

    ldi temp, (1<<CS02) | (0<<CS00) ; предделитель
    out TCCR0, temp ; старт таймера

    loop_3:
		sbrc flags, is_running_bit_index ; выключение
		rjmp loop_3
	    clr temp ; выкл таймер
		out TCCR0, temp
		ret


P_INT0: ; кнопка X выбор режима
	lsl mode
	andi flags, ~is_running_flag
	sbrc mode, 3
    ldi mode, 1
	reti

P_INT1: ; кнопка Y запуск/остановка режима
    ; если запущен, то выключить и наоборот
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
	ld temp, z+ ; загрузить элемент массива С
	com temp
	out PORTB, temp ; вывести его на светодиоды

	dec count
    breq RESTART 
    reti

    ; если конец массива, то начинаем заново
    RESTART:
	mov count, c_length 
    load_z mas_c
    reti


T_OC_SECOND:
    com count ; включение светодиодов
    out PORTB, count
    reti

; Пилообразный ШИМ
T_OWF_SECOND:
    com count ; выключение светодиодов
    out PORTB, count
    dec compare_number
    out OCR0, compare_number
    reti

; Треугольный ЧИМ
T_OWF_THIRD:
    com count ; включение/выключение светодиодов
    out PORTB, count

    cpi start_number, 0x00
    in temp2, SREG
    sbrc temp2, SREG_Z  ; пропустить, если не равно 0
    sbr flags, is_decreasing_flag

    cpi start_number, 0xff
    in temp2, SREG
    sbrc temp2, SREG_Z ; пропустить, если не равно 255
    cbr flags, is_decreasing_flag

    sbrs flags, is_decreasing_bit_index
    dec start_number
    sbrc flags, is_decreasing_bit_index
    inc start_number

    out TCNT0, start_number
    reti

; Бесконечный цикл
inf:
	rjmp inf
