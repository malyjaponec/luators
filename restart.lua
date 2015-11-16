-- restart.lua
    StartTime = tmr.now()
    Fields = {}
    tmr.alarm(0, 300, 0, function() dofile("start.lc") end)

