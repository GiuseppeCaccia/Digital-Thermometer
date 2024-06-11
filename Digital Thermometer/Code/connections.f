\ Connections.f
DECIMAL
\ GPIO connections
: LED_GREEN ( -- n_gpio) 27 ;
: LED_RED ( -- n_gpio) 22 ;
: LED_BLUE ( -- n_gpio) 17 ;
: DHT11 ( -- n_gpio ) 13 ;
: SCL ( -- n_gpio ) 3 ;
: SDA ( -- n_gpio ) 2 ;
\ Setup for LED 
: SETUP_LED_BLUE ( -- ) LED_BLUE SET_OUTPUT ;
: SETUP_LED_GREEN ( -- ) LED_GREEN SET_OUTPUT ;
: SETUP_LED_RED ( -- ) LED_RED SET_OUTPUT ;
: SETUP_LEDS SETUP_LED_BLUE SETUP_LED_GREEN SETUP_LED_RED ;
\ Sets the alternative function for display related GPIOs
: SETUP_DISPLAY SDA SET_ALTF0 SCL SET_ALTF0 ;