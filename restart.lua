-- restart.lua

    Stime = tmr.now()
    Rdat = {}
    SetMAC()
    tmr.alarm(0, 100, 0, function() dofile("measure.lc") end)

