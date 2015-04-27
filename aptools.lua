-- aptools.lua
local M = {}
local ap_was_found = 0

function M.select_ap(t)
    ap_was_found = 0
    if (t == nil) then
        return
    end
    print ("Hledam heslo pro nalezene AP...")
    for ssid,v in pairs(t) do
        authmode, rssi, bssid, channel = string.match(v, "(%d),(-?%d+),(%x%x:%x%x:%x%x:%x%x:%x%x:%x%x),(%d+)")
        --print(ssid,authmode,rssi,bssid,channel)
        print ("Kontrola AP:"..ssid)
        file.open("passwd.ini", "r")
        result = file.open("passwd.ini", "r")
        if result == nil then -- soubor neexistuje
            print ("E: nemam seznam hesel")
        else
            repeat
                line = file.readline();
                if line ~= nil then
                    cfg_ssid, cfg_pass = string.match(line, '(%w+) (%w+)')           
                    if ssid == cfg_ssid then
                        ap_was_found = 1
                        break
                    end
                end
            until line == nil
            file.close()
        end
        if (ap_was_found == 1) then
            print ("Heslo nalezeno, pripojuji se heslem:"..cfg_pass)
            wifi.sta.config(cfg_ssid,cfg_pass)
            break
        else
            print ("... neznamy AP")
        end
    end
end

function M.found()
  return ap_was_found
end

return M
