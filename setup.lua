--setup.lua
-- konstanty pro GPIO operace
    local GP = {[0]=3,[1]=10,[2]=4,[3]=9,[4]=1,[5]=2,[10]=12,[12]=6,[13]=7,[14]=5,[15]=8,[16]=0}
	
-- verze software
	SW_VERSION = "6"

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
    Rnod = "7"
	-- "1" plynomery maji vyhrazeny node 1
    -- "4" elektromery jsou node 4
	-- "7" vodomery pouzivaji node 7
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

--[[ zde je mapa pameti 
	0 - kontrolni soucet
	1,2,3 - pocet pulzu ktere se nepovedlo poslat na server
	4,5,6 - posledni vykon na dane fazi, zaloha pro obnoveni hodnoty po restartu
	7,8,9 a 10,11,12 - posedni hodnoty minima a maxima analogoveho scanneru - plati jen pro plynomery,
		zatim jen 2 hodnoty protoze zatim mam jen jednovstupovy plynomer
	
	Kontrolni soucet se pocita pouze z prvnich 3 hodnot (nepredana data na server)
	]]
    local sum,value1,value2,value3
    sum,value1,value2,value3 = rtcmem.read32(0,4)
    if sum ~= (value1+value2+value3) then -- nesouhlasi kontrolni soucet
        rtcmem.write32(0,  0, 0,0,0, 0,0,0, 1024,1024,1024,0,0,0) -- rozsireny reset i pro plynomery
		print("RTC memory eset")
    end


-- Spustim procesy nastavujici sit a merici data
    Network_Ready = 0 -- sit neni inicialozvana
    tmr.alarm(0, 250, 0, function() dofile("network.lc") end)
	-- casovac nula
	
	-- Spustim pridruzene mereni teploty DS18B20... libovolny pocet
	-- [[
	dalas = require("dalas")
	function dalas_start()
		TimeStartLast = tmr.now()/1000 -- zapisu si cas posledniho spuseni, ziskam tak presne cas za jak dlouho doslo ke zmereni cidel, ne cas od zapnuti procesoru
		dalas.setup(5,GP[0],nil) -- na 0 je 3 dratovy rezim, nil na 2 dratovy rezim, ktery nepouzivame ted
	end
	dalas_start()
	-- ]]
	
    -- sjednocene elektromery, GP[2] se nesmi pouzit jako vstup do elektromeru, zpusobuje to zaseknuti po restartu a nejspis i GPIO0
	--
    --Measure_Faze = { GP[4], GP[5], nil } -- elektromer 2 fazovy v garazi pro zasuvky a svetla
	--Measure_Faze = { GP[4], GP[5], GP[14] } -- elektromer 3 fazovy v garazi pro 380
	Measure_Faze = { GP[4], nil, nil } -- elektromer 1 fazovy pro meric1, firman 
    Energy_Faze = {0,0,0} -- akumulace energie pro jednotlive vstupy (ve Wh)
    Power_Faze = {-1,-1,-1} -- ukladani posledniho vykonu pro jednotlive vstupy (ve W) na zaklade posledni delky pulzu
	--[[
    tmr.alarm(1, 10, 0,  function() dofile("measure_elektro.lc") end)
		-- casovac 1 pro standardni zpracovani dat
		--         3 pro velmi rychle cteni digitalnich vstupu pro vypocet "pulzu"
	--]]
	
	-- [[
	-- vodomery pouzivaji jiny mechanizmus snimani pomoci dvou snimacu aby se odstranilo kmitani a nikdy nebude vic vodomeru na jednom
	-- presto zachovavam promenne z elektromeru a pouzije se jen prvni na druhou stranu je potreba mit vzdy 2 vstupy na jeden merici bod
	-- proto je tu fazeB ktera definuje druhy vstup. Moznost mit 3 vodomery na jednom luatoru je zachovana i kdyz to asi nebude stihat
	-- ani nemam misto kde bych to pouzil
	Measure_FazeB = { GP[5], nil, nil }
	tmr.alarm(1, 10, 0,  function() dofile("measure_voda.lc") end)
		-- casovac 1
	--]]
	
	--dalsi hodnoty pro plynomer, pro elektromer se nemusi definovat
	--[[
	Measure_Faze = {GP[4],GP[5],nil} -- v plynomeru to urcuje ledky ktere se rozsveci pred merenim analogu
    Energy_Faze = {0,0,0} -- akumulace energie pro jednotlive vstupy (ve Wh)
    Power_Faze = {-1,-1,-1} -- ukladani posledniho vykonu pro jednotlive vstupy (ve W) na zaklade posledni delky pulzu
	Digitize_Minimum = {1024,1024,1024} -- tyto hodnoty definuji meze kde se pohybuje signal a odesilac je posila na server, proto jsou globalni, hodnota neni podstatna nacitaji se z pameti RTC
	Digitize_Maximum = {0,0,0}
	Digitize_Average = {0,0,0}
	Digitize_Deviate = {0,0,0}
	Digitize_Status = {5,5,5} -- hodnota 5 se nepouziva
	Digitize_CaptureTime = 0
	AnalyticReport = 1 -- posila i analyticka data jako prumer, maximum minimum standardni odchylky a tak
    tmr.alarm(1, 10, 0,  function() dofile("measure_plyn.lc") end)
	--]]
		-- casovac 1 pro standardni zpracovani dat
		--         3 pro analogove mereni

    -- odesilace nepotrebuje zadne klobalni promenne, taha data z tech vyse definovanych pro ostatni procesy
	Analog = 0 -- pokud je definovane odesila analogovou hodnotu prectenou v okamziku odesilani, bez filtrace
    tmr.alarm(2, 500, 0,  function() dofile("send.lc") end)
		-- casovac 2

-- uklid toho co uz nepotrebujem 
    print("run")
