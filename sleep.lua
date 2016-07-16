-- sleep.lua    
    
    tmr.stop(0)
    tmr.stop(1)
    tmr.stop(2)
    tmr.stop(3)
    tmr.stop(4)
    tmr.stop(5)
    tmr.stop(6)

-- vypocet casu
    local RI = ReportInterval
    if ReportFast == 1 then RI = ReportIntervalFast end
    local time = (RI * 1000*1000) - tmr.now()
-- kontrola zda cas neni delsi nez je report interval, vzdy musi byt mensi, pokud je vetsi nastavi se report interval
    if time < ((RI-30) * 1000*1000) then time = ((RI-30) *1000*1000) end

-- usnuti nebo jen konec    
    if file.open("init.lua", "r") == nil then -- soubor neexistuje, rucni start, nespime, ladime kod
        print("END ("..(time/1000000).."s)")
    else
        print("Sleeping for "..(time/1000000).." s") -- tiskne se vzdy i kdyz je vypnuty debug
        node.dsleep(time, 1)
    end
