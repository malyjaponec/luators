-- wait.lua
    tmr.stop(0)
    tmr.stop(1)
    
-- vypoctu cekaci cas

    local time = (ReportInterval * 1000) - ((tmr.now() - StartTime) / 1000)

-- kontrola na to jestli to dava smysl
    if time < 200 then time = 200 end -- vzdycky si na da pauzu
    if time > (ReportInterval*1000) then time = (ReportInterval*500) end -- kdyz se cela dele nez je report interval je to chyba v aritmetice

-- nastavim cekani
    print("Waiting for "..(time/1000).." s")
    tmr.alarm(0, time, 0, function() dofile("restart.lc") end)

-- uklid
    time = nil
    collectgarbage()
    print(node.heap())
