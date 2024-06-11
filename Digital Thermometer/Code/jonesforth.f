\ Annotation has been removed from this file to expedite processing.
\ See the files in the /annexia/ for a full Literate Code tutorial, it's great!

: '\n' 10 ;
: BL 32 ;
: ':' [ CHAR : ] LITERAL ;
: ';' [ CHAR ; ] LITERAL ;
: '(' [ CHAR ( ] LITERAL ;
: ')' [ CHAR ) ] LITERAL ;
: '"' [ CHAR " ] LITERAL ;
: 'A' [ CHAR A ] LITERAL ;
: '0' [ CHAR 0 ] LITERAL ;
: '-' [ CHAR - ] LITERAL ;
: '.' [ CHAR . ] LITERAL ;
: ( IMMEDIATE 1 BEGIN KEY DUP '(' = IF DROP 1+ ELSE ')' = IF 1- THEN THEN DUP 0= UNTIL DROP ;
: SPACES ( n -- ) BEGIN DUP 0> WHILE SPACE 1- REPEAT DROP ;
: WITHIN -ROT OVER <= IF > IF TRUE ELSE FALSE THEN ELSE 2DROP FALSE THEN ;
: ALIGNED ( c-addr -- a-addr ) 3 + 3 INVERT AND ;
: ALIGN HERE @ ALIGNED HERE ! ;
: C, HERE @ C! 1 HERE +! ;
: S" IMMEDIATE ( -- addr len )
	STATE @ IF
		' LITS , HERE @ 0 ,
		BEGIN KEY DUP '"'
                <> WHILE C, REPEAT
		DROP DUP HERE @ SWAP - 4- SWAP ! ALIGN
	ELSE
		HERE @
		BEGIN KEY DUP '"'
                <> WHILE OVER C! 1+ REPEAT
		DROP HERE @ - HERE @ SWAP
	THEN
;
: ." IMMEDIATE ( -- )
	STATE @ IF
		[COMPILE] S" ' TELL ,
	ELSE
		BEGIN KEY DUP '"' = IF DROP EXIT THEN EMIT AGAIN
	THEN
;
: DICT WORD FIND ;
: VALUE ( n -- ) WORD CREATE DOCOL , ' LIT , , ' EXIT , ;
: TO IMMEDIATE ( n -- )
        DICT >DFA 4+
	STATE @ IF ' LIT , , ' ! , ELSE ! THEN
;
: +TO IMMEDIATE
        DICT >DFA 4+
	STATE @ IF ' LIT , , ' +! , ELSE +! THEN
;
: ID. 4+ COUNT F_LENMASK AND BEGIN DUP 0> WHILE SWAP COUNT EMIT SWAP 1- REPEAT 2DROP ;
: ?HIDDEN 4+ C@ F_HIDDEN AND ;
: ?IMMEDIATE 4+ C@ F_IMMED AND ;
: WORDS LATEST @ BEGIN ?DUP WHILE DUP ?HIDDEN NOT IF DUP ID. SPACE THEN @ REPEAT CR ;
: FORGET DICT DUP @ LATEST ! HERE ! ;
: CFA> LATEST @ BEGIN ?DUP WHILE 2DUP SWAP < IF NIP EXIT THEN @ REPEAT DROP 0 ;
: SEE
	DICT HERE @ LATEST @
	BEGIN 2 PICK OVER <> WHILE NIP DUP @ REPEAT
	DROP SWAP ':' EMIT SPACE DUP ID. SPACE
	DUP ?IMMEDIATE IF ." IMMEDIATE " THEN
	>DFA BEGIN 2DUP
        > WHILE DUP @ CASE
		' LIT OF 4 + DUP @ . ENDOF
		' LITS OF [ CHAR S ] LITERAL EMIT '"' EMIT SPACE
			4 + DUP @ SWAP 4 + SWAP 2DUP TELL '"' EMIT SPACE + ALIGNED 4 -
		ENDOF
		' 0BRANCH OF ." 0BRANCH ( " 4 + DUP @ . ." ) " ENDOF
		' BRANCH OF ." BRANCH ( " 4 + DUP @ . ." ) " ENDOF
		' ' OF [ CHAR ' ] LITERAL EMIT SPACE 4 + DUP @ CFA> ID. SPACE ENDOF
		' EXIT OF 2DUP 4 + <> IF ." EXIT " THEN ENDOF
		DUP CFA> ID. SPACE
	ENDCASE 4 + REPEAT
	';' EMIT CR 2DROP
;
: :NONAME 0 0 CREATE HERE @ DOCOL , ] ;
: ['] IMMEDIATE ' LIT , ;
: EXCEPTION-MARKER RDROP 0 ;
: CATCH ( xt -- exn? ) DSP@ 4+ >R ' EXCEPTION-MARKER 4+ >R EXECUTE ;
: THROW ( n -- ) ?DUP IF
	RSP@ BEGIN DUP R0 4-
        < WHILE DUP @ ' EXCEPTION-MARKER 4+
		= IF 4+ RSP! DUP DUP DUP R> 4- SWAP OVER ! DSP! EXIT THEN
	4+ REPEAT DROP
	CASE
		0 1- OF ." ABORTED" CR ENDOF
		." UNCAUGHT THROW " DUP . CR
	ENDCASE QUIT THEN
;
: ABORT ( -- ) 0 1- THROW ;
: PRINT-STACK-TRACE
	RSP@ BEGIN DUP R0 4-
        < WHILE DUP @ CASE
		' EXCEPTION-MARKER 4+ OF ." CATCH ( DSP=" 4+ DUP @ U. ." ) " ENDOF
		DUP CFA> ?DUP IF 2DUP ID. [ CHAR + ] LITERAL EMIT SWAP >DFA 4+ - . THEN
	ENDCASE 4+ REPEAT DROP CR
;
: BINARY ( -- ) 2 BASE ! ;
: OCTAL ( -- ) 8 BASE ! ;
: 2# BASE @ 2 BASE ! WORD NUMBER DROP SWAP BASE ! ;
: 8# BASE @ 8 BASE ! WORD NUMBER DROP SWAP BASE ! ;
: # ( b -- n ) BASE @ SWAP BASE ! WORD NUMBER DROP SWAP BASE ! ;
: UNUSED ( -- n ) PAD HERE @ - 4/ ;
: WELCOME
	S" TEST-MODE" FIND NOT IF
		." JONESFORTH VERSION " VERSION . CR
		UNUSED . ." CELLS REMAINING" CR
		." OK "
	THEN
;
WELCOME
HIDE WELCOME


\Versione 2
\ Some word definitions taken from pijFORTHos.
\ Link: https://github.com/organix/pijFORTHos/blob/master/annexia/jonesforth.f.txt

\ These words are necessery in order to PRINT_STRING (in lcd.f)
\ to work properly. 
\ After a number of attempts trying to rencocile these definitions with
\ those contained in se-ans.f, I observed that lookup_table.f stop working.
\ The problem resides in the use of OF - ENDOF.
\ This file must be uploaded as the first one.

\ We can use [ and ] to insert literals which are calculated at compile time.  
\ (Recall that [ and ] are the FORTH words that allow you to exit and enter compilation mode.)
\ Within definitions, use [ ... ] LITERAL anywhere that '...' is a constant expression
\ which you would rather only compute once (at compile time, rather than calculating 
\ it each time your word runs).

\ Returns the ASCII code of ".
: '"' ( -- ascii_code )
    [ CHAR " ] LITERAL ;

\ Takes an address and rounds it up (aligns it) to the next 4 byte boundary.
: ALIGNED ( c_addr -- a_addr )
    3 + 3 INVERT AND ;

\ Aligns the HERE pointer, so the next word appended will be aligned properly.
: ALIGN ( -- )
    HERE @ ALIGNED HERE ! ;

\ Appends a byte to the current compiled word.
: C, ( byte -- )
    HERE @ C! 1 HERE +! ;


\ S" string" is used in FORTH to define strings.  It leaves the address of the string and
\ its length on the stack, (length at the top of stack).  The space following S" is the 
\ normal space between FORTH words and is not a part of the string.
\ This is tricky to define because it has to do different things depending on whether
\ we are compiling or in interpret mode.  (Thus the word is marked IMMEDIATE so it can
\ detect this and do different things).
\ In compile mode we apppend the string length and the string rounded up 4 bytes
\ to the current word.  
\ In interpret mode there isn't a particularly good place to put the string, but in this
\ case we put the string at HERE (but we _don't_ change HERE). This is meant as a 
\ temporary location, likely to be overwritten soon after.
: S" IMMEDIATE ( -- addr len )
	STATE @ IF
		' LITS , HERE @ 0 ,
		BEGIN KEY DUP '"'
                <> WHILE C, REPEAT
		DROP DUP HERE @ SWAP - 4- SWAP ! ALIGN
	ELSE
		HERE @
		BEGIN KEY DUP '"'
                <> WHILE OVER C! 1+ REPEAT
		DROP HERE @ - HERE @ SWAP
	THEN ;
