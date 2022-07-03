import gpio

class IOR : Driver
  var PIN_SCLK
  var PIN_SDOUT
  var PIN_SDIN
  var PIN_INPUT_LD
  var PIN_OUTPUT_LD
  var PIN_OUTS_ON
  var PIN_OUT4
  var entradas
  var saidas


  # readInput
  def readInput()
    gpio.digital_write(self.PIN_INPUT_LD, 1)

    for i: 0..23
      self.entradas.setbits(i, 1, !gpio.digital_read(self.PIN_SDIN))
      
      gpio.digital_write(self.PIN_SCLK, 0)
      gpio.digital_write(self.PIN_SCLK, 1)
    end

    gpio.digital_write(self.PIN_INPUT_LD, 0)
  end


  # writeOutput
  def writeOutput()
    gpio.digital_write(self.PIN_OUTPUT_LD, 0)
    gpio.digital_write(self.PIN_SCLK, 0)

    for i: 0..15
      gpio.digital_write(self.PIN_SDOUT, self.saidas.getbits(15-i, 1))
      gpio.digital_write(self.PIN_SCLK, 1)
      gpio.digital_write(self.PIN_SCLK, 0)
    end

    gpio.digital_write(self.PIN_OUTPUT_LD, 1)
  end


  # init
  def init()
      self.PIN_SCLK = 5
      self.PIN_SDOUT = 18
      self.PIN_SDIN = 19
      self.PIN_INPUT_LD = 21
      self.PIN_OUTPUT_LD = 22
      self.PIN_OUTS_ON = 23
      self.entradas = bytes("5A5B5C")
      self.saidas = bytes("FF00")
      
      gpio.pin_mode(self.PIN_OUTS_ON, gpio.OUTPUT)
      gpio.digital_write(self.PIN_OUTS_ON, 1)

      gpio.pin_mode(self.PIN_SCLK, gpio.OUTPUT)
      gpio.pin_mode(self.PIN_SDOUT, gpio.OUTPUT)
      gpio.pin_mode(self.PIN_SDIN, gpio.INPUT_PULLUP)
      gpio.pin_mode(self.PIN_INPUT_LD, gpio.OUTPUT)
      gpio.pin_mode(self.PIN_OUTPUT_LD, gpio.OUTPUT)
      print("Driver IOR inicializado")
      print("Entradas: " + str(self.entradas))
      print("Saidas: " + str(self.saidas))

      gpio.digital_write(self.PIN_OUTS_ON, 0)

  end

  # every_second
  def every_second()
      self.readInput()
      self.saidas[0]=self.entradas[0]
      self.saidas[1]=self.entradas[1]
      self.writeOutput()
      print("Entradas:" + str(self.entradas))
      print("Saidas:" + str(self.saidas))
  end

end

ior = IOR()
tasmota.add_driver(ior)
