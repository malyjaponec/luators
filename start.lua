local counter = 0

-- LIBRARY - ap selector
local ap_was_found = false
local ap_selected_ssid = ""
local ap_selected_pass = ""
function ap_select(t)
    --print("HEAP ap_select "..node.heap())
    ap_was_found = false

    if nil == t then 
        print ("Scan returned empty list.")
        return
    end

    local ssid = ""
    local cfg_ssid = ""
    local cfg_pass = ""
    local line = ""
    
    for ssid in pairs(t) do
        print ("Searching password for AP "..ssid)
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
                        print ("Known ssid "..ssid..", password "..cfg_pass)
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
    --print("HEAP check_new_ip "..node.heap())

    tmr.stop(0)
    if nil == wifi.sta.getip() then 
        print("Waiting for IP...") 
        counter = counter - 1
        if (counter > 0) then
            tmr.alarm(0, 2000, 0, function() check_new_ip() end)
        else
            print(wifi.sta.status())
            print("PANIC, not IP assigned, end")
            dofile("sleep.lc")
        end
    else 
        print("Config done, IP is "..wifi.sta.getip())
        collectgarbage()
        tmr.alarm(0, 100, 0, function() dofile("measure.lc") end)  
    end
end

local function reset_apn()
    --print("HEAP reset_apn "..node.heap())

    tmr.stop(0)
    print("Scanning APs...")
    --apt = require("aptools") -- pouziva aptools, na konci zase uklidi do nil
    counter = counter - 1
    --wifi.sta.getap(apt.select_ap)
    wifi.sta.getap(ap_select)
    --if apt.found() == true then
    if ap_was_found == true then
        --print("Connecting to "..apt.ssid())
        --print("Connecting to "..ap_selected_ssid)
        --wifi.sta.config(apt.ssid(),apt.pass())
        wifi.sta.config(ap_selected_ssid,ap_selected_pass)
        wifi.sta.connect()
        wifi.sta.autoconnect(1)
        counter = 10
        tmr.alarm(0, 5000, 0, function() check_new_ip() end)
    else 
        print("Waiting between scans...")
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
    --print("HEAP change_apn "..node.heap())
    
    counter = 10
    reset_apn()
end

local function check_ip()
--    print("HEAP check_ip "..node.heap())

    tmr.stop(0)
    if nil ~= wifi.sta.getip() then 
        print("Autoconnected, IP is "..wifi.sta.getip())
        collectgarbage()
        tmr.alarm(0, 200, 0, function() dofile("measure.lc") end)
    else
        print("Connecting...") 
        counter = counter - 1
        if (counter > 0) and (1 == wifi.sta.status()) then
            tmr.alarm(0, 2000, 0, function() check_ip() end)
        else
            print(wifi.sta.status())
            change_apn()
        end
    end
end

-- start.lua
--print("HEAP start.lua "..node.heap())

tmr.stop(1)
tmr.stop(0)
counter = 5
wifi.setmode(wifi.STATION) -- nove moduly jsou prepnute do softap a nerozjede se to, jiz pouzitemu je to jedno
check_ip()
