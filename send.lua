-- send.lua
local Web
local KonecCounter
local Fail_Send
local Fail_Wifi

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
    local state,result = Web.get_state() -- vyctu si stav cloud knihovny

    -- Zajisteni 30s timeoutu i kdyz knihovna ma vlastni 20s timeout jenze nevime co se stane pri vypadku wifi pri prenosu
    KonecCounter = KonecCounter + 1
    if KonecCounter > 300 then -- pri kontrole 100ms tedy 10x za sekundu je 30sekund asi 300
        Web.abort() -- volam abort cloudoveho prenosu at udelal co udelal
        state = 4 -- fejkuju stav 4 - konec prenosu
        result = 0 -- stejne tak nastavuji vysledek na nepreneseno a o zbytek se postaraji standardni mechanizmy
    end

    -- Kontrola stavu cloud knihovny
    if (state == 4) then -- ukonceno spojeni
        if result == 1 then -- predana data
            if Debug == 1 then print("s>odeslano") end
            Send_Failed = 0 -- nuluji indikaci chyby
            Fail_Send = 0 -- nuluji cinac chyb pri penosu, povedlo se prenest
            rgb.set()
        else -- data nepredana
            if Debug == 1 then print("s>chyba,nepredano") end
            Send_Failed = 1 -- chyba, data se musi zopakovat
            Fail_Send = Fail_Send + 1 -- zvysuji citac chyb prenosu
            rgb.set("magenta")
        end
        Send_Busy = 0 -- Vymazu blokaci z jineho duvodu, doslo k odeslani, wifi musi fungovat
        Send_Request = 0 -- Vymazu pozadavek, cimz dam measure echo, ze muze poslat dalsi
        tmr.alarm(2, 100, 0, function() KontrolaOdeslani() end) -- A cekam na na dalsi pozadavek odeslani dat
    else -- nez skonci cekani cekam
        tmr.alarm(2, 100, 0, function() Konec() end) -- Cekam na stav 4
    end
end

local function Start()
    rgb.set("green")

    -- pridam si nektera technologicka data, ktera predavam na cloud
    Rcnt = Rcnt + 1
    Rdat[Rpref.."cnt"] = Rcnt
    Rdat[Rpref.."x"..Get_AP_MAC()] = 1 
    Rdat[Rpref.."fc"] = Fail_Send   
    Rdat[Rpref.."hp"] = node.heap() 

    Web.send(Rdat) -- dam pozadavek prenosu dat na cloud

    Rdat = nil
    Rdat = {} -- Vynuluju data, nikdo jiny to nedela

    KonecCounter = 0 -- citac pro timeout 
    tmr.alarm(2, 100, 0, function() Konec() end) -- nacasuji kontrolu jestli se to povedlo
end

local function ReinicializujSit()
    rgb.set("cyan")
    Send_Busy = 1 -- nesmi chodit pozadavky od mericiho systemu, ten si bude dal akumulovat spotrebu
    tmr.alarm(0, 100, 0, function() dofile("network.lc") end) -- reinicalizace site, to bud sit opravi
    -- nebo to vrati network ready zaporne cislo a dojde k citani chyb wifi
end

function KontrolaOdeslani()

    if Network_Ready > 0 then -- mozne odesilat, sit dostupna
        
        if (wifi.sta.status() ~= 5) or 
           (wifi.sta.getip() == nil) 
          then -- indikuje to ze wifi neni v poradku
            ReinicializujSit()
        else
            Send_Busy = 0 -- indikuji ze je mozne vydavat pozadavky (wifi nevykazuje prolbem)
            if Send_Request == 1 then -- kontrola zda merici system zada odeslani dat na cloud
                tmr.alarm(2, 100, 0,  function() Start() end) -- Spoustim predani dat na cloud
                return -- a vyskakuji z teto funkce aby se nedelo nic dalsiho
            end
        end

    end

    if Network_Ready < 0 then -- chyba v pristupu k siti, nepovedlo se najit AP nebo nedostal IP
		Fail_Wifi = Fail_Wifi + 1
		if Fail_Wifi > 100 then -- fakt uz to trva dlouho
			tmr.alarm(2, 100, 0,  function() dofile("reset.lc") end) -- volam restart, ztratim vsechno zmerene
			return
		else
			ReinicializujSit()
		end
    end

    if Fail_Send > 20 then -- uz se po sobe X krat nepodarilo predat
        ReinicializujSit()
    end        

    -- Nacasovat dalsi kontrolu pokud jsem nenacasoval neco jineho
    tmr.alarm(2, 250, 0,  function() KontrolaOdeslani() end)
end

Fail_Send = 0 -- toto pocita kontinualni chyby prenosu a po 20 radeji zarizeni restartuje
Fail_Wifi = 0 -- pocita pocet pokusu kdy nenajde AP
Web = require("cloud")
Web.setup('77.104.219.2',Rapik,Rnod,'emon.jiffaco.cz',3)
tmr.alarm(2, 250, 0,  function() KontrolaOdeslani() end)
