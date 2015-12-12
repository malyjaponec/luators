local counter = 0

local function SetMAC()
    local ssid,pass,bset,bssid
    ssid, pass, bset, bssid=wifi.sta.getconfig()
    if bssid:len() == 17 then -- delka je presne 17 znaku
        local hex,len = bssid:gsub(":","") -- odmazu :
        if len == 5 then -- odmazano presne 5 dvojtecek
            -- toto je varianta co posila MAC ciselne jako 2 cisla hornich a dolnich 24 bitu zvlast
            -- emon to dost tezko zpracovava, sice to lze spojit a logovat ale ty velka cisla 
            -- mu delaji problem, proto jsem zkusil variantu nize
                --local dec = tonumber(hex:sub(1,6),16) -- prevedu na dekadicke cislo
                --Fields[ReportFieldPrefix.."aph"] = dec -- zaradim k odeslani
                --dec = tonumber(hex:sub(7,12),16) -- prevedu na dekadicke cislo            
                --Fields[ReportFieldPrefix.."apl"] = dec -- zaradim k odeslani
            -- toto je varianta, ktera pouzije MAC jako identifikator predavanych dat
            -- a posila vzdy cislo 1, na zaklade toho se pak da logovat do feedu 
            -- cislo 1 nasobene pro kazdy vstup jinou konstantou a ziskat cislo AP v jednotkach
            -- pred MAC je pro jistotu x, aby se nemohlo stat ze se to splete s jinym vstupem
                Fields[ReportFieldPrefix.."x"..hex] = 1 -- zaradim k odeslani
        end
    end
end

-- LIBRARY - ap selector
local ap_was_found = false
local ap_selected_ssid = ""
local ap_selected_pass = ""
local function ap_select(t)
    ap_was_found = false

    if nil == t then 
        if Debug == 1 then print ("Scan returned empty list.") end
        return
    end

    local ssid = ""
    local cfg_ssid = ""
    local cfg_pass = ""
    local line = ""
    
    for ssid in pairs(t) do
        if Debug == 1 then print ("Searching password for AP "..ssid) end
        file.open("passwd.ini", "r")
        if nil == file.open("passwd.ini", "r") then
            print ("PANIC: file passwd.ini missing")
            dofile("sleep.lc")
            -- fatal, tak se na vse vykaslu a koncim
        else
            repeat
                line = file.readline();
                if line ~= nil then
                    cfg_ssid, cfg_pass = string.match(line, '([^|]+)|([^|]+)|')           
                    --print("DEBUG: ssid"..cfg_ssid..", pass"..cfg_pass)
                    if ssid == cfg_ssid then
                        if Debug == 1 then print ("Known ssid "..ssid..", password "..cfg_pass)
                        else print ("Selected AP:"..ssid) end
                        ap_selected_ssid = cfg_ssid
                        ap_selected_pass = cfg_pass
                        ap_was_found = true
                        break
                    end
                end
            until line == nil
            file.close()
            if ap_was_found == true then
                break
            end
        end
    end

    ssid = nil
    line = nil
    cfg_ssid = nil
    cfg_pass = nil
    line = nil
end
-- LIBRARY end

local function check_new_ip()
    tmr.stop(0)
    if nil == wifi.sta.getip() then 
        if Debug == 1 then print("Waiting for IP...") end
        counter = counter - 1
        if (counter > 0) then
            tmr.alarm(0, 500, 0, function() check_new_ip() end)
        else
            print(wifi.sta.status())
            print("PANIC, not IP assigned, end")
            dofile("sleep.lc")
        end
    else 
        print("Reconfig done, IP is "..wifi.sta.getip())
        SetMAC()
        collectgarbage()
        tmr.alarm(0, 10, 0, function() dofile("measure.lc") end)  
    end
end

local function reset_apn()
    tmr.stop(0)
    if Debug == 1 then print("Scanning APs...") end
    counter = counter - 1
    wifi.sta.getap(ap_select)
    if ap_was_found == true then
        wifi.sta.config(ap_selected_ssid,ap_selected_pass)
        wifi.sta.connect()
        wifi.sta.autoconnect(1)
        counter = 10
        tmr.alarm(0, 5000, 0, function() check_new_ip() end)
    else 
        if Debug == 1 then print("Waiting between scans...") end
        if (counter > 0) then
            tmr.alarm(0, 3000, 0, function() reset_apn() end)   
            -- musi cekat 3 sekundy jinak to nikdy neprojde a vzdycky to neprochazi na poprve 
        else
            print("PANIC, not wifi coverage, end")
            wifi.setmode(wifi.STATION) -- pro jistotu pred vypnutim rekonfiguruji, nechci to delat jindy, aby to neblokovalo nacitani AP a nebo pripojeni
            dofile("sleep.lc")
        end 
    end
    --apt = nil
end

local function change_apn()
    if Debug == 1 then print("Reselecting AP...") end
    counter = 10
    wifi.setmode(wifi.STATION) -- nove moduly jsou prepnute do softap a nerozjede se to, jiz pouzitemu je to jedno    
    reset_apn()
end

local function check_ip()
    tmr.stop(0)
    if nil ~= wifi.sta.getip() then 
        print("IP is "..wifi.sta.getip())
        SetMAC();
        collectgarbage()
        tmr.alarm(0, 10, 0, function() dofile("measure.lc") end)
    else
        if Debug == 1 then print("Connecting AP...") end
        counter = counter - 1
        if (counter > 0) and (1 == wifi.sta.status()) then
            tmr.alarm(0, 500, 0, function() check_ip() end) 
            -- zkousel jsem mensi cas a vysledkem je ze kdyz nema IP hned nedostane ji
            -- a dojde k reselekci AP, takze 2s tu byt bohuzel musi i za cenu ze kdyz
            -- nema IP hned, ze minimalni zdrzeni jsou 2s
        else
            if Debug == 1 then print(wifi.sta.status()) end
            change_apn()
        end
    end
end

-- start.lua

tmr.stop(1)
tmr.stop(0)
counter = 20 -- 5 bylo pozuito pro 2s cekani na IP, pro 500ms cekani by to chtelo 20
check_ip()
