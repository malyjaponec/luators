--setup.lua

    -- prevede ID luatoru do 36-kove soustavy
    function IDIn36(IN)
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
        InitDelayTime = InitDelayTime - InitDelayStep
        if (InitDelayTime > 0) then
            tmr.alarm(0, InitDelayStep+math.random(-5,5), 0,  function() InitDelay() end)
        else
            InitDelayTime = nil
            InitDelayStep = nil

            if Debug == 1 then print ("Batt min: "..AnalogMinimum) end
            Fields[ReportFieldPrefix.."baterie_min"] = AnalogMinimum
            AnalogMinimum = nil
            if Debug == 1 then print ("Batt max: "..AnalogMaximum) end
            Fields[ReportFieldPrefix.."baterie_max"] = AnalogMaximum
            AnalogMaximum = nil

            -- a spoustim hlavni proces vyhledani AP
            tmr.alarm(0, 100, 0,  function() dofile("start.lc") end)
        end
    end

    local function InitDelayStart()
        adc.read(0) -- nekdy prvni prevod vrati nesmysl
        InitDelayTime = 3000
        InitDelayStep = 20
        AnalogMinimum = 1024
        AnalogMaximum = 0
        print("Measuring battery.") 
        InitDelay()
    end

-- konstanty pro reportovani
    ReportInterval = 10 -- minut
    ReportNode = "3"
    ReportFieldPrefix = IDIn36(node.chipid()).."_"
    file.open("apikey.ini", "r") -- soubor tam musi byt a ze neni neosetruji
        ReportApiKey = file.readline() -- soubor nesmi obsahovat ukonceni radku, jen apikey!!!
    file.close()
    Fields = {}
    Debug = 0
    if (file.open("debug.ini", "r") ~= nil) then Debug = 1 end -- debuguje se jen kdyz je soubor debug.ini
    DHT22pin = gpionum[5]
    
-- Inicializace a mereni baterie    
    gpio.mode(gpionum[14],gpio.OUTPUT)
    gpio.write(gpionum[14],gpio.HIGH) 
    -- pripojim fotoodpor na + (je to pres diodu) tak aby nemel svod pri mereni baterie 
    -- pokud v systemu mereni svetla neni, tak se nic nestane, protoze na GPIO14 nic neni
    
    InitDelayStart()
    -- Spustim uvodni 3 sekundove mereni baterie
