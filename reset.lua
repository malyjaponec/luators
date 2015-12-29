tmr.stop(0)
tmr.stop(1)
tmr.stop(2)
tmr.stop(3)
tmr.stop(4)
tmr.stop(5)

print("Waiting for reboot")

tmr.alarm(0, 1000, 0, function() node.restart() end)

