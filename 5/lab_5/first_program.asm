.include "lib.asm"

.def counter = r16 // счетчик
.def alt_counter = r17 // второй счетчик
.def a_current = r18 // элемент масива А
.def b_current = r19 // элемент масива B
.def c_current = r20 // элемент масива B
.def bool = r21 // логическая переменная
.def mx = r22 // логическая переменная
.def counterWorkSize = r23 // счетчик заполненной зоны в массиве
.set sizeAB = 10 // размер массивов A и B
.set sizeC = 10 // размер массивов C
.set false = 0 // логический ноль
.set true = 1 // логическая еденица

.dseg // указатель на сегмент данных
.org 0x60 // начальный адрес масивов
arr_a: .byte sizeAB // Выделяем sizeAB байт на массив А
arr_b: .byte sizeAB // Выделяем sizeAB байт на массив В

.org 0x7b
arr_c: .byte sizeC // Выделяем sizeС байт на массив С

.org 0x8c
min_el: .byte 1 // выделим 1 байт под максимальный элемент

.cseg // указатель на сегмент кода
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


ldi a_current, 4 // переменная для заполнения массива a
ldi counter, sizeAB // Устанавливаем размер счетчика
MASA: // заполняем массив a
	st z+, a_current // сохранение a_current в масив Вaи инкремент указателя
	inc a_current
	dec counter
brne MASA // условия цикл заполнения массива a

// заполнения масив В
ldi b_current, 16 // переменная для заполнения массива B
ldi counter, sizeAB // Устанавливаем размер счетчика
MASB: // заполняем массив B
	st y+, b_current // сохранение b_current в масив В и инкремент указателя
	dec b_current
	dec counter
brne MASB // условия цикл заполнения массива В


// Заполним массив С разностью массивов А и В
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
				cp b_current, a_current // Сравнить b_current с a_current
				brne RAZN1 // Перейти если b_current не равно a_current
				ldi bool, true // иначе bool == true
				inc counterWorkSize
				RAZN1:
				dec counter
				brne FILL2AB // условия цикл нахождения элемента a_current в В

			cpi bool, true // Сравнить bool с false (true)
			brne RAZN2 // Перейти если bool не равно false
			st x+, a_current // x = a_current, x = x + 1
			RAZN2:
			dec alt_counter // декремент счетчика2
brne FILL1AB


; Запись в память

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