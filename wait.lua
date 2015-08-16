tmr.stop(0)

local ReportInterval = 3

local time = (ReportInterval * 1000) - ((tmr.now() - StartTime) / 1000)
if time < 100 then time = 100 end

print("Waiting for "..(time).." ms")

tmr.alarm(0, time, 0, function() dofile("restart.lc") end)

time = nil
ReportInterval = nil

collectgarbage()
print(node.heap())
