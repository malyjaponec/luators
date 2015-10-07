--setup.lua

-- konstanty pro reportovani
    RunCounter = 0
    ReportInterval = 5 -- sekund
    ReportNode = "2"
    ReportFieldPrefix = "solar_"
    ReportApiKey = "3e6176fb0367dfc59d914940f95c1007" -- jiffaco/emon
    Fields = {}
    
-- tento HW nic dalsiho nastavit nepotrebuje

-- a ted spustim bezne odesilani
    tmr.alarm(0, 100, 1, function() dofile("start.lc") end)
