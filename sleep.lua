-- sleep.lua    
    
    tmr.stop(0)
    tmr.stop(1)

-- vypocet casu
    local time = (ReportInterval * 60*1000*1000) - tmr.now()
-- kontrola zda cas neni delsi nez je report interval, vzdy musi byt mensi, pokud je vetsi nastavi se report interval
    if time < (ReportInterval * 60*1000*1000) then time = (ReportInterval * 60*1000*1000) end
-- kontrolni tisk
    if Debug == 1 then print("Sleeping for "..(time/1000000).." s") end

--print(node.heap())
node.dsleep(time, 1)
-- 2 bez kalibrace RF
-- 1 s kalibraci RF
-- 0 zalezi na bajtu 108, nevim co to znamena
-- 4 RF po startu vypnute

