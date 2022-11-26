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
  var dipSwitch
  var tmr_filtro_entradas
  var entradas_semFiltro
  var triggerEntradas
  var memTriggerEntradas



  # readInput
  def readInput()
    var entradas_raw = bytes(-2)
    gpio.digital_write(self.PIN_INPUT_LD, 1)
    
    for i: 0..15
      entradas_raw.setbits(15-i, 1, !gpio.digital_read(self.PIN_SDIN))

      gpio.digital_write(self.PIN_SCLK, 0)
      gpio.digital_write(self.PIN_SCLK, 1)
    end
    
    for i: 0..7
      self.dipSwitch.setbits(7-i, 1, !gpio.digital_read(self.PIN_SDIN))
      gpio.digital_write(self.PIN_SCLK, 0)
      gpio.digital_write(self.PIN_SCLK, 1)
    end
    
    gpio.digital_write(self.PIN_SCLK, 0) # preciso deixar em 0 para não atrapalhar 74x595 do Tasmota
    gpio.digital_write(self.PIN_INPUT_LD, 0)


    # filtro das entradas
    if (entradas_raw == self.entradas_semFiltro) 
      self.tmr_filtro_entradas += 1
    else 
      self.tmr_filtro_entradas = 0
    end

    if (self.tmr_filtro_entradas >= 0) 
      self.entradas = entradas_raw
    end
    self.entradas_semFiltro = entradas_raw


    # Trigger das entradas
    for i: 0..15
      if (self.entradas.getbits(i, 1) && !self.memTriggerEntradas.getbits(i, 1))
        self.triggerEntradas.setbits(i, 1, 1)
        if (i<=7)
          tasmota.set_power(i+8, !tasmota.get_power()[i+8])
        else
          tasmota.set_power(i-8, !tasmota.get_power()[i-8])
        end
      else
        self.triggerEntradas.setbits(i, 1, 0)
        self.memTriggerEntradas.setbits(i, 1, 1)
      end
      self.memTriggerEntradas.setbits(i, 1, self.entradas.getbits(i, 1))
    end
  end


  # init
  def init()
      self.PIN_SCLK = 5
      self.PIN_SDIN = 19
      self.PIN_INPUT_LD = 21
      self.entradas = bytes(-2)
      self.entradas_semFiltro = bytes(-2)
      self.tmr_filtro_entradas = 0
      self.dipSwitch = bytes(-1)
      self.triggerEntradas = bytes(-2)
      self.memTriggerEntradas = bytes(-2)
      
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
      # print("entradas: " + str(self.entradas))
      # print("dipSwitch: " + str(self.dipSwitch))
  end


end

ior = IOR()
tasmota.add_driver(ior)
