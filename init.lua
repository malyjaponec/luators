function init_part2()
    print("Vyhledani AP...")
    -- nahrazuje wifi.sta.config(ssid,password)
        aptools = require("aptools")
        wifi.sta.getap(aptools.select_ap)
        if aptools.found() == 0 then -- nebylo nalezeno
            -- opakuji to po 5 s
            print("Odpocivam ...")
            tmr.alarm(1, 3000, 0, function() init_part2() end)   
            return
        end
        aptools = nil
    wifi.sta.connect()
    wifi.sta.autoconnect(1)
    tmr.alarm(1, 1000, 0, function() init_part3() end);
end


function init_part3()
    if wifi.sta.getip()== nil then 
        print("IP unavaiable, Waiting...") 
        tmr.alarm(1, 1000, 0, function() init_part3() end);
    else 
        print("Config done, IP is "..wifi.sta.getip())
        dofile("send2cloud.lua")
    end
end

function init_partX()
    print("Rovnam piny pro kit...")
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
end

--init.lua
print("Nastavuji station...")
wifi.sta.config("myssid","mypassword") -- aby se to nikem neprihlasilo
wifi.setmode(wifi.STATION)
init_partX()
tmr.alarm(1, 1000, 0, function() init_part2() end)
