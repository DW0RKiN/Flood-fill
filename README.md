# Flood-fill
Flood fill algorithms for ZX Spectrum

Contribution to competition Size Z80 Programming Challenge #5

http://www.retroprogramming.com/2015/07/z80-size-programming-challenge-5.html

min-size-fill.asm 
------------------
171 bytes

Right hand flood fill algorithm 

    LOOPING_MODE = false;
    set DIRECTION;
    set MASK;

    while ( 1 ) {

    TEST_1:         // Drzime se prave steny
    if MASK == ? ? ?
               ?   0
               ? ? ? TURN_RIGHT();

    TEST_2:         // Jsme zazdeni?
    if MASK == ? 1 ?
               1   1
               ? 1 ? { DRAW_PIXEL(); EXIT; }
    
    TEST_3:         // Slepa ulicka?  
    if MASK == ? 0 ?
               1   1
               ? 1 ? { FILL_AND_STEP(); continue; }

    TEST_4:         // Prekazka?
    if MASK == ? 1 ?
               ?   ?
               ? ? ? { TURN_LEFT(); continue; }

    TEST_5:         // Brana?   . 0 .     ? 0 ?      ? 0 1
                    //          1   ? =>  1   1  or  1   0
                    //          . . .     ? ? ?      ? ? ?
    if MASK == ? ? ?
               1   ?
               ? ? ? { STEP(); continue; }

    TEST_6:         // Slouporadi
    if MASK == ? 0 1      1 0 ?      ? ? ?      ? ? ?
               ?   0  or  0   ?  or  0   ?  or  ?   0
               ? ? ?      ? ? ?      1 0 ?      ? 0 1 { STEP(); continue; }

    FILL_AND_STEP(); 

    }

    ; --------------
    FILL_AND_STEP() {
       DRAW_PIXEL;
       LOOPING_MODE = false;
       NOW_XY += DIRECTION;
       set MASK;
    }

    ; -------------
    STEP() {
    
    if ( LOOPING_MODE ) {
    
       if ( BEGIN_LOOP_XY == NOW_XY )) {
            if ( LOOP_DIRECTION == NOW_DIRECTION ) { 
                FILL_AND_STEP(); 
                return; 
            } else { 
                LOOPING_MODE = false; 
                NOW_DIRECTION = LOOP_DIRECTION;  // smer musime dodrzet, hrozi zacykleni
                // lepsi je ale zakazat LOOPING_MODE dokud neprojdu krizovatkou
            }
        }
    } else {
        ; Je to krizovatka? Tzn. ma krome mezery vepredu jeste 2 mezery
        if  ! ( MASK == ? ? ?       ? ? ?      ? ? ?      ? ? ?
                        1   0  or   0   1  or  0   0  or  0   0
                        ? 0 ?       ? 0 ?      ? 0 ?      ? 1 ? ) { 
            LOOPING_MODE = true;  
            LOOP_BEGIN_XY = NOW_XY; 
            LOOP_DIRECTION = NOW_DIRECTION;
        }
    }
    
    NOW_XY += DIRECTION;
    set MASK;
    
    }
    

queue-fill.asm
--------------
84 bytes

Vyplneni pomoci emulace fronty na zasobniku. Musi byt vypnute preruseni, protoze v urcitem okamziku pomalu presouvame SP az k zarazce a pak ho vratime zpet na puvodni hodnotu. Mezitim se ale nesmi prepsat data co lezi mezi temito adresami na zasobniku prerusenim.

