-- restart.lua    
    
    tmr.stop(0)
    tmr.stop(1)
    tmr.stop(2)
    tmr.stop(3)
    tmr.stop(4)
    tmr.stop(5)
    tmr.stop(6)
    print("Reboot") -- tiskne se vzdy i kdyz je vypnuty debug    
    node.restart()
