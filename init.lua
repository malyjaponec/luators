-- init.lua
    --uart.setup(0,115200,8,uart.PARITY_NONE,uart.STOPBITS_1,1)
    
-- emergency delay
    tmr.alarm(0, 100, 0,  function() dofile("setup.lc") end)
    print(".")
    print(".") 
    print(".")


