-- init.lua
StartTime = tmr.now()
dofile("init_part_0.lc")
uart.setup(0,115200,0,1,1)

-- toto cekani je pro pripad nutnosti to zastavit ale taky
-- protoze modul se sam prihlasi na wifi kdyz se necha chvili byt
tmr.alarm(0, 3000, 0,  function() dofile("start.lc") end)
print(" . ")
print(" . ")
