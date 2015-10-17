--setup.lua

-- konstanty pro reportovani
    ReportInterval = 15 -- minut
    ReportNode = "3"
    ReportFieldPrefix = "foliak_"
    ReportApiKey = "3e6176fb0367dfc59d914940f95c1007" -- jiffaco/emon
    Fields = {}
    
-- funkce 

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
    gpio.mode(gpionum[14],gpio.OUTPUT)
    gpio.write(gpionum[14],gpio.HIGH) -- prijim fotoodpor na + (je to pres diodu)
    adc.read(0) -- nekdy prvni prevod vrati nesmysl
    InitDelayTime = 3000
    print("AnalogMeasuring for "..(InitDelayTime/1000).." s")
    InitDelayStep = 20
    AnalogMinimum = 1024
    AnalogMaximum = 0
    InitDelay()
end
    
-- Jako prvni merim napeti baterie
    InitDelayStart()
