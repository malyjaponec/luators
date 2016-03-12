-- init.lua
    StartTime = tmr.now()
    --uart.setup(0,115200,0,1,1)
    
-- konstanty pro GPIO operace
   
-- toto cekani je pro pripad nutnosti to zastavit ale taky
-- protoze modul se sam prihlasi na wifi kdyz se necha chvili byt
    print(" . ")
    print(" . ")

--  tmr.alarm(0, 10, 0,  function() dofile("setup.lc") end)
dofile("setup.lc")
