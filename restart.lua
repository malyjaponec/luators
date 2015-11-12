-- restart.lua
    StartTime = tmr.now()
    Fields = {}
    tmr.alarm(0, 200, 0, function() dofile("start.lc") end)

