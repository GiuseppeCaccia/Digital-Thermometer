\ Time.f
HEX
\ RPPI4 Timer base address
FE003000 CONSTANT RPI4_BASE_TIMER
\ Sets Timer registers with an offset
RPI4_BASE_TIMER 4 + CONSTANT CLO
\ Delays for the time given as input (in microseconds)
: DELAY ( us -- ) CLO @ BEGIN 2DUP CLO @ - ABS SWAP > UNTIL 2DROP ;