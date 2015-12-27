-- send.lua
local x

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

local function Konec()
    local res = x.get_state()
    print(res)
    if res == 4 then
            if Debug_S == 1 then print("s> Done.") end
            -- x = nil
            -- cloud = nil
            -- package.loaded["cloud"]=nil
            -- dofile("wait.lc") 
            -- sem pridat dalsi mereni nebo radio nebo tak...
            print("odeslano")
    else
        tmr.alarm(TM["s"], 100, 0, function() Konec() end)
    end
end

local function Start()
    if Debug_S == 1 then print("s> Sending...") end
    x.send(Rdat)
    tmr.alarm(TM["s"], 100, 0, function() Konec() end)
end    

local function OdesliTed()
    Rdat[Rpref.."x"..Get_AP_MAC()] = 1 
    Rcnt = Rcnt + 1
    Rdat[Rpref.."cnt"] = Rcnt
    Rdat[Rpref.."hp"] = node.heap()    
    Rdat[Rpref.."tx"] = tmr.now()/1000
    Start()
end

local function KontrolaOdeslani()
    if Debug_S == 1 then
        print("s> net="..Completed_Network.." m="..Completed_Measure)
    end
    if (Completed_Network > 0) and (Completed_Measure > 0) then -- mozne odesilat
         tmr.alarm(TM["s"], 100, 0,  function() OdesliTed() end)
         return
    else
        if (Completed_Network < 0) or (Completed_Measure < 0) then -- fatlani problem
            -- reboot ??
            return
        end
    end
    -- Kdyz nic nacasuj dalsi kontrolu    
    if Debug_S == 1 then
        tmr.alarm(TM["s"], 3000, 0,  function() KontrolaOdeslani() end)
    else
        tmr.alarm(TM["s"], 100, 0,  function() KontrolaOdeslani() end)
    end
end

x = require("cloud")
x.setup('77.104.219.2',Rapik,Rnod,'emon.jiffaco.cz',TM["s2"])
KontrolaOdeslani()
