ReportInterval = 60

local time = (ReportInterval * 1000) - ((tmr.now() - StartTime) / 1000)
if time < 5000 then time = 5000 end

print("Waiting for "..(time/1000).." s")

tmr.stop(0)
tmr.alarm(0, time, 0, function() dofile("start.lc") end)

print(node.heap())