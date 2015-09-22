tmr.stop(0)

local ReportInterval = 10

local time = (ReportInterval * 1000) - ((tmr.now() - StartTime) / 1000)

if time < 3000 then time = 5000 end
if time > 10000 then time = 10000 end
print("Waiting for "..(time/1000).." s")

tmr.alarm(0, time, 0, function() dofile("start.lc") end)

time = nil
ReportInterval = nil

collectgarbage()
print(node.heap())
