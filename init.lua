-- init.lua
    uart.setup(0,115200,8,uart.PARITY_NONE,uart.STOPBITS_1,1)
    
-- emergency delay, je rozumne si ho tam nechat aspon 1s aby se to dalo v nouzi zastavit
    tmr.alarm(0, 1000, 0,  function() dofile("setup.lc") end)
    print(".")
    print(".") 
    print(".")


