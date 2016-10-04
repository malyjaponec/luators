--setup.lua
--
-- to co je mezi radkami hvezdicek ************ je misto kam by mel uzivatel sahnout kdyz chce neco nastavit

    --gpionum = {[0]=3,[1]=10,[2]=4,[3]=9,[4]=1,[5]=2,[10]=12,[12]=6,[13]=7,[14]=5,[15]=8,[16]=0}
    -- uspora pameti,nevyuzivane piny nejsou v definici
    gpionum = {[0]=3,[2]=4,[4]=1,[5]=2,[12]=6,[13]=7,[14]=5,[15]=8,[16]=0}

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

    -- post processing funkce, kterou si odesilac pred odeslanim zavola
    function PostProcessing(_datove_pole)
        -- *************************
        -- teplota kourovou v garazi
        if _datove_pole["6GJTY_t287820080000804F"] ~= nil then -- je dostupna teplota kourovodu
            if _datove_pole["6GJTY_t287820080000804F"] > 30 then -- teplota je pres 30 stupnu
                ReportFast = 1 -- zrychlene reportovani
            end
        end
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

        -- Spustim procesy nastavujici sit
        network = require("network")
        network.setup(1, gpionum[5])

        -- Spustim proces merici baterii, ktery bezi dokud nedojde k okamizku odeslani
        battery = require("battery")
        battery.setup(2,nil) -- bez mereni svetla
        --battery.setup(2,gpionum[14]) -- s merenim svetla - pouziva pouze foliovnik, mereni svetla neni presne a navic tam je proudovy unik

        -- Spustim proces merici senzoru
        dht22 = require("dht22")
        dht22.setup(3,gpionum[5],nil,3) -- luatori s trvale napajenym DHT
        --dht22.setup(3,gpionum[5],gpionum[13],4) -- pareniste a detsky pokoj a nove loznice protze bez toho dht prestavalo merit
        --[[ k tomu jen to ze s novym sw je problem napajeni z pinu, protoze dht pak nemeri
             behem vysilani wifi dokud nedostane luator IP, zrejme predchozi software stihl nejake
             jedno mereni pred vysilanim a to mu stacilo, nova implementace potrebuje opakovani
             kvuli presnosti a to pak dojde k tomu ze se zmeri az po ziskani IP a zdrzuje to 
             a jsou i luatory ktere vubec nezmeri nebo s urcitou pravdepodobnosti nezmeri, novy sw
             opakuje pokusy 30s to potom jdou baterky rychle do kytek, takze se vracim na trvale napajeni
             ]]--
        --dalas = require("dalas")
        --dalas.setup(5,gpionum[4],nil)
        --baro = require("baro")
        --baro.setup(4,gpionum[14],gpionum[12]) 
        --dist = require("distance")
        --dist.setup(3,20) 
        --analog = require("analog")
        --analog.setup(2,10)
        -- *************************
    end
    
-- konstanty pro reportovani
-- *************************
    ReportInterval = 10*60
    --ReportIntervalFast = 1*60 -- rychlost rychlych reportu, pokud je null tak se to nepouziva
    --PeriodicReport = 0 -- pokud je null pak se reportuje 1x a usne se, jakakoliv hodnota zpusobi neusnuti a restart po zadane dobe
    ReportFast = 0 -- defaultne vypnute
    ReportNode = "3" -- bateriove long update merici systemy pouzivaji node 3, teda ja to tak pouzivam
    --ReportNode = "5" -- merici systemy s rychym update pouzivaji 5
    -- pro solar a vytapeni je vyhrazena 2 a pro elektromery 4
-- *************************
    
    ReportFieldPrefix = IDIn36(node.chipid()).."_" -- co nejkratsi jednoznacna ID luatoru z jeho SN
    IDIn36 = nil -- rusim funkci uz ji nebudu nikdy potrebovat
    -- apikey se nacita ze souboru
    if file.open("apikey.ini", "r") == nil then -- soubor neexistuje
        print("PANIC: no apikey!")
    else
        ReportApiKey = file.readline() -- soubor nesmi obsahovat ukonceni radku, jen apikey!!!
        file.close()

-- Debug, pokud existuje soubor, knihovny vypisuji veci informace se zrovna deje
        if (file.open("debug.ini", "r") ~= nil) then Debug = 1 file.close() else Debug = 0 end
      
-- Spustim mereni, co se spusti je definovane vyse
        MeasureInit()

-- Spustim odesilac, bez casovace primo
        LedSend = gpionum[0]
        dofile("send.lc") -- pouziva casovac 0
    
-- Uklid
    end
    if PeriodicReport == nil then -- pokud nepouzivam periodicky reporting 
        gpionum = nil -- definici pinu uz nebudu potrebovat
        MeasureInit = nil -- funkci spoustejici mereni uz nikdy nezavolam
    end
