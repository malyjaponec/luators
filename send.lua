-- send.lua
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

--------------------------------------------------------------------------------
local function KonecAbnormal()
    rgb.set("magenta")
    -- knihovna http se nema volat konkurencne ale kdyz mi do 15s nic nevrati
    -- tak se vratim do stvu kdy muzu zase posilat a jestli jeste bezi predchozi
    -- beh, je to jeji problem, mela do 10s skoncit 
    state = 4 -- fejkuju stav 4 - konec prenosu
    result = 0 -- stejne tak nastavuji vysledek na nepreneseno a o zbytek se postaraji standardni mechanizmy
    tmr.alarm(2, 2500, 0, function() KontrolaOdeslani2() end) -- vim ze urcite Xs nechci nic posilat, prvni kontrolu (kvuli siti udelam za 2,5s)
end

--------------------------------------------------------------------------------
local function Konec(code, data)
    if (code == nil) then
        code = -100
    end
    if (code > 0) then
        rgb.set()
        if Debug == 1 then print("S> odeslano/" .. code) end
        Fail_Send = 0 -- nuluji cinac chyb pri penosu, povedlo se prenest
        Fail_Wifi = 0 -- kdyz se to preneslo tak bude wifi asi v poradku, nuluju, jinde se to nedela
        rtcmem.write32(0, 0,0,0,0) -- nuluji zalozni hodnoty v RTC memory vcetne kontrolniho souctu
    else
        rgb.set("blue")
        if Debug == 1 then print("S> chyba /".. code) end
        Fail_Send = Fail_Send + 1 -- zvysuji citac chyb prenosu
    end
    tmr.alarm(2, 2500, 0, function() KontrolaOdeslani2() end) -- vim ze urcite Xs nechci nic posilat, prvni kontrolu (kvuli siti udelam za 2,5s)
end

--------------------------------------------------------------------------------
local function Start()
    rgb.set("green")

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
		if Debug == 1 and SentEnergy_Faze[i] > 0 then
			print("S> pulse["..i.."]="..SentEnergy_Faze[i])
		end
    end
    
    rtcmem.write32(0, suma)-- zapisu si hodnotu kontrolniho souctu do RTC pameti
    for i=1,3 do 
        -- zpracovani vykonu k odeslani
        if Power_Faze[i] >= 0 then -- zaporne hodnoty nepredavam zamerne
            Rdat[Rpref.."p"..i] = Power_Faze[i] -- hodnotu pridam do odesilanych dat
			if Debug == 1 then print("S> power["..i.."]="..Power_Faze[i]) end
        end
	end    
    -- pridam si nektera technologicka data, ktera predavam na cloud
    Rcnt = Rcnt + 1
    Rdat[Rpref.."cnt"] = Rcnt
    Rdat[Rpref.."an"] = adc.read(0) -- vycte si aktualni hodnotu analogoveho vstupu, informacni udaj pro analyzu analogoveho zpracovani dat
	Rdat[Rpref.."min"] = Digitize_Minimum -- udaje pro analyzu kde se pohybuje vstupni signal
	Rdat[Rpref.."max"] = Digitize_Maximum 
	Rdat[Rpref.."sta"] = Digitize_Status
    Rdat[Rpref.."x"..Get_AP_MAC()] = 1
    Rdat[Rpref.."fc"] = Fail_Send   
    Rdat[Rpref.."et"] = tmr.now()/1000000
    Rdat[Rpref.."hp"] = node.heap() 

    -- prevedu na URL
    local url = "http://emon.jiffaco.cz/emoncms/input/post.json?node=" .. Rnod .. 
                "&json=" .. cjson.encode(Rdat) .. 
                "&apikey=" .. Rapik
    Rdat = nil -- data smazu explicitne

    http.get(url, nil, function(code,data) Konec(code,data) end )

    url = nil
    KonecCounter = 0 -- citac pro timeout 
    tmr.alarm(2, 15000, 0, function() KonecAbnormal() end) -- nacasuji kontrolu pokud nezavola callback
end

--------------------------------------------------------------------------------
local function ReinicializujSit()
    rgb.set("cyan")
    if Debug == 1 then print("s>network failure") end
    wifi.sta.disconnect()    
    wifi.sta.connect()
    wifi.sta.autoconnect(1)
    tmr.alarm(0, 500, 0, function() dofile("network.lc") end) 
    -- reinicalizace site, casovac je zde aby svitila dost dlouho dioda cian
    tmr.alarm(2, 2500, 0,  function() KontrolaOdeslani2() end)
    -- a dalsi kontrolu odeslani nacasuju za 2,5 sekundy protoze prihlaseni k siti nebude
    -- extra rychle a nesmim to nacasovat kratsi nez se provede predchozi casovac jinak
    -- by se ten predchozi furt precasovaval
end

--------------------------------------------------------------------------------
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
            return
        else
            -- Kontrola zda uz neni cas poslat na cloud aktualizaci
            local timedif = tmr.now() - SendTime
            if (timedif > 5000000) or (timedif < -5000000) then -- zdanllivy nesmysl, ktery pokryje pretoceni casovace do nekonecneho zaporu
                SendTime = tmr.now() -- Zapisu si cas ted tak aby perioda byla neovlivnena tim jak dlouho se to prenasi
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
            return
		end
    end

    if Fail_Send > 20 then -- uz se po sobe X krat nepodarilo predat
        Fail_Send = 0 -- tento chybejici prikaz psuoboval to, ze pri vypadku serveru se vsechny elektromery zasekli
        ReinicializujSit()
        return
    end        

    -- Nacasovat dalsi kontrolu pokud jsem nenacasoval neco jineho
    tmr.alarm(2, 250, 0,  function() KontrolaOdeslani() end)
end

--------------------------------------------------------------------------------
function KontrolaOdeslani2() -- toto je finta jak mit globalni funkci co nejmensi, protoze ji potrebuju volat vyse kde lokalni funkce neni dostupna
    KontrolaOdeslani()
end

--------------------------------------------------------------------------------
tmr.alarm(2, 250, 0,  function() KontrolaOdeslani() end) 

