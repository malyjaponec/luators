local time = 10*1000
tmr.alarm(0, time, 0, function() node.restart() end)
print("Restart scheduled in "..(time/1000).." s") 
tmr.alarm(1, 3000, 0, function() node.dsleep(3000000,2) end)
print("sleep in 1 s") 

