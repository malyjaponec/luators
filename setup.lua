--setup.lua

-- konstanty pro reportovani
    RunCounter = 0
    ReportInterval = 5 -- sekund
    ReportNode = "2"
    ReportFieldPrefix = "solar_"
    ReportApiKey = "***REMOVED***" -- jiffaco/emon
    Fields = {}
    
-- tento HW nic dalsiho nastavit nepotrebuje

-- a ted spustim bezne odesilani
    tmr.alarm(0, 100, 1, function() dofile("start.lc") end)
