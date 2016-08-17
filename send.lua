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
     -- indikacni led zhasnu
     if LedSend ~= nil then 
        gpio.mode(LedSend, gpio.INPUT) 
        gpio.write(LedSend, gpio.HIGH)
     end

    if (code == nil) then
        code = -100
    end

    if (code > 0) then
        if Debug == 1 then print("s>odeslano/" .. code) end
    else
        if Debug == 1 then print("s>chyba/".. code) end
    end
    code = nil
    data = nil
    if PeriodicReport ~= nil then -- je pozadovano reportovat pravodelne
        dofile("reload.lc")
    else
        dofile("sleep.lua")
    end
end

--------------------------------------------------------------------------------
local function KontrolaOdeslani()

    if  network.status() <= 0 or
        (dht22 ~= nil and dht22.status() == 0) or
        (dalas ~= nil and dalas.status() == 0) or
        (baro ~= nil and baro.status() == 0) or
        (dist ~= nil and dist.status() == 0)
        then -- stale cekame na odeslani

        if network.status() == -1 then
            if PeriodicReport ~= nil then -- je pozadovano reportovat pravidelne
                dofile("restart.lua")
            else
                dofile("sleep.lua")
            end
        else
            tmr.alarm(0, 31, 0,  function() KontrolaOdeslani() end)
        end
        return
    end

    if Debug == 1 then
        print("s>sending..."..node.heap())
    end
    
    -- rozsvitim indikacni led 
    if LedSend ~= nil then
        gpio.mode(LedSend, gpio.OUTPUT) 
        gpio.write(LedSend, gpio.LOW)
    end
    
    -- prekopiruju senzorova data
    local tm,t,k,v = 0
    local Rdat = {}
    Rdat[ReportFieldPrefix.."hp1"] = node.heap() 

    if dht22 ~= nil then
        t =  dht22.status()/1000000
        Rdat[ReportFieldPrefix.."t_dht"] = t
        if t > tm then tm = t end
        for k,v in pairs(dht22.getvalues()) do Rdat[ReportFieldPrefix..k] = v end
        dht22 = nil
        package.loaded["dht22"] = nil
    end
    
    if dalas ~= nil then
        t =  dalas.status()/1000000
        Rdat[ReportFieldPrefix.."t_d"] = t
        if t > tm then tm = t end
        for k,v in pairs(dalas.getvalues()) do Rdat[ReportFieldPrefix..k] = v end
        dalas = nil
        package.loaded["dalas"] = nil
    end

    if baro ~= nil then
        t =  baro.status()/1000000
        Rdat[ReportFieldPrefix.."t_b"] = t
        if t > tm then tm = t end
        for k,v in pairs(baro.getvalues()) do Rdat[ReportFieldPrefix..k] = v end
        baro = nil
        package.loaded["baro"] = nil
    end
    
    if dist ~= nil then
        t =  dist.status()/1000000
        Rdat[ReportFieldPrefix.."t_l"] = t
        if t > tm then tm = t end
        for k,v in pairs(dist.getvalues()) do Rdat[ReportFieldPrefix..k] = v end
        dist = nil
        package.loaded["distance"] = nil
    end
               
    Rdat[ReportFieldPrefix.."tm"] = tm
    t,tm,k,v = nil,nil,nil,nil
    
    -- bateriova data (analogovy prevodnik)
    if battery ~= nil then
        local min,max,cnt = battery.getvalues()
        Rdat[ReportFieldPrefix.."bmin"] = min
        Rdat[ReportFieldPrefix.."bmax"] = max
        Rdat[ReportFieldPrefix.."bcnt"] = cnt
        min,max,cnt = nil
        -- svetlo (sdileny analogovy prevodnik s baterii)
        local lightlevel = battery.getlight()
        if lightlevel > -1 then -- mereni je povolene/nakonfigurovane
            Rdat[ReportFieldPrefix.."light"] = lightlevel
        end;
        lightlevel = nil
        battery = nil
        package.loaded["battery"]=nil
    end
    
    -- sitova data
    Rdat[ReportFieldPrefix.."ti"] = network.status()/1000000
    network = nil
    package.loaded["network"]=nil

    -- postprocessing, na miru jednotlivym systemum a pritom ostatni to nenarusi, dane adresou dalasu
    PostProcessing(Rdat)
    
    -- doplnkova data
    Rdat[ReportFieldPrefix.."cnt"] = Rcnt
    Rdat[ReportFieldPrefix.."x"..Get_AP_MAC()] = 1
    -- cas odeslani, slozity to vypocet :)
        local time = (tmr.now() - (TimeStartLast*1000 or 0))
        if time <= 0 then time = 1 end
        Rdat[ReportFieldPrefix.."ts"] = time / 1000000
        time = nil
    Rdat[ReportFieldPrefix.."hp2"] = node.heap() 
    
    -- prevedu na URL
    local url = "http://emon.jiffaco.cz/emoncms/input/post.json?node=" .. ReportNode .. 
                "&json=" .. cjson.encode(Rdat) .. 
                "&apikey=" .. ReportApiKey
    Rdat = nil -- data smazu explicitne
    http.get(url, nil, function(code,data) Konec(code,data) end )
    url = nil -- url uz taky mazu
    -- nacasuji kontrolu pokud nezavola callback a zasekne se to, tak se to bud uspi nebo restartuje   
    if PeriodicReport ~= nil then
        tmr.alarm(0, 15000, 0, function() dofile("restart.lua") end) 
    else
        tmr.alarm(0, 15000, 0, function() dofile("sleep.lua") end) 
    end
end

--------------------------------------------------------------------------------
tmr.alarm(0, 500, 0,  function() KontrolaOdeslani() end)  -- Na zacatku klidne muzu cekat dele

