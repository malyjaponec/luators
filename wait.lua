tmr.stop(0)

local ReportInterval = 3

print("DEBUG: time now = "..tmr.now())
print("DEBUG: start time = "..StartTime)

local time = (ReportInterval * 1000) - ((tmr.now() - StartTime) / 1000)
if time < 100 then time = 100 end
-- nemam lepsi metodu jak zabranit chybe pri pretoceni citace nez omezi cekani na maximalni teoreticky mozny interval
if time > 3000 then time = 3000 end

print("Waiting for "..(time).." ms")

tmr.alarm(0, time, 0, function() dofile("restart.lc") end)

time = nil
ReportInterval = nil

collectgarbage()
print(node.heap())
