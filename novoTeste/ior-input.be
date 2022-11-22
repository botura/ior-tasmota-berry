import strict
import gpio
import mqtt
import string

class IOR : Driver
  var PIN_SCLK
  var PIN_SDIN
  var PIN_INPUT_LD
  var PIN_OUTPUT_LD
  var entradas
  var dipswtich
  var tmrSendMessage
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
    
    gpio.digital_write(self.PIN_SCLK, 0) # preciso deixar em 0 para não atrapalhar 74x595 do Tasmota

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


  # init
  def init()
      self.PIN_SCLK = 5
      self.PIN_SDIN = 19
      self.PIN_INPUT_LD = 21
      self.entradas = 0x0000
      self.entradas_semFiltro = self.entradas
      self.entradas_filtro = 0
      self.dipswtich = 0x00
      self.tmrSendMessage = 0
      
      # gpio.pin_mode(self.PIN_SCLK, gpio.OUTPUT)
      gpio.pin_mode(self.PIN_SDIN, gpio.INPUT_PULLUP)
      gpio.pin_mode(self.PIN_INPUT_LD, gpio.OUTPUT)
      print("Driver IOR inicializado")
  end


  # every_50ms
  def every_50ms()
      # update inputs
      self.readInput()
  end


  # every_second
  def every_second()
      self.tmrSendMessage += 1
      if (self.tmrSendMessage >= 60) # send message every 60s
        self.tmrSendMessage = 0
        # self.sendMessage()
      end
      print("Entradas:" + str(self.entradas))
      print("Dipswitch:" + str(self.dipswtich))
  end


end

ior = IOR()
tasmota.add_driver(ior)
