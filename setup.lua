--setup.lua
   
-- konstanty pro reportovani
    RunCounter = 0
    ReportInterval = 5 -- sekund
    ReportNode = "2"
    ReportFieldPrefix = "sh_" -- jako solar heater
    ReportApiKey = "***REMOVED***" -- jiffaco/emon
    Fields = {}
    Debug = 1
    
-- tento HW nic dalsiho nastavit nepotrebuje

-- a ted spustim bezne odesilani
    tmr.alarm(0, 100, 1, function() dofile("start.lc") end)
