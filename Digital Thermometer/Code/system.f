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