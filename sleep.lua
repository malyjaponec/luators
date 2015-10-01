tmr.stop(0)
tmr.wdclr()
print(node.heap())
print("Switching power off...")
gpio.write(gpionum[13],gpio.LOW) -- timto se vypnu
tmr.delay(500000) -- cekam 0,5s
print("Power gone, still running???, setting up emergency reboot in 60s...")
tmr.alarm(0, 60000, 1, function() node.restart() end)
