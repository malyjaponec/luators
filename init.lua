--init.lua
print("Setting up WIFI...")
wifi.setmode(wifi.STATION)
--modify according your wireless router settings
wifi.sta.config("JIFFACO","***REMOVED***855")
wifi.sta.connect()
 wifi.sta.autoconnect(1)
tmr.alarm(1, 1000, 1, function() 
if wifi.sta.getip()== nil then 
print("IP unavaiable, Waiting...") 
else 
tmr.stop(1)
print("Config done, IP is "..wifi.sta.getip())
dofile("send2cloud.lua")
end 
end)
-- Pozhasinani ledek
-- cervena 
gpio.mode(8, gpio.OUTPUT)
gpio.write(8, gpio.LOW)
-- zelena
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


