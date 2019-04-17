-- init.lua
    -- ne seriovou linku nemenim, nedela to dobrotu 
    
-- rizeni casovani
    Stime = tmr.now()

-- toto cekani je pro pripad nutnosti to zastavit ale taky
-- protoze modul se sam prihlasi na wifi kdyz se necha chvili byt
    print(" . ")
    print(" . ")
    tmr.alarm(0, 2000, 0,  function() dofile("setup.lc") end)
