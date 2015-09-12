; Right hand flood fill algorithm for ZX Spectrum
; The main requirement is the smallest amount of memory used.
; Program size plus size of used the stack.
;
; http://www.retroprogramming.com/2015/07/z80-size-programming-challenge-5.html
;
; Compile:
; pasmo -d min-size-fill.asm min-size-fill.bin > test.asm ; ls min-size-fill.bin -l

progStart	EQU	$C400	; 50176
org progStart


SHOW_CURSOR		EQU	1
CALLS_FROM_BASIC	EQU	1
COPY_IMAGE		EQU	1
IMAGE_ADR		EQU	$AC00	;  44032


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
	LD	HL,$2758		; 3
	EXX				; 1
	RET				; 1

ENDIF




IF SHOW_CURSOR

BLIK:
	LD	A,IXH
	XOR	$FF
	LD	IXH,A

	PUSH	BC
	PUSH	HL
	PUSH	DE
   
	EXX
	PUSH	DE
	EXX
	POP	DE			; DE = DE'
	LD	A,H
	OR	A
	JR	nz,ZNACKA_AKTIVNI
	POP	DE
	PUSH	DE
ZNACKA_AKTIVNI:
	CALL	ZISKEJ_ADR_PIXELU
	LD	C,(HL)
	AND	IXH
	OR	(HL)
	LD	(HL),A

	POP	DE
	PUSH	DE   
	PUSH	HL
	CALL	ZISKEJ_ADR_PIXELU
	LD	B,(HL)
	AND	IXH
	OR	(HL)
	LD	(HL),A

	EI
	HALT
	HALT
	DI

	LD	(HL),B
	POP	HL
	LD	(HL),C
   
	POP	DE
	POP	HL
	POP	BC
	RET
   
ENDIF




; **********************************************************************
; ***  Globalni promene ***

; 7 0 1  hi8 lo1 lo2  n n n  . . e  . . .  w . .
; 6   2  hi4     lo4  .$83.  .$0Ee  .$38.  w$E0.
; 5 4 3  hi2 hi1 lo8  . . .  . . e  s s s  w . .

; C = Aktualni azimut = tri sousedni bity jsou jednickove, ve smeru natoceni plus jeho sousedi
; H = Znacka je smazana = 0, nebo obsahuje Azimut v dobe polozeni znacky

; L = Maska osmiokoli
; 7 0 1  hi8 lo1 lo2  pohled shora, 0 je vpred, 2 vpravo atd.
; 6   2  hi4     lo4
; 5 4 3  hi2 hi1 lo8

; DE' = Souradnice YX znacky "Tady jsem uz byl"

; B = counter for loops, etc.
; C = current azimuth
; H = mark is cleared = 0, or contains azimuth at the time of laying the mark
; L = mask eight neighborhood
; DE'= coordinates YX mark "Here I was already"
; DE = current coordinates YX

; **********************************************************************
; Vstup: D = Y, E = X
INIT:
	LD	HL,$0083		; 10:3 Smazana znacka "Byl jsem tady" + Falesna maska osmiokoli ktera vyvola otoceni doprava  
	LD	C,L			;  4:1 $83 = N

IF SHOW_CURSOR
	LD	IXH,H
MAIN:
	CALL	BLIK
  
ELSE

MAIN:
  
ENDIF

; Priorita 0
; ? ? ?
; ?   0
; ? ? ?
	BIT	2,L			; 8:2
	LD	B,$0E			; 7:2 = 14
	CALL	z,OTOCENI_DOPRAVA	;17/10:3 OTOCENI_DOPRAVA, byla tam dira, drzime se totiz prave strany
    
; musi byt call jinak se zase otoci doprava odkud jsme prisli, pokud jsme nepolozili znacku
; pokud byla vpravo mezera, tak mame pred sebou prazdno a uz se nebudeme tocit doleva a znovu opakovat rutinu VYHODNOT_POZICI
  
; Priorita 1
; ? 1 ?
; 1   1
; ? 1 ?
	LD	A,L
	AND	$55			; CTYROKOLI
	SUB	$55
	JR	z,POLOZ_A_KROK		; jsme zazdeni, not PUSH => RET = EXIT program

	call	TEST			; 17:3
	JR	MAIN			; 12:2
; -------------------------------------




; **********************************************************************
TEST:

; A = FF   FB     EF     EB     BF     BB     AF     AB
; ? 0 ?  ? 0 ?  ? 0 ?  ? 0 ?  ? 0 ?  ? 0 ?  ? 0 ?  ? 0 ?
; 1   1  1   0  1   1  1   0  0   1  0   0  0   1  0   0
; ? 1 ?  ? 1 ?  ? 0 ?  ? 0 ?  ? 1 ?  ? 1 ?  ? 0 ?  ? 0 ?
; Priorita 3  
; ? 0 ?
; 1   1
; ? 1 ?
	INC	A			;  4:1 LEVY+PRAVY+ZADNI, nastane uz jen v pripade ze pred nama je prazdno
;	CP	$54			;  7:2
	JR	z,POLOZ_A_KROK		; vylezame ze slepe ulicky
 
; Priorita 2
; ? 1 ?
; ?   ?
; ? ? ?
;	BIT	0,L			;  8:2
	RRCA				;  4:1
	LD	B,$0A			;  7:2 = 10
	JR	c,OTOCENI_DOLEVA	;12/7:2  Pred nama stena?
  
; Takze ted vime, ze pred nama je prazdno, ale muze byt i napravo pokud jsme se otocili

; Priorita 4
; ? 0 ?      ? 0 ?         ? 0 1
; 1   x =>   1   1   nebo  1   0
; ? ? ?      ? ? ?         ? ? ?
	BIT	6,L			;  8:2 "Brana", prava strana je brana ze je vyplnena implicitne, jinak jsme se otocili doprava a pak je minimalne leva a horni pravy plny, takze taky to plati.
	JR	NZ,JEN_KROK		;12/7:2

; Priorita 5 = kontrola "sloupu" v rozich
; 7 0 1  hi8 lo1 lo2   ? 0 1    1 0 ?    ? ? ?    ? ? ?
; 6   2  hi4     lo4   ?   0    0   ?    0   ?    ?   0
; 5 4 3  hi2 hi1 lo8   ? ? ?    ? ? ?    1 0 ?    ? 0 1
  
  
IF 0
	LD	A,L			;  4:1
;	LD	B,4			;  7:2 B = ( 10 nebo 0 ) >= 4
VP_Loop:
	RRCA				;  4:1
	CP	$60			;  7:2   0 ? ?
	JR	nc,VP_Next		;12/7:2  1   ?
	CP	$40			;  8:2   0 ? ?
	JR	nc,JEN_KROK		;12/7:2  $40..$5F
VP_Next:
	RRCA				;  4:1
	DJNZ	VP_Loop			;13/8:2 
					;[:13]
ENDIF
								
; not carry, zero flag
; Use A only!
	LD	A,L			;  4:1  
VP_Loop:  
	ADD	A,A			;  4:1
	JR	nc,VP_Next+1		;12/7:2
	ADD	A,A			;  4:1  
	JR	nc,JEN_KROK		;12/7:2
VP_Next:
	ADD	A,A			;  4:1
	ADD	A,A			;  4:1
	JR	c,VP_Next		;12/7:2
	JR	nz,VP_Loop		;12/7:2
					;[:13]
;	JR POLOZ_A_KROK  



; **********************************************************************
POLOZ_A_KROK:
   
	call	ZISKEJ_ADR_PIXELU	; 17:3 Premaze H = azimut znacky a L = masku osmiokoli
;	OR	(HL)			;  7:1 Tohle vyhodime protoze chyba bude jen pokud pokladame na uz vykresleny pixel, coz nastane jen pokud zacatek je do steny
	LD	(HL),A			;  7:1
	LD	H,B			;  4:1 = 0, smazana znacka "Byl jsem tady"
	LD	L,B			;  4:1 do Osmiokoli dame nulu => bude si myslet ze je to krizovatka a nepolozi znacku kterou mazu
  
;	JR	KROK_VPRED		; MAIN nebo EXIT PROGRAM




; **********************************************************************
; Prilepek k rutine KROK_VPRED, pro variantu nezdim, jen jdu
; C = Aktualni azimut = tri sousedni bity jsou jednickove, ve smeru natoceni plus jeho sousedi
; H = Znacka je smazana = 0, nebo obsahuje Azimut v dobe polozeni znacky
; L = Maska osmiokoli
; DE' = Souradnice YX znacky "Tady jsem uz byl"
JEN_KROK:

; Je to krizovatka? Tzn. ma krome mezery vepredu jeste 2 mezery
; 7 0 1  hi8 lo1 lo2   ? 0 ?    ? 0 ?    ? ? ?    ? ? ?
; 6   2  hi4     lo4   1   0    0   1    0   0    0   0
; 5 4 3  hi2 hi1 lo8   ? 0 ?    ? 0 ?    ? 0 ?    ? 1 ?
	LD	A,L
	AND	$54			; LEVY + ZADNI + PRAVY
	CP	$14			; ZADNI + PRAVY
	JR	c,KROK_VPRED		; prazdny byl LEVY a aspon jeden ze dvou zbyvajicich
	CP	$40			; LEVY je teda nastaven, nebo oba ZADNI+PRAVY
	JR	z,KROK_VPRED		; ZADNI + PRAVY nenastaveny
; neni to krizovatka 

	LD	A,H			;  8:2 Azimut znacky

	PUSH	DE			; 11:1
	EXX				;  4:1

	OR	A			;  4:1 Je polozena? carry = 0
	JR	NZ,JK_POLOZENA
  
; v tehle variante je jedno, ze je nekdy lepsi polozit znacku az za krizovatkou a bude ji pokladat stale a stale a porad zjistovat ze je na spojnici

	POP	DE			; 10:1 DE' = YX znacky
	EXX	
	LD	H,C			;  4:1 Azimut znacky prepsan aktualnim, tim je zaroven znacka aktivni

	JR	KROK_VPRED
  
JK_POLOZENA:				; Znacka je polozena, carry = 0

	POP	HL			; 10:1
	SBC	HL,DE			; 15:2 Shodne souradnice
	EXX				;  4:1
	JR	NZ, KROK_VPRED		;12/7:2
  
	CP	C			;  8:2 Shodne azimuty?  
	JR	z,POLOZ_A_KROK
  ; Znacka byla polozena, ale prisli jsme z jineho smeru, takze lezi na spojnici dvou casti a
  ; behame v te chodbe tam a zpet. Pokud bychom ji rozdelili nevyplnime jednu polovinu plochy.
  ; Nemuzeme ani hned smazat znacku, protoze priste pujdeme z druhe strany a polozime znacku zase sem.
  ; Idealni reseni je polozit znacku v puvodnim smeru, jinak se zacykli na trojmezi 3 spojnic, ale az za krizovatkou.
  ; Nam ted postaci v puvodnim smeru, ale jen o pixel. Pak zjisti ze je zase na spojnici a zase ho posune az k te krizovatce.
  
	LD	C,A			;  4:1 Natocime se do puvodniho smeru kdy jsme znacku pokladali
	LD	H,$00			;  7:2 = 0 = smazana znacka "Byl jsem tady"
; pokracujeme rutinou KROK_VPRED




; **********************************************************************
; Rutina nastavi masku osmiokoli, zmeni souradnici v DE
; Vstup: 
;	maska osmiokoli v C

;	7 0 1 pohled shora, 0 je vpred, 2 vpravo, atd.
;	6   2
;	5 4 3

;	D = Y
;	E = X
; Vystup: DE po kroku vpred
; Meni: A, B = 0, HL, DE
KROK_VPRED:
	PUSH	HL			; 11:1 Potrebujeme uchovat H = azimut znacky
	call	PRICTI_XY		; 17:3 meni: A, BC, DE = New DE, HL 
	POP	HL			; 10:1
; Vstup: nic
; Vystup: maska bude kompletne nastavena
NASTAV_OSMIOKOLI:
	LD	B,8			;  7:2
OTOCENI_DOLEVA:				; B = 8 + 2     = 10
OTOCENI_DOPRAVA:			; B = 8 - 2 + 8 = 14

KV_LOOP:
	RRC	C			;  8:2 Otocime azimut doleva o 45 stupnu
	PUSH	BC			; 11:1 Pouzijeme B i C pro azimut
	PUSH	DE			; 11:1
	PUSH	HL			; 11:1 Potrebujeme uchovat H = azimut znacky
	call	PRICTI_XY		; 17:3
	POP	HL			; 10:1
	POP	DE			; 10:1
	POP	BC			; 10:1
	RL	L			;  8:2 Vysledek z carry natlacime zprava do bitu nula masky osmiokoli v bit 7 vypadne do carry 
	DJNZ KV_LOOP			;13/8:2

	RET				; 10:1




; **********************************************************************
; Rutina udela vypocet Y += dY, X += dX
; Pokud jsou souradnice mimo okraj tak vraci carry!
; Vstup: 
;	DE = YX
;	C = Azimut = tri sousedni bity jsou nastaveny na jedna

;	7 0 1   hi8 lo1 lo2   n n n   . nene   . . e   . . .    . . .   . . .   w . .   nwnw.
;	6   2   hi4     lo4   .   .   .   ne   .   e   .   se   .   .   sw  .   w   .   nw  .
;	5 4 3   hi2 hi1 lo8   . . .   . . .    . . e   . sese   s s s   swsw.   w . .   . . .  

; Vystup: DE = NewYX nebo carry
; Meni: A, DE  
PRICTI_XY:

; Y orezani resi az fce ZISKEJ_ADR_PIXELU
; Y-1?
      BIT	0,C			;  8:2
      JR	z,PXY0			;12/7:2
      DEC	D			;  4:1 Y--
PXY0:

; Y+1?
      BIT	4,C			;  8:2
      JR	z,PXY1			;12/7:2
      INC	D			;  4:1 Y++
      
PXY1:
      AND	A			;  4:1 carry = 0
      LD	A,E			;  4:1
      LD	E,$01			;  7:2
      
; X-1?
      BIT	6,C			;  8:2
      JR	z,PXY2			;12/7:2
      SUB	E			;  4:1 X--
      
PXY2:
; X+1?
      BIT	2,C			;  8:2
      JR	z,PXY3			;12/7:2
      ADD	A,E			;  4:1 X++
      
PXY3:
      LD	E,A			;  4:1
      RET	c			;11/5:1
					;[:26]




; **********************************************************************
; Rutina prevede souradnice YX na adresu bajtu s pixelem a jeho masku v danem bajtu
; Vstup: 
; 	D = Y, E = X
;	Y = BB RRR SSS X = CCCCC ...
; Vystup: 
;	HL = adresa bajtu,
;	A = maska pixelu
;	B = 0 pokud dobehne do konce, carry = PIXEL

; H = 010 BB SSS L = RRR CCCCC
; BB:    číslo bloku 0,1,2 (v bloku číslo 3 je atributová paměť)
; SSS:   číslo řádky v jednom znaku, který je vysoký osm obrazových řádků
; RRR:   pozice textového řádku v bloku. Každý blok je vysoký 64 obrazových řádků, což odpovídá osmi řádkům textovým
; CCCCC: index sloupce bajtu v rozmezí 0..31, kde je uložena osmice sousedních pixelů
ZISKEJ_ADR_PIXELU:
  
	LD	A,D			;  4:1 BBRRRSSS = Y
	CP	192			;  7:2
	CCF				;  4:1 carry = 1 - carry 
	RET	c			; 11/5:1         carry = 0
	RRA				;  4:1 0BBRRRSS, carry = ?
	SCF				;  4:1           carry = 1
	RRA				;  4:1 10BBRRRS, carry = ?
	AND	A			;  4:1           carry = 0
	RRA				;  4:1 010BBRRR
	LD	L,A			;  4:1 .....RRR
	XOR	D			;  4:1 ???????? provede se 2x takze zadna zmena, mezitim ale smazem spodek, tak to udela + (b mod 8)
	AND	$F8			;  7:2 ?????000
	XOR	D			;  4:1 010BBSSS Takže H bude obsahovat 64+8*INT (b/64)+(b mod 8)
	LD	H,A			;  4:1 což je vyšší bajt adresy bodu.  

	LD	A,L			;  4:1 .....RRR
	XOR	E			;  4:1 ???????? provede se 2x takze zadna zmena, mezitim ale vynulujeme hornich 5 bitu
	AND	$07			;  7:2 00000???
	XOR	E			;  4:1 CCCCCRRR
	RRCA				;  4:1 RCCCCCRR
	RRCA				;  4:1 RRCCCCCR
	RRCA				;  4:1 RRRCCCCC
	LD	L,A			;  4:1 Takže L bude 32*INT (b/(b mod 64)/8)+INT (x/8).

; Vstup: E = X 
; Vystup: maska pixelu
; Meni: A, B
ZAP_NASTAV_MASKU:
	LD	A,$80			;  7:2  
	LD	B,E			;  4:1 B=0? or B>8? Tak probehne spousta zbytecnych smycek, ale usetrime 3 bajty za LD A,E: AND $07: LD B,A
ZAP_LOOP:
	RRCA				;  4:1 rotace doprava
	DJNZ	ZAP_LOOP		;13/8:2

	XOR	(HL)			;  7:1 A = OR(HL) a pokud tam byl uz pixel, tak bit masky je nula = neztratime masku pro pripadne vyplneni
	CP	(HL)			;  7:1 carry kdyz tam byl pixel
	RET				; 10:1
