tmr.stop(0)
tmr.stop(1)

print("Waiting for reboot")

tmr.alarm(0, 1000, 0, function() node.restart() end)

