--setup.lua

-- konstanty pro reportovani
    local ReportInterval = 15 -- minut
    local SecurityOffInterval = 33 -- sekund
    ReportNode = "3"
    ReportFieldPrefix = "venku_"
    ReportApiKey = "***REMOVED***" -- jiffaco/emon

-- nastaveni hodin
local function ClockInit()
    -- Zapnu pridrzeni napajeni, jinak by se po resetu hodin vypnul, a nastavim bezpecnostni interval na vypnuti, kdyby se to zacyklovalo
    gpio.mode(gpionum[13],gpio.OUTPUT)
    gpio.write(gpionum[13],gpio.HIGH)
    tmr.alarm(1, (SecurityOffInterval*1000), 0, function() gpio.write(gpionum[13],gpio.LOW) end) 

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

        -- a spoustim hlavni proces vyhledani AP
        tmr.alarm(0, 100, 0,  function() dofile("start.lc") end)
    end
end

local function InitDelayStart()
    ClockInit() -- init
    ClockAlarm(ReportInterval) -- nastaveni budiky
    InitDelayTime = 3000
    print("AnalogMeasuring for "..(InitDelayTime/1000).." s")
    InitDelayStep = 20
    AnalogMinimum = 1024
    AnalogMaximum = 0
    InitDelay()
end
    
-- Jako prvni merim napeti baterie
InitDelayStart()
