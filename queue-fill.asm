; Queue flood fill algorithm for ZX Spectrum
; The main requirement is the smallest amount of memory used.
; Program size plus size of used the stack.
;
; http://www.retroprogramming.com/2015/07/z80-size-programming-challenge-5.html
;
; Compile:
; pasmo -d queue-fill.asm queue-fill.bin > test.asm; ls queue-fill.bin -l

progStart  	equ	$6000	; 24576
org	progStart


TURBO_MODE		EQU	0
CALLS_FROM_BASIC	EQU	1
COPY_IMAGE		EQU	0
IMAGE_ADR		EQU	$6100	; 24832

IF TURBO_MODE

START_Q			EQU	$FB
END_Q			EQU	$FE
; queue $FB00..$FEFF
; 1024 bytes queue sufficient for a normal picture, but specially treated anti-queue image needs more

ENDIF



IF COPY_IMAGE

; copy image on screen			;
	LD	BC,192*32		; 3 6144
	LD	DE,$4000		; 3
	LD	HL,IMAGE_ADR		; 3
	LDIR				; 2
ENDIF



IF CALLS_FROM_BASIC

; Busyho kod pro nacteni parametru primo z Basicu
; PRINT USR addr, x, y

	RST	$20			; 1
	CALL	$24FB			; 3
	RST	$20			; 1
	CALL	$24FB			; 3
	CALL	$2DD5			; 3
	PUSH	AF			; 1
	CALL	$2DD5			; 3
	POP	DE			; 1
	LD	E,A			; 1

	CALL	INIT			; 3 $C42C: call $C435
	EI				; 1
	LD	HL,$2758		; 3
	EXX				; 1 TURBO_MODE use HL'
	RET				; 1

ENDIF





; **********************************************************************
; Vstup: E = Y, D = X
INIT:

IF TURBO_MODE
	EXX			;  4:1
	LD	HL,256*(END_Q+1); 10:3 HL = Last in
	LD	D,H		;  4:1
	LD	E,L		;  4:1 DE = First in
	EXX			;  4:1
	CALL	PUSH_PIXEL	; 17:3
  
MAIN:

LOAD_PIXEL:
; Vystup: DE = XY pixelu
	EXX			;  4:1
    
	AND	A		;  4:1 carry = 0
	SBC	HL,DE		; 15:2
;	EXX
	RET	z		;11/5:1 otoci stinovy za obyc pri odchodu
;	EXX
	ADD	HL,DE		; 11:1
;				[41/35:5]

	EX	DE,HL		;  4:1
	CALL	DEC_HL		; 17:3 HL = First in
	LD	B,(HL)		;  7:1
	DEC	L		;  4:1
	LD	C,(HL)		;  7:1
	EX	DE,HL		;  4:1
	PUSH	BC		; 11:1
	EXX			;  4:1
	POP	DE		; 10:1

ELSE
; Jako Y souradnice se mohou objevit hodnoty $C0 = 192 a $FF = 255 = -1
	LD	C,$F8		;  7:2 pouzije se to jeste jako maska
	PUSH	BC		; 11:1 Zarazka

	CALL	PUSH_PIXEL	; 17:3
  
MAIN:

	POP	DE		; 10:1
	LD	A,E		;  4:1
	CP	C		;  4:1 $F8
	RET	z		;11/5:1 Zarazka?

ENDIF



; X++
	INC	D		;  4:1
	CALL	nz, PUSH_PIXEL	;17/10:3
  
; X--
	DEC	D		;  4:1
	JR	z,Y_PLUS	;12/7:2  LD A,D: INC D: OR A: call nz,PUSH_PIXEL 8:2
	DEC	D		;  4:1
	CALL	PUSH_PIXEL	; 17:3
	INC	D		;  4:1
  
Y_PLUS:
; Test rozsahu se provadi pri prevodu YX na adresu, stoji to tam jen 2 bajty navic
; Y++
	INC	E		;  4:1
	CALL	PUSH_PIXEL	; 10:3
  
	DEC	E		;  4:1
	DEC	E		;  4:1
	CALL	PUSH_PIXEL	; 17:3
	JR	MAIN		; 12:2




; **********************************************************************
; Rutina vykresli pixel pokud neni a uzlozi ho do fronty
; Vstup: 
;	D = X
;	E = Y 
PUSH_PIXEL:

; Rutina ziska adresu bajtu pixelu o zname souradnici XY 
; Vstup: D = X, E = Y 
; Vystup: HL = adresa bajtu
; H = 010 BB SSS L = RRR CCCCC
; X = CCCCC ...  Y = BB RRR SSS  DE = XY
; BB:    číslo bloku 0,1,2 (v bloku číslo 3 je atributová paměť)
; SSS:   číslo řádky v jednom znaku, který je vysoký osm obrazových řádků
; RRR:   pozice textového řádku v bloku. Každý blok je vysoký 64 obrazových řádků, což odpovídá osmi řádkům textovým
; CCCCC: index sloupce bajtu v rozmezí 0..31, kde je uložena osmice sousedních pixelů

	LD	A,E		;  4:1 BBRRRSSS = Y
	AND	A		;  4:1           carry = 0
	RRA			;  4:1 0BBRRRSS, carry = ?
	CP	$60		;  7:2 192/2=96
	RET	nc		;11/5:1          carry = 1
	RRA			;  4:1 10BBRRRS, carry = ?
	AND	A		;  4:1           carry = 0
	RRA			;  4:1 010BBRRR
	LD	L,A		;  4:1 .....RRR
	XOR	E		;  4:1 ???????? provede se 2x takze zadna zmena, mezitim ale smazem spodek, tak to udela + (b mod 8)
IF TURBO_MODE
	AND	$F8		;  7:2 ?????000
ELSE
	AND	C		;  4:1 ?????000 $F8
ENDIF
	XOR	E		;  4:1 010BBSSS Takže H bude obsahovat 64+8*INT (b/64)+(b mod 8)
	LD	H,A		;  4:1 což je vyšší bajt adresy bodu.  

	LD	A,L		;  4:1 .....RRR
	XOR	D		;  4:1 ???????? provede se 2x takze zadna zmena, mezitim ale vynulujeme hornich 5 bitu
	AND	$07		;  7:2 00000???
	XOR	D		;  4:1 CCCCCRRR
	RRCA			;  4:1 RCCCCCRR
	RRCA			;  4:1 RRCCCCCR
	RRCA			;  4:1 RRRCCCCC
	LD	L,A		;  4:1 Takže L bude 32*INT (b/(b mod 64)/8)+INT (x/8).

; Rutina ziska masku pixelu v bajtu
; Vstup: D = X 
; Vystup: maska pixelu
; Meni: A, B

IF TURBO_MODE
	LD	A,D		;  4:1
	AND	$07		;  7:2
	LD	B,A		;  4:1
	INC	B		;  4:1
	LD	A,$01		;  7:2
ELSE
	LD	A,$80		;  7:2  
	LD	B,D		;  4:1 B=0? or B>8? Tak probehne spousta zbytecnych smycek, ale usetrime 3 bajty za LD A,D: AND $07: LD B,A
ENDIF
TP_MASK_LOOP:
	RRCA			;  4:1 rotace doprava
	DJNZ	TP_MASK_LOOP	;13/8:2
  
  
; Rutina vykresli pixel pokud neni, nebo opusti rutinu
	XOR	(HL)		;  7:1
	CP	(HL)		;  7:1
	RET	c		;11/5:1 carry = PIXEL
	LD	(HL),A		;  7:1
 

 
IF TURBO_MODE

SAVE_PIXEL:
; Vstup: DE = XY pixelu
; Nehlida stav kdy zacnu premazavat nejstarsi data pokud je kruhovy buffer mensi nez ukladana data
	PUSH	DE		; 11:1
	EXX			;  4:1
	POP	BC		; 10:1
	CALL	DEC_HL		; 17:3 HL = Last in
	LD	(HL),B		;  7:1
	DEC	L		;  4:1
	LD	(HL),C		;  7:1
	EXX			;  4:1    
	RET			; 11:1
  
DEC_HL:
	DEC	HL		;  6:1
	LD	A,H		;  4:1
	CP	START_Q		;  7:2
	RET	nc		;11/5:1
	LD	H,END_Q		;  7:2
	RET			; 11:1

  
ELSE
; Rutina ulozi souradnice pixelu na zasobnik az tesne nad zarazku, FIFO 
	LD	HL,-$0002	; 10:3
	ADD	HL,SP		; 11:1 HL = SP-2
	DI			;  4:1
	LD	A,C		;  4:1 $F8 zarazka

; EX	(SP),HL		; 19:1 HL = a DE = ? SP =   X b c d e f
; PUSH	HL		; 11:1 HL = a DE = ? SP = A x b c d e f
; POP	HL		; 10:1 HL = a DE = ? SP = a X b c d e f
; POP	HL		; 10:1 HL = x DE = ? SP = a x B c d e f  
  
; EX	(SP),HL		; 19:1 HL = b DE = ? SP = a x X c d e f
; PUSH	HL		; 11:1 HL = b DE = ? SP = a B x c d e f
; POP	HL		; 10:1 HL = b DE = ? SP = a b X c d e f
; POP	HL		; 10:1 HL = x DE = ? SP = a b x C d e f 


	EX	(SP),HL		; 19:1 HL = a SP =   S b c
PP_STACK:
  
	PUSH	HL		; 11:1 HL = a SP = A s b c 
	POP	HL		; 10:1 HL = a SP = a S b c
	POP	HL		; 10:1 HL = s SP = a s B c 
	EX	(SP),HL		; 19:1 HL = b SP = a s S c
	CP	L		;  4:1
	JR	nz,PP_STACK	;12/7:2
  
	EX	(SP),HL		; 19:1 HL = s SP = a s B c, vratime zarazku
	PUSH	DE		; 11:1 HL = s SP = a x B c
	LD	SP,HL		;  6:1
	RET			; 11:1


;  POP	BC		; 10:1 BC = a SP =   a B c d
;PP_STACK:  
;  PUSH	BC		; 11:1 BC = a SP =   A b c d 
;  PUSH	BC		; 11:1 BC = a SP = A a b c d
;  POP	BC		; 10:1 BC = a SP = a A b c d
;  POP	BC		; 10:1 BC = a SP = a a B c d
;  POP	BC		; 10:1 BC = b SP = a a b C d
;  CP	C		;  4:1
;  JR	nz,PP_STACK	;12/7:2
;   
;  PUSH	BC		; 11:1 BC = b SP = a a B c d, vratime zarazku
;  PUSH	DE		; 11:1 BC = b SP = a X B c d, ulozime souradnici
;  LD	SP,HL		;  6:1
;  RET			; 11:1

ENDIF
