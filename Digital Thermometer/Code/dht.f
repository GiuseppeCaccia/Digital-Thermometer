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