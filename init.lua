-- init.lua
StartTime = tmr.now()
RunCounter = 0
ReportInterval = 5
uart.setup(0,115200,0,1,1)

-- Nastaveni sbernice s teplomery (vypnuto)
   gpio.mode(6, gpio.OUTPUT) -- 12
   gpio.write(6, gpio.LOW)
   gpio.mode(7, gpio.OUTPUT) -- 14
   gpio.write(7, gpio.LOW)
-- Nastaveni vsutpnich pinu   
   gpio.mode(5, gpio.INPUT, gpio.FLOAT) -- 14
   gpio.mode(0, gpio.INPUT, gpio.FLOAT) -- 16
   gpio.mode(2, gpio.INPUT, gpio.FLOAT) -- 4
   gpio.mode(1, gpio.INPUT, gpio.FLOAT) -- 5

-- toto cekani je pro pripad nutnosti to zastavit ale taky
-- protoze modul se sam prihlasi na wifi kdyz se necha chvili byt
tmr.alarm(0, 3000, 0,  function() dofile("start.lc") end)
print(" . ")
print(" . ")
