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