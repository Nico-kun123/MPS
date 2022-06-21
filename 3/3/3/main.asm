;
; 3.asm
;
; Created: 03.05.2022 21:31:25
; Author : 413
;

.def temp = r16
.def delay = r17
.def delay2 = r18

nop

RESET:
ser temp
out ddrb, temp
clr temp
out ddrd, temp
ldi temp, 0xC3

nop

LOOP:
out PORTB,temp
sbis PIND, 0x00
	rol temp
sbis PIND, 0x01
	inc temp
sbis PIND, 0x02
	ror temp
sbis PIND, 0x03
	dec temp

nop

dly:
dec delay
	brne dly
dec delay2
	brne dly
rjmp loop
