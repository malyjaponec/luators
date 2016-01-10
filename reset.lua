--tmr.stop(0)
--tmr.stop(1)
--tmr.stop(2)
--tmr.stop(3)
--tmr.stop(4)
--tmr.stop(5)

rgb.set("white")

print("restart")
--tmr.alarm(0, 250, 0, function() node.restart() end)
node.restart()

