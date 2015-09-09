-- init.lua
StartTime = tmr.now()
uart.setup(0,115200,0,1,1)
dofile("init_part_0.lc")
RunCounter = 0
ReportInterval = 60

-- toto cekani je pro pripad nutnosti to zastavit ale taky
-- protoze modul se sam prihlasi na wifi kdyz se necha chvili byt
tmr.alarm(0, 3000, 0,  function() dofile("start.lc") end)
print(" . ")
print(" . ")
