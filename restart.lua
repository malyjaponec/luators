-- restart.lua
    StartTime = tmr.now()
    Fields = {}
    tmr.alarm(0, 100, 0, function() dofile("start.lc") end)
