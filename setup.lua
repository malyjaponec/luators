--setup.lua

    local gpionum = {[0]=3,[1]=10,[2]=4,[3]=9,[4]=1,[5]=2,[10]=12,[12]=6,[13]=7,[14]=5,[15]=8,[16]=0}

    -- prevede ID luatoru do 36-kove soustavy
    local function IDIn36(IN)
        local kody,out,znak="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ",""
        while (IN>0) do 
            IN,znak=math.floor(IN/36),(IN % 36)+1
            out = string.sub(kody,znak,znak)..out
        end
        return out
    end

-- konstanty pro reportovani
    ReportInterval = 10*60 -- sekund a nesmi byt kratsi nez 31!!!
    ReportIntervalFast = 1*60 -- rychlost rychlych reportu
    ReportFast = 0 -- defaultne vypnute
    ReportNode = "3" -- bateriove merici systemy zmer a vypni pouzivaji n    3
    ReportFieldPrefix = IDIn36(node.chipid()).."_"
    file.open("apikey.ini", "r") -- soubor tam musi byt a ze neni neosetruji
        ReportApiKey = file.readline() -- soubor nesmi obsahovat ukonceni radku, jen apikey!!!
    file.close()

-- Debug
    Debug = 0
    if (file.open("debug.ini", "r") ~= nil) then Debug = 1 end -- debuguje se jen kdyz je soubor debug.ini
      
-- Spustim procesy nastavujici sit
--    local network -- musi byt local protoze globalni promenna s necim koliduje
    network = require("network")
    network.setup(1, gpionum[2]) -- casovace 0 pro sit

-- Spustim proces merici baterii, ktery bezi dokud nedojde k okamizku odeslani
    battery = require("battery")
    battery.setup(2) -- casovac 1 se pouziva pro mereni baterie

-- Spustim proces merici senzoru
    dht22 = require("dht22")
    dht22.setup(3,ReportFieldPrefix,gpionum[5],gpionum[13])
--    dalas1 = require("dalas")
--    dalas1.setup(5,ReportFieldPrefix,gpionum[4])
--    dalas2 = require("dalas1")
--    dalas2.setup(6,ReportFieldPrefix,gpionum[15])
--    baro = require("baro")
--    baro.setup(4,ReportFieldPrefix,gpionum[14],gpionum[12]) 

-- Spustim odesilac, bez casovace primo
    LedSend = nil
    dofile("send.lc") -- pouziva casovac 0
    
-- Uklid
    gpionum = nil
        
