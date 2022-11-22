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
  var dipswtich
  var tmrSendMessage
  var topic
  var entradas_filtro
  var entradas_semFiltro



  # readInput
  def readInput()
    var entradas_raw = 0x0000
    var dipswitch_raw = 0x00
    gpio.digital_write(self.PIN_INPUT_LD, 1)
    
    var mask = 0x0080
    for i: 0..15
      entradas_raw = entradas_raw | (!gpio.digital_read(self.PIN_SDIN) ? mask : 0)
      
      gpio.digital_write(self.PIN_SCLK, 0)
      gpio.digital_write(self.PIN_SCLK, 1)
      mask >>= 1
      if i==7 mask = 0x8000 end
    end
    
    mask = 0x80
    for i: 0..7
      dipswitch_raw = dipswitch_raw | (!gpio.digital_read(self.PIN_SDIN) ? mask : 0)
      
      gpio.digital_write(self.PIN_SCLK, 0)
      gpio.digital_write(self.PIN_SCLK, 1)
      mask >>= 1
    end

    gpio.digital_write(self.PIN_INPUT_LD, 0)


    # filtro das entradas
    if (entradas_raw == self.entradas_semFiltro) 
      self.entradas_filtro += 1
    else 
      self.entradas_filtro = 0
    end

    if (self.entradas_filtro > 0) 
      self.entradas = entradas_raw
    end
    self.entradas_semFiltro = entradas_raw

    self.dipswtich = dipswitch_raw

  end


  # writeOutput
  def writeOutput()
    var mask = 0x8000
    gpio.digital_write(self.PIN_OUTPUT_LD, 0)
    gpio.digital_write(self.PIN_SCLK, 0)

    for i: 0..15
      gpio.digital_write(self.PIN_SDOUT, (self.saidas & mask ? 0 : 1))

      gpio.digital_write(self.PIN_SCLK, 1)
      gpio.digital_write(self.PIN_SCLK, 0)
      mask >>= 1
      if i==7 mask = 0x0080 end
    end

    gpio.digital_write(self.PIN_OUTPUT_LD, 1)
  end


  # sendMessage
  def sendMessage()
    var payloadEntradas = "{"
    var payloadSaidas = "{"
    # var teste = self.entradas[0]<<8 + self.entradas[1]
    var mask = 1
    for i:0..15
      payloadEntradas += string.format("\"e%s\":%s", i+1, (self.entradas & mask) ? 1 : 0)
      payloadSaidas += string.format("\"s%s\":%s", i+1, (self.saidas & mask) ? 1 : 0)
      mask <<= 1
      if (i < 15)
        payloadEntradas+=","
        payloadSaidas+=","
      end
    end

    payloadEntradas+="}"
    payloadSaidas+="}"

    mqtt.publish(string.format("stat/%s/entradas", self.topic), payloadEntradas)
    mqtt.publish(string.format("stat/%s/saidas", self.topic), payloadSaidas)
    mqtt.publish(string.format("stat/%s/sensors", self.topic), tasmota.read_sensors())
  end


  # init
  def init()
      self.PIN_SCLK = 5
      self.PIN_SDOUT = 18
      self.PIN_SDIN = 19
      self.PIN_INPUT_LD = 21
      self.PIN_OUTPUT_LD = 22
      self.PIN_OUTS_ON = 23
      self.entradas = 0x0000
      self.entradas_semFiltro = self.entradas
      self.entradas_filtro = 0
      self.dipswtich = 0x00
      self.saidas = 0x0000
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

      self.writeOutput()
      gpio.digital_write(self.PIN_OUTS_ON, 0)
  end


  # every_50ms
  def every_50ms()
      # update inputs
      self.readInput()

      # do some processing
      self.saidas=self.entradas
      
      # update outputs
      self.writeOutput()
  end


  # every_second
  def every_second()
      self.tmrSendMessage += 1
      if (self.tmrSendMessage >= 60) # send message every 60s
        self.tmrSendMessage = 0
        self.sendMessage()
      # print("Entradas:" + str(self.entradas))
      # print("Dipswitch:" + str(self.dipswtich))
      # print("Saidas:" + str(self.saidas))       

      end
  end


  # # json_append
  # def json_append()
  #   var msg = string.format(",\"IOR\":{\"Entradas\":\"%s\",\"Saidas\":\"%s\"}",
  #             str(self.entradas), str(self.saidas))
  #   tasmota.response_append(msg)
  # end

end

ior = IOR()
tasmota.add_driver(ior)
