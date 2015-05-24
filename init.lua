-- init.lua
dofile("init_part_0.lc");
tmr.alarm(0, 3000, 0, function() dofile("start.lc") end)
