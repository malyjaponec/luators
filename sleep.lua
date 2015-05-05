-- prepare reboot
local time = (CloudInterval * 1000) - (tmr.now()/1000)
if time < 15000 then time = 15000 end
tmr.alarm(0, time, 0, function() node.restart() end)
print("Restart scheduled in "..(time/1000).." s") 
