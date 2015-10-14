--setup.lua

-- konstanty pro reportovani
    ReportInterval = 15 -- minut
    ReportNode = "3"
    ReportFieldPrefix = "sklenik_"
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
    InitDelayTime = 3000
    print("AnalogMeasuring for "..(InitDelayTime/1000).." s")
    InitDelayStep = 20
    AnalogMinimum = 1024
    AnalogMaximum = 0
    adc.read(0) -- nekdy to cte maxiumu jako 1024 coz nejspis je ze prvni prevod se nepovede, tohle to resi
    InitDelay()
end
    
-- Jako prvni merim napeti baterie
    InitDelayStart()
