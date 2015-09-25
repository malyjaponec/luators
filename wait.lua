tmr.stop(0)

local time = (ReportInterval * 1000) - ((tmr.now() - StartTime) / 1000)

if time < 1000 then time = 1000 end
if time > 10000 then time = 10000 end
print("Waiting for "..(time/1000).." s")

tmr.alarm(0, time, 0, function() dofile("restart.lc") end)

time = nil

collectgarbage()
print(node.heap())
