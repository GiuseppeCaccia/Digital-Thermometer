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