local ip_timeout = 0

local function init_part4()
    aptools = mil
    if nil == wifi.sta.getip() then 
        ip_timeout = ip_timeout + 1
        print("IP unavaiable, waiting..."..(ip_timeout)) 
        if ip_timeout < 10 then
            tmr.alarm(0, 2000, 0, function() init_part4() end)
        else
            -- prepare reboot
            local time = (60 * 1000) - (tmr.now()/1000)
            if time < 15000 then time = 15000 end
            tmr.alarm(0, time, 0, function() node.restart() end)
            print("Restart scheduled in "..(time/1000).." s") 
        end    
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
        ip_timeout = 0
        tmr.alarm(0, 5000, 0, function() init_part4() end)
    end
end

-- start.lua
--tmr.alarm(1, 1000, 1, function() print(node.heap()) end) -- pokud se pouzije padne to na nedostatek pameti
wifi.sta.config("nesmysl","nesmysl1") -- aby se to nikem neprihlasilo, jinak nefunguje poradne vyhedani 
wifi.setmode(wifi.STATION)
tmr.alarm(0, 1000, 0, function() init_part2() end)
