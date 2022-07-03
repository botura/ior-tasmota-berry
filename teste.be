import gpio

var PIN_INP1 = 12
var PIN_INP2 = 13
var PIN_INP3 = 14
var PIN_OUT1 = 15
var PIN_OUT2 = 16
var PIN_OUT3 = 17
var PIN_OUT4 = 18


gpio.pin_mode(PIN_INP1, gpio.OUTPUT)
gpio.pin_mode(PIN_INP2, gpio.OUTPUT)
gpio.pin_mode(PIN_INP3, gpio.INPUT)
gpio.pin_mode(PIN_OUT1, gpio.OUTPUT)
gpio.pin_mode(PIN_OUT2, gpio.OUTPUT)
gpio.pin_mode(PIN_OUT3, gpio.OUTPUT)
gpio.pin_mode(PIN_OUT4, gpio.OUTPUT)

print(gpio.digital_read(PIN_INP1))
gpio.digital_write(PIN_INP1, 1)
print(gpio.digital_read(PIN_INP1))
