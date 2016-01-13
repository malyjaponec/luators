-- send.lua
local x
local KonecCounter
local FailCounter
local CoverageFailCounter

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
    local state,result = x.get_state() -- vyctu si stav cloud knihovny

    -- Zajisteni 30s timeoutu i kdyz knihovna ma vlastni 20s timeout jenze nevime co se stane pri vypadku wifi pri prenosu
    KonecCounter = KonecCounter + 1
    if KonecCounter > 300 then -- pri kontrole 100ms tedy 10x za sekundu je 30sekund asi 300
        x.abort() -- volam abort cloudoveho prenosu at udelal co udelal
        state = 4 -- fejkuju stav 4 - konec prenosu
        result = 0 -- stejne tak nastavuji vysledek na nepreneseno a o zbytek se postaraji standardni mechanizmy
    end

    -- Kontrola stavu cloud knihovny
    if (state == 4) then -- ukonceno spojeni
        if result == 1 then -- predana data
            if Debug == 1 then print("s>odeslano") end
            FailCounter = 0 -- nuluji cinac chyb pri penosu, povedlo se prenest
            rgb.set()
        else -- data nepredana
            if Debug == 1 then print("s>chyba,nepredano") end
            Send_Failed = 1 -- chyba, data se musi zopakovat
            FailCounter = FailCounter + 1 -- zvysuji citac chyb prenosu
            rgb.set("magenta")
        end
        Rdat = nil
        Rdat = {} -- Vynuluju data, nikdo jiny to nedela
        Send_Request = 0 -- Vymazu pozadavek
        Send_Busy = 0 -- Vymazu blokaci z jineho duvodu
        tmr.alarm(2, 500, 0, function() KontrolaOdeslani() end) -- A cekam na na dalsi pozadavek odeslani dat
    else -- nez skonci cekani cekam
        tmr.alarm(2, 500, 0, function() Konec() end) -- Cekam na stav 4
    end
end

local function Start()
    rgb.set("green")
    -- pridam si nektera technologicka data, ktera predavam na cloud
    Rcnt = Rcnt + 1
    Rdat[Rpref.."cnt"] = Rcnt
    Rdat[Rpref.."x"..Get_AP_MAC()] = 1 
    Rdat[Rpref.."fc"] = FailCounter   
    Rdat[Rpref.."hp"] = node.heap() 

    x.send(Rdat) -- dam pozadavek prenosu dat na cloud

    KonecCounter = 0 -- citac pro timeout 
    tmr.alarm(2, 1000, 0, function() Konec() end) -- nacasuji kontrolu jestli se to povedlo
end

function KontrolaOdeslani()

    if Network_Ready > 0 then -- mozne odesilat, sit dostupna, neni jinak reseno to ze se wifi ztrati
        
        if wifi.sta.status() ~= 5 then -- indikuje to ze wifi neni v poradku
            rgb.set("cyan")
            Send_Busy = 1
            tmr.alarm(0, 100, 0, function() dofile("network.lc") end) -- reinicalizace site
        else
            Send_Busy = 0 -- indikuji ze je mozne vydavat pozadavky (wifi je pripojena)
            if Send_Request == 1 then -- merici system zada odeslani dat na cloud
                tmr.alarm(2, 100, 0,  function() Start() end) -- Jdu na to
                return
            end
        end

    end

    if Network_Ready < 0 then -- chyba v pristupu k siti, reset barvu si reset zaridi sam
		CoverageFailCounter = CoverageFailCounter + 1
		if FailCounter > 5 then -- reset v pripade X nenalezeneho AP
			tmr.alarm(2, 100, 0,  function() dofile("reset.lc") end)
			return
		else
			rgb.set("cyan")
			Send_Busy = 1
			tmr.alarm(0, 100, 0, function() dofile("network.lc") end) -- reinicalizace site
		end
    end

--    if FailCounter > 20 then -- reset v pripade X chyb prenosu
--        tmr.alarm(2, 100, 0,  function() dofile("reset.lc") end)
--        return
--    end        
-- nevim zda je lepsi udelat reset a ztratit informaci o spotrebe a nebo pocitat s tim ze bez resetu
-- se to z problemu vykope samo, asi to druhe, stejne pri vypadku wifi signalu to zacne restartovat
-- je otazka zda to neni spatne, mozna by se nemel reset takoveho zarizeni delat nikdy protoze nedostupnost
-- wifi muze byt jen otazka docasna a treba za pul hodiny se opravi a system by jinak dokazal naakumulovana
-- data poslat i po takove dobe

    -- Nacasovat dalsi kontrolu pokud jsem nenacasoval neco jineho
    tmr.alarm(2, 250, 0,  function() KontrolaOdeslani() end)
end

FailCounter = 0 -- toto pocita kontinualni chyby prenosu a po 20 radeji zarizeni restartuje
CoverageFailCounter = 0 -- pocita pocet pokusu kdy nenajde AP
x = require("cloud")
x.setup('77.104.219.2',Rapik,Rnod,'emon.jiffaco.cz',3)
tmr.alarm(2, 250, 0,  function() KontrolaOdeslani() end)

