ip_get_counter = 0
ap_get_counter = 0
found_known_ap = 0
found_new_ap = 0

local cfg_ssid = ""
local cfg_pass = ""

local function init_select_ap(t)
    found_new_ap = 0
    if nil == t then 
        print ("Warning: nil AP list")
        return
    end

    local ssid = ""
    local line = ""
    
    for ssid in pairs(t) do
        if nil == file.open("passwd.ini", "r") then
            print ("ERROR: no password file")
            return; -- fatal, tak se na vse vykaslu a koncim
        else
            repeat
                line = file.readline();
                if line ~= nil then
                    cfg_ssid, cfg_pass = string.match(line, '(%w+) (%w+)')           
                    if ssid == cfg_ssid then
                        print ("connecting: "..cfg_ssid.."/"..cfg_pass)
                        wifi.sta.config(cfg_ssid,cfg_pass)
                        wifi.sta.connect()
                        found_new_ap = 1
                        break
                    end
                end
            until line == nil
            file.close()
        end
    end

    ssid = nil
    line = nil
    line = nil
end

local function init_store_ap()
    local rewrite_file = 0
    if nil ~= file.open("last_ap.ini", "r") then
        line = file.readline();
        if line ~= nil then
            local stored_ssid,stored_pass
            file.close()
            stored_ssid, stored_pass = string.match(line, '(%w+) (%w+)')
            if ((stored_ssid ~= cfg_ssid) or (stored_pass ~= cfg_pass)) then
                rewrite_file = 1
            end
            stored_ssid = nil
            stored_pass = nil
        end
        line = nil
    else 
        rewrite_file =1
    end

    if 1 == rewrite_file then            
        print ("new last ap")
        if nil ~= file.open("last_ap.ini","w") then
            file.writeline(cfg_ssid.." "..cfg_pass)
            file.close()
        end
    end
    rewrite_file = nil
end

local function init_get_ip()
    if nil == wifi.sta.getip() then 
        print("ip unavaiable, waiting...") 
        ip_get_counter = ip_get_counter + 1
        if ip_get_counter > 15 then -- uz to trva 15s a nemame IP
            if 1 == found_known_ap then -- spojeni na zaklade zapamataovnaeho ap
                print ("last ap removed")
                file.remove("last_ap.ini")
            end
            dofile("sleep.lc")
        else -- jeste nacasujem dalsi pokus
            tmr.alarm(0, 2000, 0, function() init_get_ip() end)
        end
    else 
        print("got ip "..wifi.sta.getip())
        --init_store_ap()
        print("clound begin...")
        tmr.alarm(0, 100, 0, function() dofile("send2cloud.lua") end)
    end
end

local function init_search_ap()
    print("searching ap ...")
    wifi.sta.getap(init_select_ap)
    if 0 == found_new_ap then -- nebylo nalezeno
        ap_get_counter = ap_get_counter + 1
        if 10 > ap_get_counter then
            print("sleeping before next scan")
            tmr.alarm(0, 3000, 0, function() init_search_ap() end)   
            -- musi cekat 3 sekundy jinak to nikdy neprojde a vzdycky to neprochazi na poprve 
        else
            dofile("sleep.lc")    
        end
    else
        wifi.sta.connect()
        ip_get_counter = 0
        tmr.alarm(0, 1000, 0, function() init_get_ip() end)
    end
end

local function init_last_known_ap()
    found_known_ap = 0
    if nil ~= file.open("last_ap.ini", "r") then
        line = file.readline();
        if line ~= nil then
            cfg_ssid, cfg_pass = string.match(line, '(%w+) (%w+)')           
            found_known_ap = 1
            print ("reconnecting: "..cfg_ssid.."/"..cfg_pass)
            wifi.sta.config(cfg_ssid,cfg_pass)
            wifi.sta.connect()
            line = nil
       end
        file.close()
    end
end

-- start.lua
wifi.setmode(wifi.STATION)
--init_last_known_ap()
if 1 == found_known_ap then -- predchozi AP nalezeno, spojuje se
    ip_get_counter = 0
    tmr.alarm(0, 1000, 0, function() init_get_ip() end)
else -- predchozi AP neni, budem hledat
    ap_get_counter = 0
    init_search_ap()
end
    
