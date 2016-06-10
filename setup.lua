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
    Rcnt = 0
    Rnod = "4" -- vsechny elektromery jsou 4
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
    local sum,value1,value2,value3
    sum,value1,value2,value3 = rtcmem.read32(0,4)
    if sum ~= (value1+value2+value3) then -- nesouhlasi kontrolni soucet
        rtcmem.write32(0, 0,0,0,0,0,0,0)
    end


-- Spustim procesy nastavujici sit a merici data
    Network_Ready = 0 -- sit neni inicialozvana
    tmr.alarm(0, 250, 0, function() dofile("network.lc") end)

    -- sjednocene elektromery, GP[2] se nesmi pouzit, zpusobuje to zaseknuti po restartu
    Measure_Faze = { GP[4], GP[5], GP[14] } -- definice pinu ktere se ctou, prestal jsem pouzivat pin 2 zasekaval system
    Energy_Faze = {0,0,0} -- akumulace energie pro jednotlive vstupy (ve Wh)
    Power_Faze = {-1,-1,-1} -- ukladani posledniho vykonu pro jednotlive vstupy (ve W) na zaklade posledni delky pulzu
    tmr.alarm(1, 10, 0,  function() dofile("measure.lc") end)
		-- minimalni cas aby to co nejdrive zacalo merit

    -- odesilace nepotrebuje zadne klobalni promenne, taha data z tech vyse definovanych pro ostatni procesy
    tmr.alarm(2, 500, 0,  function() dofile("send.lc") end)

-- uklid toho co uz nepotrebujem 
    print("run")
