local function init_part4()
    aptools = mil
    if nil == wifi.sta.getip() then 
        print("IP unavaiable, waiting...") 
        tmr.alarm(0, 2000, 0, function() init_part4() end)
    else 
        print("Config done, IP is "..wifi.sta.getip())
        dofile("send2cloud.lc")
    end
end

local function init_part2()
    print("Searching AP...")
    aptools = require("aptools")
    wifi.sta.getap(aptools.select_ap)
    if aptools.found() == 0 then -- nebylo nalezeno
        print("Waiting before AP scan...")
        tmr.alarm(00, 3000, 0, function() init_part2() end)   
        -- musi cekat 3 sekundy jinak to nikdy neprojde a vzdycky to neprochazi na poprve 
        return
    else
        print("Connecting AP...")
        wifi.sta.connect()
        tmr.alarm(0, 5000, 0, function() init_part4() end)
    end
end

-- start.lua
--tmr.alarm(1, 1000, 1, function() print(node.heap()) end) -- pokud se pouzije padne to na nedostatek pameti
wifi.sta.config("nesmysl","nesmysl1") -- aby se to nikem neprihlasilo, jinak nefunguje poradne vyhedani 
wifi.setmode(wifi.STATION)
tmr.alarm(0, 1000, 0, function() init_part2() end)
