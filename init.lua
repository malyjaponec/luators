-- init.lua
CloudInterval = 60 -- sekund

dofile("init_pins.lc") -- prenastaveni pinu po resetu
tmr.alarm(0, 5000, 0, function() dofile("start.lc") end) -- zpozdeny start
