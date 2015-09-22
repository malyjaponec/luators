tmr.stop(0)

print("Waiting for reboot")

tmr.alarm(0, 5000, 0, function() node.restart() end)

