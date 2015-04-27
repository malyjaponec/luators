function select_ap(t)
    nalezeno = 0
    if (t == nil) then
        print ("Nepredan seznam AP")
        return
    end
    print ("Hledam heslo pro nalezene AP...")
    for ssid,v in pairs(t) do
        authmode, rssi, bssid, channel = string.match(v, "(%d),(-?%d+),(%x%x:%x%x:%x%x:%x%x:%x%x:%x%x),(%d+)")
        --print(ssid,authmode,rssi,bssid,channel)
        print ("Kontrola AP:"..ssid)
        result = file.open("passwd.ini", "r")
        if result == nil then -- soubor neexistuje
            print ("E: nemam seznam hesel")
        else
            repeat
                line = file.readline();
                if line ~= nil then
                    cfg_ssid, cfg_pass = string.match(line, '(%w+) (%w+)')           
                    if ssid == cfg_ssid then
                        nalezeno = 1
                        break
                    end
                end
            until line == nil
            file.close()
        end
        if (nalezeno == 1) then
            print ("Heslo nalezeno!")
            break
        else
            print ("... neznamy AP")
        end
    end
end

wifi.sta.getap(select_ap)
