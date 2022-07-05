import strict
import gpio
import mqtt
import string

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
  var tmrSendMessage
  var topic
  var entradas_filtro
  var entradas_semFiltro



  # readInput
  def readInput()
    var entradas_raw = bytes("000000", -3)
    gpio.digital_write(self.PIN_INPUT_LD, 1)

    for i: 0..23
      entradas_raw.setbits(i, 1, !gpio.digital_read(self.PIN_SDIN))
      
      gpio.digital_write(self.PIN_SCLK, 0)
      gpio.digital_write(self.PIN_SCLK, 1)
    end

    gpio.digital_write(self.PIN_INPUT_LD, 0)


    # filtro
    if (entradas_raw == self.entradas_semFiltro) 
      self.entradas_filtro += 1
    else 
      self.entradas_filtro = 0
    end

    if (self.entradas_filtro > 0) 
      self.entradas = entradas_raw
    end
    self.entradas_semFiltro = entradas_raw

  end


  # writeOutput
  def writeOutput()
    gpio.digital_write(self.PIN_OUTPUT_LD, 0)
    gpio.digital_write(self.PIN_SCLK, 0)
    var aux = bytes("0000", -2) # -2 -> tamanhno máximo do array é 2
    aux[0]=self.saidas[1]
    aux[1]=self.saidas[0]

    for i: 0..15
      gpio.digital_write(self.PIN_SDOUT, (aux.getbits(i, 1)==0) ? 1 : 0)

      gpio.digital_write(self.PIN_SCLK, 1)
      gpio.digital_write(self.PIN_SCLK, 0)
    end

    gpio.digital_write(self.PIN_OUTPUT_LD, 1)
  end


  # sendMessage
  def sendMessage()
    mqtt.publish(string.format("stat/%s/entradas", self.topic), self.entradas)
    mqtt.publish(string.format("stat/%s/saidas", self.topic), self.saidas)
  end


  # init
  def init()
      self.PIN_SCLK = 5
      self.PIN_SDOUT = 18
      self.PIN_SDIN = 19
      self.PIN_INPUT_LD = 21
      self.PIN_OUTPUT_LD = 22
      self.PIN_OUTS_ON = 23
      self.entradas = bytes("000000", -3) # -3 -> tamanhno máximo do array é 3
      self.entradas_semFiltro = self.entradas
      self.entradas_filtro = 0
      self.saidas = bytes("0000", -2) # -2 -> tamanhno máximo do array é 2
      self.tmrSendMessage = 0
      
      gpio.digital_write(self.PIN_OUTS_ON, 1)
      gpio.pin_mode(self.PIN_OUTS_ON, gpio.OUTPUT)

      gpio.pin_mode(self.PIN_SCLK, gpio.OUTPUT)
      gpio.pin_mode(self.PIN_SDOUT, gpio.OUTPUT)
      gpio.pin_mode(self.PIN_SDIN, gpio.INPUT_PULLUP)
      gpio.pin_mode(self.PIN_INPUT_LD, gpio.OUTPUT)
      gpio.pin_mode(self.PIN_OUTPUT_LD, gpio.OUTPUT)
      print("Driver IOR inicializado")

      # descobre o topic do mqtt
      var res = tasmota.cmd("Status6")
      res = res["Status"]
      self.topic = res["Topic"]

      gpio.digital_write(self.PIN_OUTS_ON, 0)

  end


  # every_50ms
  def every_50ms()
      # update inputs
      self.readInput()

      # do some processing
      self.saidas[0]=self.entradas[0]
      self.saidas[1]=self.entradas[1]
      
      # update outputs
      self.writeOutput()
  end


  # every_second
  def every_second()
      # print("Entradas:" + str(self.entradas))
      # print("Saidas:" + str(self.saidas))

      self.tmrSendMessage += 1
      if (self.tmrSendMessage >= 5) # send message every 5s
        self.tmrSendMessage = 0
        self.sendMessage()
      end
  end

end

ior = IOR()
tasmota.add_driver(ior)
