-- restart.lua

    Stime = tmr.now()
    Rdat = {}
    tmr.alarm(0, 100, 0, function() dofile("start.lc") end)

