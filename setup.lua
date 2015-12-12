--setup.lua
    local AnalogMinimum
    local AnalogMaximum
    local AnalogCount
    local InitDelayTime
    local InitStartTime

-- nastaveni hodin na 0:0:0
    local function ClockInit()
        -- Zapnu pridrzeni napajeni, jinak by se po resetu hodin vypnul, a nastavim bezpecnostni interval na vypnuti, kdyby se to zacyklovalo
        gpio.mode(gpionum[13],gpio.OUTPUT)
        gpio.write(gpionum[13],gpio.HIGH)
        tmr.alarm(1, (SecurityOffInterval*1000), 0, function() dofile("sleep.lc") end) 
    
        -- Init hodin
        i2c.setup(0,gpionum[12],gpionum[14],i2c.SLOW)
        i2c.start(0)
        i2c.address(0, 0x6F ,i2c.TRANSMITTER) -- zapis ridiciho slova / write
        i2c.write(0, 00) -- zapis adresy 
        i2c.write(0, 0x80) -- zapis sekundy + start oscilatoru
        i2c.write(0, 0x00) -- zapis minuty
        i2c.write(0, 0x00) -- zapis hodiny
        i2c.write(0, 0x08) -- den v tydnu, zapisuji abych zrustil power fail bit a zapnul Vbat 
        i2c.stop(0)
    end

-- nastaveni budiku na DOBA minut
    local function ClockAlarm(Doba)
        i2c.start(0)
        i2c.address(0, 0x6F ,i2c.TRANSMITTER) -- zapis ridiciho slova / write
        i2c.write(0, 0x0A) -- zapis adresy registr casu buzeni sekundy
        i2c.write(0, 0x00) -- zapis sekundy 0
        i2c.write(0, Doba) -- zapis minuty, pozor je to BCD
        i2c.stop(0)
        
        i2c.start(0)
        i2c.address(0, 0x6F ,i2c.TRANSMITTER) -- zapis ridiciho slova / write
        i2c.write(0, 0x07) -- zapis adresy ovladani alarmu
        i2c.write(0, 0x10) -- zapis aktivace alarmu 0
        i2c.stop(0)
        
        i2c.start(0)
        i2c.address(0, 0x6F ,i2c.TRANSMITTER) -- zapis ridiciho slova / write
        i2c.write(0, 0x0D) -- zapis adresy registr nastaveni alarmu (registr dne)
        i2c.write(0, 0x10) -- alarm minutova shoda, vymazani
        i2c.stop(0)
    end    

-- vypsani registru RTC, tech na zacatku co nas zajimaji
    local function ClockReadAll() -- DEBUG vypis vsech hodnot z RTC, skoro vsech
        i2c.start(0)
        i2c.address(0, 0x6F ,i2c.TRANSMITTER) -- zapis ridiciho slova / write
        i2c.write(0, 00) -- zapis adresy 
        i2c.start(0)
        i2c.address(0, 0x6F ,i2c.RECEIVER) -- zapis ridiciho slova / write
        local data = i2c.read(0, 16) -- vyctu 16 dat
        i2c.stop(0)
    
        print("RegisterDebugRead:")
        local q
        for q=1,16,1 do
            print ((q-1)..":"..string.byte(data,q))
        end
        print(" ")
    end

-- prevede ID luatoru do 36-kove soustavy
    local function IDIn36(IN)
        local kody,out,znak="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ",""
        while (IN>0) do 
            IN,znak=math.floor(IN/36),(IN % 36)+1
            out = string.sub(kody,znak,znak)..out
        end
        return out
    end

-- uvodni mereni baterie ktere zdrzuje ale je nutne tak dlouhe (proto nazev delay)
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

            -- kontrola na nizke napeti - pripraveno, ted nevim jak to chci presne ridit podle ktereho napeti
            -- local voltage = AnalogMaximum * 0.003436
            -- if (voltage < 2.00) then -- mene nez 2V
            -- ClockAlarm(ReportIntervalLowBat) -- nastaveni budiky na dlouhou dobu
            -- end

            -- a spoustim hlavni proces vyhledani AP
            Fields[ReportFieldPrefix.."tb"] = tmr.now()/1000
            tmr.alarm(0, 10, 0,  function() dofile("start.lc") end)
        end
    end

-- spusteni mereni baterie a nastaveni RTC
    local function InitDelayStart()
    	ClockInit() -- re-inicializace RTC
	    ClockAlarm(ReportInterval) -- nastaveni budiky na standardni dobu
        adc.read(0) -- nekdy prvni prevod vrati nesmysl
        InitStartTime = tmr.now()
        InitDelayTime = 1000000 -- X sekundy limit, pak se s merenim baterie skonci a jde se hledat AP
        math.randomseed(tmr.now())
        AnalogMinimum = 1024
        AnalogMaximum = 0
        AnalogCount = 1
        InitDelay() -- zamosevolajici funkce se musi aspon jednou spustit
    end

-- konstanty pro reportovani
    local ReportInterval = 0x10 -- minut, v BCD!!!
    local ReportIntervalLowBat = 0x59 -- hodnota pro nizkou baterii (60 minut nejde, tak 59)
    ReportIntervalNoRTC = 5 -- v pripade ze nepujde vypnout zdroj, mel by byt jiny aby se na cloudu poznalo ze je problem
    local SecurityOffInterval = 35 -- sekund na vsechno, zmereni, preneseni, potvrzeni
    ReportNode = "3"
    ReportFieldPrefix = IDIn36(node.chipid()).."_"
    file.open("apikey.ini", "r") -- soubor tam musi byt a ze neni neosetruji
        ReportApiKey = file.readline() -- soubor nesmi obsahovat ukonceni radku, jen apikey!!!
    file.close()
    Fields = {}
    Debug = 0
    if (file.open("debug.ini", "r") ~= nil) then Debug = 1 end -- debuguje se jen kdyz je soubor debug.ini
    
    -- nastaveni pinu zde zadna nejsou, protoze je to pevny HW a neocekava se nutnost zmeny

    
print("Measuring battery.") 
InitDelayStart() -- Spustim uvodni X sekundove mereni baterie
