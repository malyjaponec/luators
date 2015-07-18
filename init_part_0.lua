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

