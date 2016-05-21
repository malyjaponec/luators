--setup.lua

local AnalogMinimum
local AnalogMaximum
local AnalogCount

local InitDelayTime
local InitStartTime

    -- prevede ID luatoru do 36-kove soustavy
    local function IDIn36(IN)
        local kody,out,znak="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ",""
        while (IN>0) do 
            IN,znak=math.floor(IN/36),(IN % 36)+1
            out = string.sub(kody,znak,znak)..out
        end
        return out
    end

    local function InitDelay()
        local AnalogValue = adc.read(0)
        if (AnalogValue > AnalogMaximum) then 
            AnalogMaximum = AnalogValue
        end
        if (AnalogValue < AnalogMinimum) then 
            AnalogMinimum = AnalogValue
        end
        
        if (tmr.now() < (InitStartTime+InitDelayTime)) then
            AnalogCount = AnalogCount + 1
            tmr.alarm(0, math.random(1,2), 0,  function() InitDelay() end)
        else
            Fields[ReportFieldPrefix.."bat_min"] = AnalogMinimum
            Fields[ReportFieldPrefix.."bat_max"] = AnalogMaximum
            Fields[ReportFieldPrefix.."bat_cnt"] = AnalogCount

            -- a spoustim hlavni proces vyhledani AP
            Fields[ReportFieldPrefix.."tb"] = tmr.now()/1000
            tmr.alarm(0, 10, 0,  function() dofile("start.lc") end)
        end
    end

    local function InitDelayStart()
        adc.read(0) -- nekdy prvni prevod vrati nesmysl
        InitStartTime = tmr.now()
        InitDelayTime = 1000000 -- X sekundy limit, pak se s merenim skonci
        math.randomseed(tmr.now())
        AnalogMinimum = 1024
        AnalogMaximum = 0
        AnalogCount = 1
        InitDelay()
    end

-- konstanty pro reportovani
    ReportInterval = 10*60 -- sekund a nesmi byt kratsi nez 31!!!
    ReportIntervalFast = 2*60 -- rychlost rychlych reportu
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
    Sb3 = gpionum[12] -- zapojeni 2 dratove phantom napajeni
    Sb3p = 3 -- volba presnosti pro phantom
    Sb3d = 750000 -- odpovidajici cekaci doby
    gpio.mode(Sb3, gpio.INPUT, gpioFLOAT) 
    gpio.mode(Sb3, gpio.OUTPUT) 
    gpio.write(Sb3, gpio.HIGH)
    

-- nastaveni pinu pro zapnuti proudu do DHT22
    gpio.mode(DHT22powerpin,gpio.OUTPUT)
    gpio.write(DHT22powerpin,gpio.HIGH) 
    -- DHT22 napajim pinem GPIO13 (vedle VCC) protoze to pri sleep
    -- usetri kolem 10uA
    
    print("Measuring battery.") 
    --InitDelayStart()
    dofile("measure.lc")
    
        -- Spustim uvodni X sekundove mereni baterie
