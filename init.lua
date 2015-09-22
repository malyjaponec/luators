-- init.lua
StartTime = tmr.now()
RunCounter = 0
uart.setup(0,115200,0,1,1)

-- Pozhasinani ledek
	-- cervena 
		gpio.mode(8, gpio.OUTPUT)
		gpio.write(8, gpio.LOW)
	-- zelena
    -- Nezapnuti proudu do 18b20 sestavy, napaji GPIO 12
		gpio.mode(6, gpio.OUTPUT)
		gpio.write(6, gpio.LOW)
	-- modra
		gpio.mode(7, gpio.OUTPUT)
		gpio.write(7, gpio.LOW)
	-- mala cervena zhruba uprostred prosvecovala
		gpio.mode(2, gpio.OUTPUT)
		gpio.write(2, gpio.HIGH)
	-- a vedle dalsi
		gpio.mode(1, gpio.OUTPUT)
		gpio.write(1, gpio.HIGH)

-- toto cekani je pro pripad nutnosti to zastavit ale taky
-- protoze modul se sam prihlasi na wifi kdyz se necha chvili byt
tmr.alarm(0, 3000, 0,  function() dofile("start.lc") end)
print(" . ")
print(" . ")
