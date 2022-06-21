//	ВАРИАНТ №7
// 
//	Размер массивов A и B: 10,
//	Операция: Пересечение,
//	Размер массива C: 10
// Адрес массива C: 0x7B
// Поиск: MIN Элемента
// Адрес Элемента:	0x8C
// Сортировка: Убывание

//	1) Расположить исходные массивы последовательно, с начального адреса – $0060;
//	2) Заполнить исходные массивы произвольными значениями.
//	3) Выполнить операцию ПЕРЕСЕЧЕНИЯ над массивами A и B и результат записать в память в массив C, расположенный по адресу 0x7B.
//	4) В массиве C найти МИНИМАЛЬНЫЙ элемент и записать его по адресу 0x8C.
//	5) Отсортировать массив C по УБЫВАНИЮ.

// Инициализируем несколько "переменных"
.def counter = r16			; Счетчик
.def alt_counter = r17		; Второй счетчик
.def a_current = r18		; Элемент массива А
.def b_current = r19		; Элемент массива B
.def c_current = r20		; Элемент массива C
.def bool = r21				; Логическая переменная
.def mx = r22				; Логическая переменная
.def counterWorkSize = r23	; Счетчик заполненной зоны в массиве
.set sizeAB = 10			; Размер массивов A и B
.set sizeC = 10				; Размер массивов C
.set false = 0				; Логический ноль
.set true = 1				; Логическая единица

// Сегмент данных, работа с памятью
.dseg						; Указатель на сегмент данных
	.org 0x60				; Начальный адрес масивов
		arr_a: .byte sizeAB ; Выделяем sizeAB байт на массив А
		arr_b: .byte sizeAB ; Выделяем sizeAB байт на массив В
	.org 0x7B
		arr_c: .byte sizeC  ; Выделяем sizeС байт на массив С
	.org 0x8C
		min_el: .byte 1		; Выделим 1 байт под максимальный элемент

// Сегмент кода, выполнение задания
.cseg ; Входим в сегмент кода

// Формируем регистровые пары
ldi xl, low(arr_c)	; X
ldi xh, high(arr_c)
ldi yl, low(arr_b)	; Y
ldi yh, high(arr_b)
ldi zl, low(arr_a)	; Z
ldi zh, high(arr_a)

// Заполнение массивов A и B
// A = [ 9,10,11,12,13,14,15,16,17,18]
// B = [15,14,13,12,11,10, 9, 8, 7, 6]
// Общие элементы: 9, 10, 11, 12, 13, 14, 15
ldi a_current, 9		; Переменная для заполнения массива a
ldi counter, sizeAB		; Устанавливаем размер счетчика
MASA:					; Заполняем массив a
	st z+, a_current	; Сохранение a_current в масив В и инкремент указателя
	inc a_current
	dec counter
brne MASA				; Условия цикл заполнения массива a

ldi b_current, 15		; Переменная для заполнения массива B
ldi counter, sizeAB		; Устанавливаем размер счетчика
MASB:					; Заполняем массив B
	st y+, b_current	; Сохранение b_current в масив В и инкремент указателя
	dec b_current
	dec counter
brne MASB				; Условия цикл заполнения массива В

// ПЕРЕСЕЧЕНИЕ.
// Массив C должен содержать следующие числа:
// C = [0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x00, 0x00, 0x00].
// Просматриваем массив A на элементы пересечения с элементами массива B
// Повторно формируем регистровые пары X и Y, т.к. работали с их адресами
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
		cp b_current, a_current ; Сравнить b_current с a_current
		brne RAZN1				; Перейти, если b_current не равно a_current
		ldi bool, true			; Иначе bool == true
		inc counterWorkSize
		RAZN1:
			dec counter
			brne FILL2AB		; Условия цикл нахождения элемента a_current в В

	cpi bool, true		; Сравнить bool с false (true)
	brne RAZN2			; Перейти, если bool не равно false
	st x+, a_current	; x = a_current, x = x + 1
	RAZN2:
		dec alt_counter	; Декремент счетчика №2
brne FILL1AB

// Поиск МИНИМАЛЬНОГО элемента.
// По адресу 0x8C должен записаться 0x00 (пустой элемент), т.к. размер массива C (10)
// больше найденного вектора пересечения (7),
// и минимальным элементом обозначится пустой элемент (0x00).
// Формируем регистровую пару Z
ldi xl, low(arr_c)	; X
ldi xh, high(arr_c)
ld mx,x				; Устанавливаем значение первого элемента

mov counter, counterWorkSize
Find_min:
	ld c_current, x+	; сi=x, x=x+1
	cp mx, c_current	; Сравнить c_current с mx
	BRLO nebol			; Перейти если c_current меньше mx
	mov mx, c_current	; Иначе mx = c_current
	nebol:
	dec counter
brne Find_min

ldi yl, low(min_el)		; Y
ldi yh, high(min_el)
st y, mx

// Сортировка по УБЫВАНИЮ
// После сортировки получится следующий массив:
// C = [0x0F, 0x0E, 0x0D, 0x0C, 0x0B, 0x0A, 0x09, 0x00, 0x00, 0x00]
// 3 нуля в конце - пустые элементы из-за размера массива C = 10 элементов, где 7 не нулевых из них составляют вектор пересечения массивов A и B
SORT:
	ldi xl, low(arr_c)	; X
	ldi xh, high(arr_c)
	ldi bool, false		; bool = false
	mov counter, counterWorkSize
	SORT2:
		ld c_current, x+	; сi=x, x=x+1
		ld mx, x			; mx = x
		cp mx, c_current	; Сравнить mx с c_current
		BRLO SWIP			; Перейти если меньше (больше brsh)
			ldi bool, true	; bool = true
			mov a_current, c_current	; a_current = c_current//
			
			st -x, mx			; x=x-1, x = mx
			ld r13, x+			; r13 не нужен, быстрый способ увеличить x
			st x, a_current		; x = a_current
		SWIP:
		dec counter		; Декремент счетчика
	brne SORT2
	cpi bool, true		; Сравнить bool с true
breq SORT				; Перейти если bool равно true
nop

// Бесконечный цикл
inf:
rjmp inf