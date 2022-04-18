--tmr.stop(0)
--tmr.stop(1)
--tmr.stop(2)
--tmr.stop(3)
--tmr.stop(4)
--tmr.stop(5)

rgb.set("white")

print("restart")
--tmrX = tmr.create()
--tmrX:alarm(250, tmr.ALARM_SINGLE, function() node.restart() end)
node.restart()

