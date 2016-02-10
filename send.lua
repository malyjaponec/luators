-- send.lua
local Web
local KonecCounter = 0
local Fail_Send = 0
local Fail_Wifi = 0
local SendTime = 0
local SentEnergy_Faze = {0,0,0}

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
    if KonecCounter > 150 then -- pri kontrole 100ms tedy 10x za sekundu je 15sekund asi 150
        Web.abort() -- volam abort cloudoveho prenosu at udelal co udelal
        state = 4 -- fejkuju stav 4 - konec prenosu
        result = 0 -- stejne tak nastavuji vysledek na nepreneseno a o zbytek se postaraji standardni mechanizmy
    end

    -- Kontrola stavu cloud knihovny
    if state == 4 then -- ukonceno spojeni
        if result == 1 then -- predana data
            if Debug == 1 then print("s>odeslano") end
            Fail_Send = 0 -- nuluji cinac chyb pri penosu, povedlo se prenest
            rtcmem.write32(0, 0,0,0,0) -- nuluji zalozni hodnoty v RTC memory vcetne kontrolniho souctu
            rgb.set()
        else -- data nepredana
            if Debug == 1 then print("s>chyba,nepredano") end
            Fail_Send = Fail_Send + 1 -- zvysuji citac chyb prenosu
            rgb.set("magenta")
        end
        SendTime = tmr.now() -- po odeslani si zapisu cas, takze dalsi prenos zacne za urcenou dobu, pocita se od konce prenosu        
        tmr.alarm(2, 2500, 0, function() KontrolaOdeslani2() end) -- vim ze urcite Xs nechci nic posilat, prvni kontrolu (kvuli siti udelam za 2,5s)
        --collectgarbage()
    else -- nez skonci cekani cekam
        if (state > 0) then -- doslo k sestaveni TCP, domlouvaji se servery
            rgb.set("green")
            tmr.alarm(2, 250, 0, function() Konec() end) -- Cekam na odeslani pomalu, uz svtim zelene
        else
            tmr.alarm(2, 100, 0, function() Konec() end) -- Cekam na odeslani ale rychle abych vcas prepnul do zelena, jiank by se zelena vubec nemusela objevit
        end
    end
end

local function Start()
    rgb.set("blue")

    -- vytvorim zakladni data, ktera chci prenest na cloud
    local Rdat = {}
    local i,energy
    local suma = 0
    for i=1,3 do 
    
        -- pocatek kriticke sekce
            -- prepise si hodnoty energie k odeslani a v merici smaze na 0
            energy,Energy_Faze[i] = Energy_Faze[i],0
        -- konec kriticke sekce
        
        -- sam si akumuluji hodnoty k odeslani ziskane z merice a mazu je jen po uspesnem predani
        SentEnergy_Faze[i] = rtcmem.read32(i,1) -- vyctu si hodnotu z RTC memory 
        SentEnergy_Faze[i] = SentEnergy_Faze[i] + energy -- prictu aktualni citace za posledni periodu
        rtcmem.write32(i, SentEnergy_Faze[i])-- zapisu si hodnoty do RTC memory
        suma = suma + SentEnergy_Faze[i] -- scitam si kontrolni soucet
        Rdat[Rpref.."e"..i] = SentEnergy_Faze[i] -- hodnotu pridam do odesilanych dat
    end
    rtcmem.write32(0, suma)-- zapisu si hodnotu kontrolniho souctu do RTC pameti
    for i=1,3 do 
        -- zpracovani vykonu k odeslani
        if Power_Faze[i] >= 0 then -- zaporne hodnoty nepredavam zamerne
            Rdat[Rpref.."p"..i] = Power_Faze[i] -- hodnotu pridam do odesilanych dat
        end
	end    
    -- pridam si nektera technologicka data, ktera predavam na cloud
    Rcnt = Rcnt + 1
    Rdat[Rpref.."cnt"] = Rcnt
    Rdat[Rpref.."an"] = adc.read(0) -- mereni svetla nebo neceho takoveho
    -- nektere moduly me davaji 65k takze tohle se musi kdyz tak odkomentovat
    Rdat[Rpref.."x"..Get_AP_MAC()] = 1
    Rdat[Rpref.."fc"] = Fail_Send   
    Rdat[Rpref.."et"] = tmr.now()/1000000
    Rdat[Rpref.."hp"] = node.heap() 

    Web.send(Rdat) -- dam pozadavek prenosu dat na cloud

    KonecCounter = 0 -- citac pro timeout 
    tmr.alarm(2, 100, 0, function() Konec() end) -- nacasuji kontrolu jestli se to povedlo
end

local function ReinicializujSit()
    rgb.set("cyan")
    Send_Busy = 1 -- nesmi chodit pozadavky od mericiho systemu, ten si bude dal akumulovat spotrebu
    wifi.sta.disconnect()    
    wifi.sta.connect()
    wifi.sta.autoconnect(1)
    tmr.alarm(0, 100, 0, function() dofile("network.lc") end) -- reinicalizace site, to bud sit opravi
    -- nebo to vrati network ready zaporne cislo a dojde k citani chyb wifi
end

local function KontrolaOdeslani()

    if Network_Ready > 0 then -- mozne odesilat, sit dostupna

        -- napred probiha kontrola zda nedoslo k problemum na wifi
        local status = wifi.sta.status()
        if (status == 0) or 
           (status == 2) or 
           (status == 3) or 
           (status == 4) or 
           (wifi.sta.getip() == nil) 
          then -- indikuje to ze wifi neni v poradku
            ReinicializujSit() -- volam externi reinicializacni skript
        else
            -- Kontrola zda uz neni cas poslat na cloud aktualizaci
            local timedif = tmr.now() - SendTime
            if (timedif > 4500000) or (timedif < -4500000) then -- zdanllivy nesmysl, ktery pokryje pretoceni casovace do nekonecneho zaporu
                 if Debug == 1 then print("s>odesilam,cas:"..timedif/1000000) end
                tmr.alarm(2, 100, 0,  function() Start() end) -- Spoustim predani dat na cloud
                return -- a vyskakuji z teto funkce aby se nedelo nic dalsiho
            end
        end
        status = nil -- uz ho nepotrebuju        

    end

    if Network_Ready < 0 then -- chyba v pristupu k siti, nepovedlo se najit AP nebo nedostal IP
        -- -1 not coverage
        -- -2 not IP assigned
        -- -9 not password file
		Fail_Wifi = Fail_Wifi + 1
		if Fail_Wifi > 100 then -- fakt uz to trva dlouho - zde je otazka zda v novem systemu odesilani neni lepsi udelat rovnou reset nez se pokouset o reinicalizaci
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

function KontrolaOdeslani2() -- toto je finta jak mit globalni funkci co nejmensi, protoze ji potrebuju volat vyse kde lokalni funkce neni dostupna
    KontrolaOdeslani()
end

Web = require("cloud")
Web.setup('77.104.219.2',Rapik,Rnod,'emon.jiffaco.cz',3)
tmr.alarm(2, 250, 0,  function() KontrolaOdeslani() end) 

