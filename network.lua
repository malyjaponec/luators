-- bylo by dobre preklopit na kod shodny s telomery, az na ty ledky \
-- ktere maji jinak, takze to zatim nechavam jak to je, byt je to slozitejsi
-- udrzovat prevzal sem tam neco co zkrati cas nalezeni IP (zkouma se to
-- po 100ms misto po 2s... ale asi to neni potreba pro plynomer

local counter
local ap_was_found

local function ap_select(t)
    if nil == t then 
        if Debug == 1 then print ("IP> Scan returned empty list.") end
        ap_was_found = 0
        return
    end

    if file.open("passwd.ini", "r") == nil then
        ap_was_found = 3
        return
    end
        
    local ssid
    local cfg_ssid
    local cfg_pass
    local line
    
    for ssid in pairs(t) do
        if Debug == 1 then print ("IP> Searching password for AP "..ssid) end
        file.seek("set") -- jdu na zacatek souboru hesel
        repeat
            line = file.readline();
            if line ~= nil then
                cfg_ssid, cfg_pass = string.match(line, '([^|]+)|([^|]+)|')           
                if ssid == cfg_ssid then
                    if Debug == 1 then print ("IP> Known ssid "..ssid..", password "..cfg_pass) end
                    ap_was_found = 1
                    file.close()
                    wifi.sta.config(cfg_ssid,cfg_pass)
                    wifi.sta.connect()
                    wifi.sta.autoconnect(1)
                    return
                end
            end
        until line == nil
    end
    file.close()
    ap_was_found = 0
end

local function check_new_ip()
    rgb.set("red")
    if nil == wifi.sta.getip() then 
        if Debug == 1 and counter % 10 == 0 then print("IP> Connecting AP...") end
        counter = counter - 1
        if (counter > 0) then
            tmr.alarm(0, 100, 0, function() check_new_ip() end)
        else
            print(wifi.sta.status())
            print("IP> PANIC, not IP assigned, end")
            Network_Ready = -2
        end
    else 
        print("Reconfig done, IP is "..wifi.sta.getip())
        Rdat[Rpref.."ti"] = tmr.now()/1000
        rgb.set()
        Network_Ready = 1
    end
end

local function reset_apn_result()
    if ap_was_found == 1 then -- nalezeno, konfiguruji
        counter = 200 -- opet cekam 20s na IP
        tmr.alarm(0, 2000, 0, function() check_new_ip() end) -- zacnu cekat na IP
        return
    end
    if ap_was_found == 3 then -- neni soubor, jiz nastavena ch
        print ("IP> PANIC: file passwd.ini missing")
        Network_Ready = -9
        return
    end      
    if ap_was_found == -1 then -- zatim neni dohledano, jen kvuli debugu 
        if Debug == 1 then print("IP> AP search timeout") end
    end      
    -- vse ostatni nejspis 0
    if (counter > 0) then
        if Debug == 1 then print("IP> Scan unsucessful, trying again...") end
        counter = counter - 1
        ap_was_found = -1 -- nastavim si ze nevim jestli neco nebo nic
        if Debug == 1 then print("IP> Scanning APs...") end
        wifi.sta.getap(ap_select) -- spoustim hledani
        tmr.alarm(0, 3000, 0, function() reset_apn_result() end) -- za 3 sekundu spust kontrolu vysledku
    else
        print("IP> PANIC, not wifi coverage, end")
        wifi.setmode(wifi.STATION) -- pro jistotu pred vypnutim rekonfiguruji, nechci to delat jindy, aby to neblokovalo nacitani AP a nebo pripojeni
        Network_Ready = -1
    end
end

local function change_apn()
    rgb.set("orange")
    if Debug == 1 then print("ip> Reselecting AP...") end
    counter = 3 -- skenuji 3x a pak reknu ze neni
    wifi.setmode(wifi.STATION) -- nove moduly jsou prepnute do softap a nerozjede se to, jiz pouzitemu je to jedno    
    counter = counter - 1
    ap_was_found = -1 -- nastavim si ze nevim jestli neco nebo nic
    if Debug == 1 then print("ip> Scanning APs...") end
    wifi.sta.getap(ap_select) -- spoustim hledani
    tmr.alarm(0, 3000, 0, function() reset_apn_result() end) -- za 3 sekundu spust kontrolu vysledku
end

local function check_ip()
    rgb.set("red")
    if nil ~= wifi.sta.getip() then 
        if Debug == 1 then print("ip> IP is "..wifi.sta.getip()) end
        rgb.set()
        Network_Ready = 1
    else
        if Debug == 1 and counter % 10 == 0 then print("IP> Connecting AP...") end
        counter = counter - 1
        if (counter > 0) and (1 == wifi.sta.status()) then
            tmr.alarm(0, 100, 0, function() check_ip() end)
        else
            if Debug == 1 then print("ip> connect failed, status:"..wifi.sta.status()) end
            change_apn()
        end
    end
end

-- start.lua

Network_Ready = 0 -- toto se sice nastavuje vnejsem pri volani ze setupu ale kdyz to budu volat z sendu tak at si to nastavi samo
counter = 200 -- prilizne 20 sekund cekam na pripojeni pak neco zacnu resit
tmr.alarm(0, 1000, 0, function() check_ip() end)
