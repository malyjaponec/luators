--setup.lua
--
-- to co je mezi radkami hvezdicek ************ je misto kam by mel uzivatel sahnout kdyz chce neco nastavit

    --gpionum = {[0]=3,[1]=10,[2]=4,[3]=9,[4]=1,[5]=2,[10]=12,[12]=6,[13]=7,[14]=5,[15]=8,[16]=0}
    -- uspora pameti,nevyuzivane piny nejsou v definici
    gpionum = {[0]=3,[2]=4,[4]=1,[5]=2,[12]=6,[13]=7,[14]=5,[15]=8,[16]=0}
	
	-- verze software
	SW_VERSION = "6"	

    -- prevede ID luatoru do 36-kove soustavy, tak aby to bylo reprezentovano co nejmene znaky
    local function IDIn36(IN)
        local kody,out,znak="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ",""
        while (IN>0) do 
            IN,znak=math.floor(IN/36),(IN % 36)+1
            out = string.sub(kody,znak,znak)..out
        end
        kody,znak = nil
        return out
    end

    -- post processing funkce, kterou si odesilac pred odeslanim zavola a ona muze neco upravit nebo hlavne 
	-- slouzi k prepnuti rychlosti reportingu, coz ale nakonec nikde nepouzivame protoze se vsude nasadili
	-- systemy napajene ze site, treba protoze krome reportu taky ovladaji rele
    function PostProcessing(_datove_pole)
        -- *************************
--        -- teplota kourovou v garazi
--		if _datove_pole["6GJTY_t287820080000804F"] ~= nil then -- je dostupna teplota kourovodu
--			if _datove_pole["6GJTY_t287820080000804F"] > 30 then -- teplota je pres 30 stupnu
--				ReportFast = 1 -- zrychlene reportovani
--            end
--        end
--        -- zkusebni cidlo 
--        if _datove_pole["6GJTY_t287820080000804F"] ~= nil then -- je dostupna teplota kourovodu
--            if _datove_pole["6GJTY_t287820080000804F"] > 30 then -- teplota je pres 30 stupnu
--                ReportFast = 1 -- zrychlene reportovani
--            end
--        end
        -- *************************
    end
    
    -- inicializuje veskere merici mechanizmy, je to v globalni funkci protoze pri 
    -- periodickem reportovani se to vola znova a znova
    function MeasureInit()
        -- *************************

        -- Spustim procesy nastavujici sit, nastavi se casovac a indikacni led
        network = require("network")
        network.setup(1, gpionum[15]) -- s ledkovym vystupem
		--network.setup(1, nil) -- bez ovladani ledky, muze byt vhodne pro exoticke systemy pouzivajici SPI a I2C co nemaji dost volnych pinu jeste na prdle blikani

        -- Spustim proces merici baterii, ktery bezi dokud nedojde k okamizku odeslani
        --battery = require("battery")
        --battery.setup(2, nil) -- bez mereni svetla
        --battery.setup(2,gpionum[14]) -- s merenim svetla - pouziva pouze foliovnik, mereni svetla neni presne a navic tam je proudovy unik

        -- Spustim proces merici senzoru
        --dht22 = require("dht22")
        --dht22.setup(3,gpionum[5],nil,3) -- luatori s trvale napajenym DHT
        --dht22.setup(3,gpionum[5],gpionum[14],3) -- DHT odpojovane - napajeni z pinu
        --[[ k tomu jen to ze s novym sw je problem napajeni z pinu, protoze dht pak nemeri
             behem vysilani wifi dokud nedostane luator IP, zrejme predchozi software stihl nejake
             jedno mereni pred vysilanim a to mu stacilo, nova implementace potrebuje opakovani
             kvuli presnosti a to pak dojde k tomu ze se zmeri az po ziskani IP a zdrzuje to 
             a jsou i luatory ktere vubec nezmeri nebo s urcitou pravdepodobnosti nezmeri, novy sw
             opakuje pokusy 30s to potom jdou baterky rychle do kytek, takze se vracim na trvale napajeni
			 
			 dodatek: nektere dht se na trvalem napajeni zasekavaji, nahodne zaden za 3 hodiny prestanou merit
			 software pak 30s zkousi se s nima domluvit a nic nezmeni a vybiji baterky, takze je to
			 hodne individualni jak to zapojit, zda se ze to zavisi od kusu dht
             ]]--
        dalas = require("dalas")
        dalas.setup(5,gpionum[14],nil,gpionum[16])
        --baro = require("baro")
        --baro.setup(4,gpionum[14],gpionum[12]) 
        --dist = require("distance")
        --dist.setup(3,50) 
        analog = require("analog")
        analog.setup(2,25)

		digital = require("digital")
		digital.capture(gpionum[4],gpionum[5])
		
        -- *************************
    end
    
-- *************************
-- konstanty pro reportovani
-- *************************
    ReportInterval = 5
    --ReportIntervalFast = 1*60 -- rychlost rychlych reportu, pokud je null tak se to nepouziva
    PeriodicReport = 0 -- pokud je null pak se reportuje 1x a usne se, jakakoliv hodnota zpusobi neusnuti a restart po zadane dobe
    ReportFast = 0 -- defaultne vypnute
    ReportNode = "1" 
	--[[ moje rozdeleni nodu emonu jak je pouzivam ja
	1 plynomer, kotel a vytapeni
	2 solarni ohrev vody
	3 pomalu aktualizovane merici systemy z baterii (teplomery, delkomery, barometry)
	4 elektromery
	5 rychle merici systemy z AC (udirna) a kontrolni systemy (to co ma vystupni agenty)
	6 node red - vypoctena data ktera tlaci na emon node red systemy
	7 testovani 
	]]
-- **********************************
-- konstanty pro cteni dat ze serveru
-- **********************************
	--GetFeeds = {[639]=gpionum[4]}
	
-- ***
    ReportFieldPrefix = IDIn36(node.chipid()).."_" -- co nejkratsi jednoznacna ID luatoru z jeho SN
    IDIn36 = nil -- rusim funkci uz ji nebudu nikdy potrebovat
    -- apikey se nacita ze souboru
    if file.open("apikey.ini", "r") == nil then -- soubor neexistuje
        print("PANIC: no apikey!")
    else
        ReportApiKey = file.readline() -- soubor nesmi obsahovat ukonceni radku, jen apikey!!!
        file.close()
		
-- Prenastaveni pinu, ktere nechci pouzivat, nekdy se rozsveci RGB ledka a podobne takze zde je prostor to rucne napsat
	gpio.mode(gpionum[13], gpio.OUTPUT) 
	gpio.write(gpionum[12], gpio.LOW)

-- Debug, pokud existuje soubor, knihovny vypisuji veci informace se zrovna deje
        if (file.open("debug.ini", "r") ~= nil) then Debug = 1 file.close() else Debug = 0 end
      
-- Spustim mereni, co se spusti je definovane vyse
        MeasureInit()

-- Spustim odesilac, bez casovace primo
        LedSend = gpionum[12] -- zaporna hodnota se pouzije pokud chceme ledku spinat otevrenym kolektorem, kladna hodnota kdyz je ledka zapojena proti zemi
        dofile("send.lc") -- pouziva casovac 0
    
-- Uklid
    end
    if PeriodicReport == nil then -- pokud nepouzivam periodicky reporting 
        gpionum = nil -- definici pinu uz nebudu potrebovat
        MeasureInit = nil -- funkci spoustejici mereni uz nikdy nezavolam
    end
