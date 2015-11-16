-- wait.lua
    tmr.stop(0)
    tmr.stop(1)
    
-- vypoctu cekaci cas

    local time = (Rint * 1000) - ((tmr.now() - Stime) / 1000)
    if (Debug == 1) then print("Should wait for "..(time/1000).." s") end

-- kontrola na to jestli to dava smysl
    if time < 250 then time = 100 end -- vzdycky si na da pauzu
    if time > (Rint*1000) then time = 100 end -- kdyz se cela dele nez je report interval je to chyba v aritmetice, cekam minimalni cas

-- nastavim cekani
    print("Waiting for "..(time/1000).." s") -- dalsich 250ms ceka restart skript
    tmr.alarm(0, time, 0, function() dofile("restart.lc") end)

-- uklid
    time = nil
    print(node.heap())
    
