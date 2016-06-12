--setup.lua

    gpionum = {[0]=3,[1]=10,[2]=4,[3]=9,[4]=1,[5]=2,[10]=12,[12]=6,[13]=7,[14]=5,[15]=8,[16]=0}

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
    ReportInterval = 1*60 -- sekund a nesmi byt kratsi nez 31!!!
    ReportIntervalFast = 1*60 -- rychlost rychlych reportu
    ReportFast = 0 -- defaultne vypnute
    
    ReportNode = "3" -- bateriove merici systemy zmer a vypni pouzivaji node 3
    ReportFieldPrefix = IDIn36(node.chipid()).."_"
    file.open("apikey.ini", "r") -- soubor tam musi byt a ze neni neosetruji
        ReportApiKey = file.readline() -- soubor nesmi obsahovat ukonceni radku, jen apikey!!!
    file.close()
    Fields = {}
    Debug = 0
    if (file.open("debug.ini", "r") ~= nil) then Debug = 1 end -- debuguje se jen kdyz je soubor debug.ini
    DHT22pin = gpionum[5]
    DHT22powerpin = gpionum[13]
    Lightpin = gpionum[14] 
    
-- nastaveni pinu pro spravne mereni baterie
    gpio.mode(Lightpin,gpio.OUTPUT)
    gpio.write(Lightpin,gpio.HIGH) 
    -- pripojim fotoodpor na + (je to pres diodu) tak aby nemel svod pri mereni baterie 
    -- pokud v systemu mereni svetla neni, tak se nic nestane, protoze na GPIO14 nic neni

-- konstanty a jednorazova priprava pro mereni, zavisi na measure.lua
    -- teploty
    Sb3 = nil -- zapojeni 2 dratove phantom napajeni
    Sb3p = 3 -- volba presnosti pro phantom
    Sb3d = 750000 -- odpovidajici cekaci doby
    if (Sb3 ~= nil) then
        gpio.mode(Sb3, gpio.INPUT, gpioFLOAT) 
        gpio.mode(Sb3, gpio.OUTPUT) 
        gpio.write(Sb3, gpio.HIGH)
    end
    
-- nastaveni pinu pro zapnuti proudu do DHT22

    
-- Spustim procesy nastavujici sit
--    local network -- musi byt local protoze globalni promenna s necim koliduje
    network = require("network")
    network.setup(0, gpionum[0]) -- casovace 0 pro sit

-- Spustim proces merici baterii, ktery bezi dokud nedojde k okamizku odeslani
-- to je misto kde si proces odesilajici vycte data
--    local battery
    battery = require("battery")
    battery.setup(1) -- casovac 1 se pouziva pro mereni baterie

-- Spustim proces merici DHT a DALAS
--    local sensors
    sensors = require("sensors")
    sensors.setup(2,ReportFieldPrefix) -- casovac 2 pro merici algoritmy
    
-- Spustim cekani na konec
    dofile("send.lua") -- pouziva casovac 3
    



