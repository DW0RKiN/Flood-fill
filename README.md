# Flood-fill
Flood fill algorithms for ZX Spectrum

Contribution to competition Size Z80 Programming Challenge #5

http://www.retroprogramming.com/2015/07/z80-size-programming-challenge-5.html

    Right hand flood fill algorithm 
    min-size-fill.asm 
    171 bytes

    Vyplneni pomoci emulace fronty na zasobniku. 
    Musi byt vypnute preruseni, protoze v urcitem okamziku vracime SP az k zarazce 
    a pak ho vratime zpet na puvodni hodnotu. Mezitim se ale nesmi prepsat data 
    co lezi mezi temito adresami na zasobniku prerusenim.
    queue-fill.asm 
    84 bytes
