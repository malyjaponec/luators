-- sleep.lua    
    
    tmr.stop(0)
    tmr.stop(1)
    tmr.stop(2)
    tmr.stop(3)

    -- vypocet casu
    local RI = ReportInterval
    if ReportFast == 1 then RI = ReportIntervalFast end
    
    local time = (RI * 1000*1000) - tmr.now()
    -- kontrola zda cas neni delsi nez je report interval, vzdy musi byt mensi, pokud je vetsi nastavi se report interval
    if time < ((RI-30) * 1000*1000) then time = ((RI-30) *1000*1000) end
    -- kontrolni tisk vzdy i kdyz je debug vypnuty
    print("Sleeping for "..(time/1000000).." s") 
    

--print(node.heap())
--node.dsleep(time, 1)
-- 2 bez kalibrace RF
-- 1 s kalibraci RF
-- 0 zalezi na bajtu 108, nevim co to znamena
-- 4 RF po startu vypnute

