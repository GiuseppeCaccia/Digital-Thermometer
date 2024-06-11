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