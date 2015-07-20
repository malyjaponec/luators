ReportInterval = 300

local time = (ReportInterval * 1000*1000) - tmr.now() - 100000
if time < 5000000 then time = 5000000 end
print("Sleeping for "..(time/1000000).." s")
--tmr.alarm(0, 100, 0, function() node.dsleep(time, 2) end)
tmr.wdclr()
tmr.stop(0)
print(node.heap())
node.dsleep(time, 1)
-- 2 bez kalibrace RF
-- 1 s kalibraci RF
-- 0 zalezi na bajtu 108, nevim co to znamena
-- 4 RF po startu vypnute

