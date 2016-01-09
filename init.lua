-- init.lua
    uart.setup(0,115200,0,1,1)
    --uart.setup(0,9600,0,1,1)

    
-- emergency delay
    tmr.alarm(0, 2000, 0,  function() dofile("setup.lc") end)
    print(".")
    print(".") 
    print(".")