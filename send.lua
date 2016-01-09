-- send.lua
local x
local Timeout

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
    local state,result = x.get_state()
    if (state == 4) then -- ukonceno spojeni
        if result == 1 then -- predana data
            if Debug_S == 1 then print("s>odeslano") end
            rgb.set()
        else -- data nepredana
            Send_Failed = 1
            rgb.set("magenta")
        end
        Rdat = {} -- Vynuluju data, nikdo jiny to nedela
        Send_Request = 0 -- Vymazu pozadavek
        Send_Busy = 0 -- Vymazu blokaci z jineho duvodu
        tmr.alarm(TM["s"], 100, 0, function() KontrolaOdeslani() end) -- A cekam na na dalsi mereni
    else -- nez skonci cekani cekam, knihovna ma 20s timeout a mela by vzdycky dojit do stavu 4
        tmr.alarm(TM["s"], 100, 0, function() Konec() end)
    end
end

local function Start()
    rgb.set("green")
    -- pridam si nektera technologicka data, ktera predavam na cloud
    Rdat[Rpref.."x"..Get_AP_MAC()] = 1 
    Rcnt = Rcnt + 1
    Rdat[Rpref.."cnt"] = Rcnt
    Rdat[Rpref.."hp"] = node.heap()    

    x.send(Rdat) -- dam pozadavek prenosu dat na cloud
    
    tmr.alarm(TM["s"], 100, 0, function() Konec() end) -- nacasuji kontrolu jestli se to povedlo
end

function KontrolaOdeslani()

    if Network_Ready > 0 then -- mozne odesilat, sit dostupna, neni jinak reseno to ze se wifi ztrati
        
        if wifi.sta.status() ~= 5 then -- indikuje to ze wifi neni v poradku
            rgb.set("cyan")
            Send_Busy = 1
            tmr.alarm(TM["ip"], 1000, 0, function() dofile("network.lc") end) -- reinicalizace site, zkousim poprve nikdy jsem to neresil, vzdy to vedlo k resetu
        else
            Send_Busy = 0 -- indikuji ze je mozne vydavat pozadavky (wifi je pripojena)
            if Send_Request == 1 then -- merici system zada odeslani dat na cloud
                tmr.alarm(TM["s"], 100, 0,  function() Start() end) -- Jdu na to
                return
            end
        end

    end

    if Network_Ready < 0 then -- chyba v pristupu k siti, reset barvu si reset zaridi sam
        tmr.alarm(TM["s"], 100, 0,  function() dofile("reset.lc") end)
        return
    end

    -- Nacasovat dalsi kontrolu pokud jsem nenacasoval neco jineho
    tmr.alarm(TM["s"], 250, 0,  function() KontrolaOdeslani() end)
end

x = require("cloud")
x.setup('77.104.219.2',Rapik,Rnod,'emon.jiffaco.cz',TM["s2"])
tmr.alarm(TM["s"], 250, 0,  function() KontrolaOdeslani() end)

