--setup.lua
-- konstanty pro GPIO operace
    local GP = {[0]=3,[1]=10,[2]=4,[3]=9,[4]=1,[5]=2,[10]=12,[12]=6,[13]=7,[14]=5,[15]=8,[16]=0}

-- uklid pinu co by mohli svitit ledkama 
  -- zrusil jsem at svitej!

-- prevede ID luatoru do 36-kove soustavy a ulozi si hodnotu do promenne pro reportovani
    local function IDIn36(IN)
        local kody,out,znak="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ",""
        while (IN>0) do 
            IN,znak=math.floor(IN/36),(IN % 36)+1
            out = string.sub(kody,znak,znak)..out
        end
        return out
    end
    Rpref = IDIn36(node.chipid()).."_"
	IDIn36 = nil -- funkci po tom co ji pouziju zrusim

-- nastavi knihovnu pro RGB
    rgb = require("rgb")
    rgb.setup() -- volam s defaultnim zapojeni RGB
    rgb.set() -- volam bez parametru = cerna

-- vice vypisu, temer se v nove vzniknutych kodech nepouziva, ale v sitove vrstve je pouzito
    Debug = 0 
    if (file.open("debug.ini", "r") ~= nil) then
        Debug = 1
        file.close()
    end

-- konstanty pro reportovani
    Rcnt = 0 -- citac poctu reportu od zapnuti
    Rnod = "6" -- plynomery jsou pod node 6
    if (file.open("apikey.ini", "r") ~= nil) then
        Rapik = file.readline() -- soubor nesmi obsahovat ukonceni radku, jen apikey!!!
        file.close()
    else
        Rapik = "xxx"
        print("PANIC: no apikey.ini")
    end
    Rdat = {}

-- vycisteni RTC ram pameti, pouziva se pro nahodne restarty a ne pro ochranu pred 
-- zapnutim napajeni, ale jak poznam, ze je to zapnuti systemu? podle kontrolniho souctu
-- energii, ktery zapisuji vzdy pri zmene energi
    local sum,minimum,maximum,energy
    sum,minimum,maximum,energy = rtcmem.read32(0,4)
    if sum ~= (minimum+maximum+energy) then -- nesouhlasi kontrolni soucet
        rtcmem.write32(0, 0,0,0,0,0,0,0)
    end
	sum,minimum,maximum,energy = nil,nil,nil,nil


-- Spustim procesy nastavujici sit a merici data
    Network_Ready = 0 -- sit neni inicialozvana
    tmr.alarm(0, 250, 0, function() dofile("network.lc") end)

    Energy = {0} -- akumulace energie pro jednotlive vstupy (ve otackech kolecka, prevod se musi udelat na cloudu)
    Power = {-1} -- ukladani posledniho vykonu pro jednotlive vstupy (v otackach kolecka za jednotku casu) na zaklade posledni delky pulzu
    tmr.alarm(1, 10, 0,  function() dofile("measure.lc") end)
		-- minimalni cas aby to co nejdrive zacalo merit

    -- odesilac nepotrebuje zadne hlobalni promenne, taha data z tech vyse definovanych pro ostatni procesy
    tmr.alarm(2, 500, 0,  function() dofile("send.lc") end)

-- uklid toho co uz nepotrebujem 
    print("run")
