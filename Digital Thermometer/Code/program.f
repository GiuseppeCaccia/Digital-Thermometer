\ Jonesforth.f
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

\ Utils.f
DECIMAL
\ From microseconds to milliseconds 
: TO_MS ( time_us -- time_ms ) 1000 * ;
\ From Celsius to Kelvin
: TO_KELVIN ( temp_celsius -- temp_kelvin ) 273 + ;
\ Converts a char to his ASCII encoding
: TO_ASCII_2 ( var -- d_ascii u_ascii ) DUP 10 MOD 48 + SWAP 10 / 48 + SWAP ;
: TO_ASCII_3 ( var -- ascii ) DUP DUP 100 / 48 + ROT 10 / 10 MOD 48 + ROT 10 MOD 48 + ; 
: TO_ASCII @ DUP 100 / IF TO_ASCII_3 ELSE TO_ASCII_2 THEN ;
\ Computes the absolute value of the given number
: ABS ( n -- |n| ) DUP 0 < IF -1 * THEN ;

\ GPIO.f
HEX
\ RPPI4 GPIO base address
FE200000 CONSTANT RPI4_BASE_GPIO
\ Reach GPIO registers with an offset
RPI4_BASE_GPIO 1C + CONSTANT GPSET0
RPI4_BASE_GPIO 28 + CONSTANT GPCLR0
RPI4_BASE_GPIO 34 + CONSTANT GPLEV0
\ Checks if the GPIO is valid
: CHECK_GPIO ( n_gpio -- boolean ) DUP 0>= SWAP 39 <= AND ;
\ Drops invalid GPIOs
: INVALID_GPIO ( n_gpio -- ) DROP ." GPIO is not valid." CR ;
\ Finds Registers
: RPI4_BASE_GPIO_REGISTER ( n_gpio -- rpi4_base_register_addr ) DUP CHECK_GPIO
    IF
        A / 4 * RPI4_BASE_GPIO +
    ELSE
        INVALID_GPIO
    THEN ;
: GPSET0_REGISTER ( n_gpio -- gpset0_register_addr ) DUP CHECK_GPIO
    IF
        20 / 4 * GPSET0 +
    ELSE
        INVALID_GPIO
    THEN ;
: GPCLR0_REGISTER ( n_gpio -- gpclr0_register_addr ) DUP CHECK_GPIO
    IF
        20 / 4 * GPCLR0 +
    ELSE
        INVALID_GPIO
    THEN ;
: GPLEV0_REGISTER ( n_gpio -- gplev0_register_addr ) DUP CHECK_GPIO
    IF
        20 / 4 * GPLEV0 +
    ELSE
        INVALID_GPIO
    THEN ;
\ Calculates the mask for bit clearing
: MASK_CLEAN ( n_gpio -- mask_fsel ) A MOD 3 * 7 SWAP LSHIFT ;
\ Bit clear function
: BIT_CLEAR ( register mask -- cleaned_register ) INVERT AND ;
\ Sets GPIO input
: SET_INPUT ( n_gpio -- ) DUP RPI4_BASE_GPIO_REGISTER DUP @ ROT MASK_CLEAN BIT_CLEAR SWAP ! ;
\ Sets GPIO output
: SET_OUTPUT ( n_gpio -- ) DUP DUP RPI4_BASE_GPIO_REGISTER DUP @ ROT MASK_CLEAN BIT_CLEAR ROT A MOD 3 * 1 SWAP LSHIFT OR SWAP ! ;
\ Sets GPIO with its alternative function
: SET_ALTF0 ( n_gpio -- ) DUP DUP RPI4_BASE_GPIO_REGISTER DUP @ ROT MASK_CLEAN BIT_CLEAR ROT A MOD 3 * 4 SWAP LSHIFT OR SWAP ! ;
\ Returns input from GPIO
: GET_INPUT ( n_gpio -- boolean )
    DUP GPLEV0_REGISTER @ SWAP 20 MOD 1 SWAP LSHIFT AND
    IF
        1 
    ELSE
        0 
    THEN ;
\ Sets GPIO bit to 1 in the GPSET register
: GPIO_ON ( n_gpio -- ) DUP GPSET0_REGISTER SWAP 20 MOD 1 SWAP LSHIFT SWAP ! ;
\ Sets GPIO bit to 1 in the GPCLR register
: GPIO_OFF ( n_gpio -- ) DUP GPCLR0_REGISTER SWAP 20 MOD 1 SWAP LSHIFT SWAP ! ;

\ Connections.f
DECIMAL
\ GPIO connections
: LED_GREEN ( -- n_gpio) 4 ;
: LED_RED ( -- n_gpio) 5 ;
: LED_BLUE ( -- n_gpio) 6 ;
: DHT11 ( -- n_gpio ) 9 ;
: SCL ( -- n_gpio ) 3 ;
: SDA ( -- n_gpio ) 2 ;
\ Setup for LED 
: SETUP_LED_BLUE ( -- ) LED_BLUE SET_OUTPUT ;
: SETUP_LED_GREEN ( -- ) LED_GREEN SET_OUTPUT ;
: SETUP_LED_RED ( -- ) LED_RED SET_OUTPUT ;
: SETUP_LEDS SETUP_LED_BLUE SETUP_LED_GREEN SETUP_LED_RED ;
\ Sets the alternative function for display related GPIOs
: SETUP_DISPLAY SDA SET_ALTF0 SCL SET_ALTF0 ;

\ Time.f
HEX
\ RPPI4 Timer base address
FE003000 CONSTANT RPI4_BASE_TIMER
\ Sets Timer registers with an offset
RPI4_BASE_TIMER 4 + CONSTANT CLO
\ Delays for the time given as input (in microseconds)
: DELAY ( us -- ) CLO @ BEGIN 2DUP CLO @ - ABS SWAP > UNTIL 2DROP ;

\ DHT11.f
DECIMAL 
\ Contains the data received from the humidity-temperature sensor
VARIABLE DHT_BITS
\ Contains the current temperature
VARIABLE CURRENT_INDEX
\ Contains the current humidity index
VARIABLE CURRENT_INDEX_HUM
\ Contains the temperature average
VARIABLE MEDIA
\ Contains the humidity average
VARIABLE MEDIA_HUMIDITY
\ Counter
VARIABLE COUNTER 
\ Number of measurements
30 CONSTANT NUM_MEASUREMENTS
\ Number DHT cicles
31 CONSTANT DHT_CICLE
\ Contains each temperature value
VARIABLE CUMULATOR
\ Contains each humidity value
VARIABLE CUMULATOR_HUMIDITY
\ Contains the integer value of temperature (in Celsius)
VARIABLE HUMIDITY_INT
\ Containt temporaneus humidity values
VARIABLE HUMIDITY_T
\ Contains the integer value of temperature (in Celsius)
VARIABLE TEMP_INT
\ Contains temporaneous temperature values
VARIABLE TEMP_T
\ Contains the integer value of temperature (in Kelvin)
VARIABLE TEMP_INT_KELVIN
\ DHT11 Start Signal
: DHT_SIGNAL ( -- ) DHT11 SET_OUTPUT DHT11 GPIO_OFF 18000 DELAY DHT11 GPIO_ON DHT11 SET_INPUT ;
: BIT_0 ( -- ) BEGIN DHT11 GET_INPUT 0 = WHILE REPEAT ;
: BIT_1 ( -- ) BEGIN DHT11 GET_INPUT 1 = WHILE REPEAT  ;
\ Verify if the bit is 1 or 0
: READ_DHT ( -- )
    BIT_0 BIT_1 
    DHT_CICLE BEGIN 
        DHT_BITS DUP @ 1 LSHIFT SWAP ! BIT_0 CLO @ BIT_1 CLO @ SWAP - 50 > 
        IF 
            DHT_BITS DUP @ 1 OR SWAP ! 
        THEN 
        1 - DUP 0 > 
        WHILE REPEAT DROP ;
\ Do the measurements for temperature
: READ_TEMP_T ( -- ) DHT_BITS @ 8 RSHIFT 255 AND ;
\ Do the measurements for humidity
: READ_HUMIDITY_T ( -- ) DHT_BITS @ 24 RSHIFT ;
\ Humidity Filtering
: HUM_FILTERING ( -- )
    DUP DUP 0 > SWAP 100 < AND \verify if humidity is in range
    IF  
        HUMIDITY_T ! 
        HUMIDITY_T @ CUMULATOR_HUMIDITY +!
        1 CURRENT_INDEX_HUM +! 
        ." Umidità rilevata: " HUMIDITY_T @ . ." % " CR 
    ELSE
        DROP
        ." Umidità fuori dal range previsto " CR
    THEN ;
\ Temperature Filtering
: TEMP_FILTERING ( -- )
    DUP DUP 0 > SWAP 50 < AND \Verify if temperature is in range
    IF  
        TEMP_T ! 
        TEMP_T @ CUMULATOR +!
        1 CURRENT_INDEX +! 
        ." Temperatura rilevata: " TEMP_T @ . ." °C " CR 
    ELSE
        DROP
        ." Temperatura fuori dal range previsto " CR
    THEN ;
\ Calculate humidity average
: CALCULATE_AVERAGE_HUMIDITY ( -- )
    CUMULATOR_HUMIDITY @ 0 >
    IF
        CUMULATOR_HUMIDITY @ CURRENT_INDEX_HUM @ / MEDIA_HUMIDITY !
    ELSE 
        0 MEDIA_HUMIDITY !
    THEN
    ;
\ Calculate temperature average
: CALCULATE_AVERAGE ( -- )
    CUMULATOR @ 0 >
    IF
        CUMULATOR @ CURRENT_INDEX @ / MEDIA !
    ELSE 
        0 MEDIA !
    THEN
    ;
\ Start measurements
: MEASURE ( -- )
    30000 DELAY
    DHT_SIGNAL READ_DHT 
    ." Misurazione Eseguita " CR
    READ_TEMP_T
    TEMP_FILTERING 
    READ_HUMIDITY_T 
    HUM_FILTERING 
    ;
\ Start cicling
: CICLE ( -- )
    BEGIN
        ." Misurazione N° " COUNTER @ . CR  
        MEASURE
        1 COUNTER +!                          
        COUNTER @ NUM_MEASUREMENTS <                             
    WHILE
        TRUE                                    
    REPEAT DROP ;
\ Do all the measurements
: MEASURE_ALL ( -- )
    CICLE
    CALCULATE_AVERAGE
    CALCULATE_AVERAGE_HUMIDITY
    ." Somma delle temperature rilevate: " CUMULATOR @ . CR
    ." Somma delle umidità rilevate: " CUMULATOR_HUMIDITY @ . CR
    ." Numero di misurazioni di temperatura valide: " CURRENT_INDEX @ . CR
    ." Numero di misurazioni di umidità valide: " CURRENT_INDEX_HUM @ . CR
    MEDIA @ TEMP_INT ! 
    MEDIA_HUMIDITY @ HUMIDITY_INT !
    ;
\ Print Humidity in the console
: PRINT_HUM ( -- ) ." Humidity: " HUMIDITY_INT ? ." % " CR ;
\ Print Temperature in the console
: PRINT_TEMPERATURE ( -- ) ." Temp: " TEMP_INT ? ." ° C" CR ;
\ Initialize variables
: INITIALIZE ( -- ) 0 COUNTER ! 0 CURRENT_INDEX ! 0 CURRENT_INDEX_HUM ! 0 CUMULATOR ! 0 CUMULATOR_HUMIDITY ! 0 DHT_BITS ! 0 TEMP_INT_KELVIN ! ;
\ Converts from Celsius to Kelvin
: CONVERT ( -- ) TEMP_INT @ TO_KELVIN TEMP_INT_KELVIN ! ;
\ Start measuring
: START_MEASUREMENT ( -- ) INITIALIZE MEASURE_ALL CONVERT PRINT_HUM PRINT_TEMPERATURE ;

\ LCD.f
HEX
\ RPPI4 BSC (Broadcom Serial Control) base address
FE804000 CONSTANT RPI4_BASE_BSC1
\ Sets BSC registers with an offset
RPI4_BASE_BSC1 8 + CONSTANT BSC1_DLEN
RPI4_BASE_BSC1 10 +  CONSTANT BSC1_FIFO
RPI4_BASE_BSC1 C + CONSTANT BSC1_A
\ Returns true if the value is a command
: IS_COMMAND ( value -- boolean ) 100 AND ;
\ Stores the value in the data BSC1 FIFO register
: BSC1_STORE ( value -- )
    BSC1_FIFO ! ;
\ Sets as 1 the dimension of the value (in bytes)
: BSC1_1BYTE ( -- )
    1 BSC1_DLEN ! ;
\ Sets as 0 the "Read Transfer bit" and as 1 the "Start Transfer" bit and the "I2C Enable" bit in the control register
: I2C_ENABLE ( -- )
    8080 RPI4_BASE_BSC1 ! ;
\ Starts I2C Bus 
: I2C_BUS ( value -- )
    BSC1_STORE
    BSC1_1BYTE
    I2C_ENABLE ;
\ Sends 4 bits to the display
: 4BIT_CHAR ( is_command, value -- )
    DUP ROT 
    IF
        C + 
    ELSE
        D + 
    THEN
    I2C_BUS 1 TO_MS DELAY
    8 + I2C_BUS 2 TO_MS DELAY ;
\ Prints a character on the display
: PRINT_CHAR ( value -- ) DUP IS_COMMAND SWAP 2DUP F0 AND 4BIT_CHAR F AND 4 LSHIFT 4BIT_CHAR 5 TO_MS DELAY ;
\ Cleans the display
: LCD_CLEAR ( -- )
    101 PRINT_CHAR ;
\ Prints a string on the display
: PRINT_STRING ( a_0, a_1, ..., a_n -- )
    LCD_CLEAR DEPTH DUP
    BEGIN
        DUP 0 > 
    WHILE
        ROT >R 1 -
    REPEAT
    DROP 
    BEGIN
        DUP 0 > 
    WHILE
        R> PRINT_CHAR 1 -
    REPEAT
    DROP ;
\ Prints the humidity value on the display
: PRINT_HUMIDITY ( -- ) 48 75 6D 69 64 69 74 79 3A 20 HUMIDITY_INT TO_ASCII 25 1C0 ;
\ Prints the temperature value on the display (in Celsius)
: PRINT_TEMPERATURE_CELSIUS ( -- ) 54 65 6D 70 3A 20 TEMP_INT TO_ASCII DF 43 ;
\ Prints the temperature value on the display (in Kelvin)
: PRINT_TEMPERATURE_KELVIN ( -- ) 54 65 6D 70 3A 20 TEMP_INT_KELVIN TO_ASCII DF 4B ;
\ Configures the display by setting the value 3F in the slave address and sending the command 0x02 ("set 4-bit mode")
: LCD_INIT ( -- ) 3F BSC1_A ! 102 PRINT_CHAR ;

\ System.f
\ System MODE:
\ 0 = OFF
\ 1 = Celsius
\ 2 = Kelvin
DECIMAL
VARIABLE MODE
\ Switch mode
: SWITCH_MODE ( -- ) MODE DUP @ 1 + 3 MOD SWAP ! ;
\ "Boot" the system
: BOOT ( -- ) 0 MODE ! SETUP_LEDS SETUP_DISPLAY LCD_INIT ." Setup Completed " CR ;
\ Makes a measurement and shows the measured values on the display (Celsius)
: CELSIUS_TEMPERATURE ( -- ) LCD_CLEAR START_MEASUREMENT PRINT_HUMIDITY PRINT_TEMPERATURE_CELSIUS PRINT_STRING ;
\ Makes a measurement and shows the measured values on the display (Kelvin)
: KELVIN_TEMPERATURE ( -- )  LCD_CLEAR START_MEASUREMENT PRINT_HUMIDITY PRINT_TEMPERATURE_KELVIN PRINT_STRING ;
\ Turn all LEDs ON
: ALL_LED_ON ( -- ) LED_RED GPIO_ON LED_BLUE GPIO_ON LED_GREEN GPIO_ON ;
\ Turn all LEDs OFF
: ALL_LED_OFF ( -- ) LED_RED GPIO_OFF LED_BLUE GPIO_OFF LED_GREEN GPIO_OFF ;
\ Turn the LED ON according to temperature range
: LED_ON ( -- )
    \ Cool Temperature
    TEMP_INT @ 0 > TEMP_INT @ 19 < AND
    IF
        LED_BLUE GPIO_ON 
        LED_GREEN GPIO_OFF
        LED_RED GPIO_OFF
        ." BLUE LED ON! " CR CR
    ELSE
        \ Medium Temperature
        TEMP_INT @ 19 >= TEMP_INT @ 29 < AND
        IF
            LED_GREEN GPIO_ON 
            LED_BLUE GPIO_OFF
            LED_RED GPIO_OFF
            ." GREEN LED ON! " CR CR
        ELSE
            \ Hot Temperature
            TEMP_INT @ 29 >= TEMP_INT @ 50 < AND
            IF
                LED_RED GPIO_ON 
                LED_BLUE GPIO_OFF
                LED_GREEN GPIO_OFF
                ." RED LED ON! " CR CR
            ELSE
                ALL_LED_OFF
                ." LEDs OFF! " CR CR
            THEN
        THEN
    THEN ;
\ Check if MODE is zero before entering the loop
: CHECK_MODE ( -- )
    MODE @ 0 = 
    IF
        ALL_LED_ON ." System OK. Starting INIT LOOP." CR
    ELSE
        ." System IS NOT OK. Aborting INIT LOOP." CR
    THEN ;
\ Makes the system work
: INIT ( -- )
    BEGIN
        15000000 DELAY
        IF
            SWITCH_MODE
        THEN
        MODE @ 1 = 
        IF
            ." Loading Mesuraments... " CR 
            CELSIUS_TEMPERATURE 
            LED_ON 
        ELSE
            MODE @ 2 = 
            IF
                ." Loading Mesuraments... " CR
                KELVIN_TEMPERATURE 
                LED_ON
            ELSE
                ." Cleaning LCD Display... " CR CR
                LCD_CLEAR 
            THEN
        THEN
        DROP
    AGAIN ;

\ Main.f
: MAIN ( -- )
    BOOT
    CHECK_MODE
    INIT ;

