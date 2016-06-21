-- send.lua

local function Get_AP_MAC()
    local ssid,pass,bset,bssid
    ssid, pass, bset, bssid=wifi.sta.getconfig()
    if bssid:len() == 17 then -- delka je presne 17 znaku
        local hex,len = bssid:gsub(":","") -- odmazu :
        if len == 5 then -- odmazano presne 5 dvojtecek
            return hex;
        end
    end
    return "????"
end

--------------------------------------------------------------------------------
local function Konec(code, data)
    if (code == nil) then
        code = -100
    end
    if (code > 0) then
        if Debug == 1 then print("s>odeslano/" .. code) end
    else
        if Debug == 1 then print("s>chyba/".. code) end
    end

     -- druhou led zhasnu
     gpio.write(LedSend, gpio.HIGH)
     
    dofile("sleep.lua")
end

--------------------------------------------------------------------------------
local function KontrolaOdeslani()

    if network.status() > 0 and sensors.status() > 0 then -- odesilame

        if Debug == 1 then print("s>sedning...") end
  
       -- rozsvitim druhou led 
       gpio.mode(LedSend, gpio.OUTPUT) 
       gpio.write(LedSend, gpio.LOW)
    
        -- vytvorim zakladni data, ktera chci prenest na cloud
        Rdat = sensors.getvalues()
        Rdat[ReportFieldPrefix.."tm"] = sensors.status()/1000000
        sensors = nil
        package.loaded["sensors"]=nil
  
        -- bateriova data
        min,max,cnt = battery.getvalues()
        battery = nil
        package.loaded["battery"]=nil
        Rdat[ReportFieldPrefix.."bmin"] = min
        Rdat[ReportFieldPrefix.."bmax"] = max
        Rdat[ReportFieldPrefix.."bcnt"] = cnt

        -- sitova data
        Rdat[ReportFieldPrefix.."ti"] = network.status()/1000000
        network = nil
        package.loaded["network"]=nil
       
        -- doplnkova data
        Rdat[ReportFieldPrefix.."cnt"] = Rcnt
        Rdat[ReportFieldPrefix.."x"..Get_AP_MAC()] = 1
        Rdat[ReportFieldPrefix.."ts"] = tmr.now()/1000000
        Rdat[ReportFieldPrefix.."hp"] = node.heap() 
    
        -- prevedu na URL
        local url = "http://emon.jiffaco.cz/emoncms/input/post.json?node=" .. ReportNode .. 
                    "&json=" .. cjson.encode(Rdat) .. 
                    "&apikey=" .. ReportApiKey
        Rdat = nil -- data smazu explicitne
        http.get(url, nil, function(code,data) Konec(code,data) end )
        url = nil -- url uz taky mazu
        tmr.alarm(3, 15000, 0, function() dofile("sleep.lua") end) -- nacasuji kontrolu pokud nezavola callback a zasekne se to

    else
        if network.status() == -1 then
            dofile("sleep.lua")
        else
            tmr.alarm(3, 31, 0,  function() KontrolaOdeslani() end)
        end
    end
end

--------------------------------------------------------------------------------
tmr.alarm(3, 500, 0,  function() KontrolaOdeslani() end)  -- Na zacatku klidne muzu cekat dele

