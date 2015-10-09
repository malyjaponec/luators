--setup.lua

   function InitDelay()
        local AnalogValue = adc.read(0)
        if (AnalogValue > AnalogMaximum) then 
            AnalogMaximum = AnalogValue
        end
        if (AnalogValue < AnalogMinimum) then 
            AnalogMinimum = AnalogValue
        end
        InitDelayTime = InitDelayTime - InitDelayStep
        if (InitDelayTime > InitDelayStep) then
            tmr.alarm(0, InitDelayStep, 0,  function() InitDelay() end)
        else
            InitDelayTime = nil
            InitDelayStep = nil
            tmr.alarm(0, 100, 0,  function() dofile("start.lc") end)
        end
    end
    function InitDelayStart()
        InitDelayTime = 2000
        print("AnalogMeasuring for "..(InitDelayTime/1000).." s")
        InitDelayStep = 20
        AnalogMinimum = 1024
        AnalogMaximum = 0
        InitDelay()
    end
    
-- konstanty pro reportovani
    RunCounter = 0
    ReportInterval = 5 -- sekund
    ReportNode = "1"
    ReportFieldPrefix = "tester1_"
    ReportApiKey = "***REMOVED***" -- jiffaco/emon
    Fields = {}
    InitDelayStart()
    
-- tento HW nic dalsiho nastavit nepotrebuje

-- a ted spustim bezne odesilani
    tmr.alarm(0, 100, 1, function() dofile("start.lc") end)
