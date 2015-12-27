local counter = 0

-- promenne vystupujici z call back funkce hledani AP, jinak nez pres lokalne globalni promenne to z funkce,
-- kterou vola rutina vyhledani AP nedostanu
local ap_was_found = false
local ap_selected_ssid = ""
local ap_selected_pass = ""

local function ap_select(t)
    ap_was_found = false

    if nil == t then 
        if Debug_IP == 1 then print ("ip> Scan returned empty list.") end
        return
    end

    local ssid = ""
    local cfg_ssid = ""
    local cfg_pass = ""
    local line = ""
    
    for ssid in pairs(t) do
        if Debug_IP == 1 then print ("ip> Searching password for AP "..ssid) end
        file.open("passwd.ini", "r")  -- tohle presunout pred for, takhle to xkrat otvira soubor
        if nil == file.open("passwd.ini", "r") then
            print ("ip> PANIC: file passwd.ini missing")
            Completed_Network = -1
            break
        else
            repeat
                line = file.readline();
                if line ~= nil then
                    cfg_ssid, cfg_pass = string.match(line, '([^|]+)|([^|]+)|')           
                    if ssid == cfg_ssid then
                        if Debug_IP == 1 then print ("ip> Known ssid "..ssid..", password "..cfg_pass) end
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
    if nil == wifi.sta.getip() then 
        if Debug_IP == 1 then print("ip> Waiting for IP...") end
        counter = counter - 1
        if (counter > 0) then
            tmr.alarm(TM["ip"], 500, 0, function() check_new_ip() end)
        else
            print(wifi.sta.status())
            print("ip> PANIC, not IP assigned, end")
            Completed_Network = -1
        end
    else 
        print("Reconfig done, IP is "..wifi.sta.getip())
        Rdat[Rpref.."ti"] = tmr.now()/1000
        Completed_Network = 1
    end
end

local function reset_apn()
    if Debug_IP == 1 then print("ip> Scanning APs...") end
    counter = counter - 1
    wifi.sta.getap(ap_select)
    if ap_was_found == true then
        wifi.sta.config(ap_selected_ssid,ap_selected_pass)
        wifi.sta.connect()
        wifi.sta.autoconnect(1)
        counter = 10
        tmr.alarm(TM["ip"], 5000, 0, function() check_new_ip() end)
    else 
        if Debug_IP == 1 then print("ip> Waiting between scans...") end
        if (counter > 0) then
            tmr.alarm(TM["ip"], 3000, 0, function() reset_apn() end)   
            -- musi cekat 3 sekundy jinak to nikdy neprojde a ne vzdycky to prochazi na poprve 
        else
            print("ip> PANIC, not wifi coverage, end")
            wifi.setmode(wifi.STATION) -- pro jistotu pred vypnutim rekonfiguruji, nechci to delat jindy, aby to neblokovalo nacitani AP a nebo pripojeni
            Copmpleted_Network = -1
        end 
    end
end

local function change_apn()
    if Debug_IP == 1 then print("ip> Reselecting AP...") end
    counter = 10
    wifi.setmode(wifi.STATION) -- nove moduly jsou prepnute do softap a nerozjede se to, jiz pouzitemu je to jedno    
    reset_apn()
end

local function check_ip()
    if nil ~= wifi.sta.getip() then 
        if Debug_IP == 1 then print("ip> IP is "..wifi.sta.getip()) end
        Rdat[Rpref.."ti"] = tmr.now()/1000
        Completed_Network = 1
    else
        if Debug_IP == 1 then print("ip> Connecting AP...") end
        counter = counter - 1
        if (counter > 0) and (1 == wifi.sta.status()) then
            tmr.alarm(TM["ip"], 500, 0, function() check_ip() end) -- Mensi cas taky funguje
        else
            if Debug_IP == 1 then print("ip> status:"..wifi.sta.status()) end
            change_apn()
        end
    end
end

-- start.lua

counter = 20 -- 5 bylo pozuito pro 2s cekani na IP, pro 500ms cekani by to chtelo 20
check_ip()
