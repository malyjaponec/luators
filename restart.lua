StartTime = tmr.now()
tmr.alarm(0, 100, 0, function() dofile("start.lc") end)