-- init.lua
    uart.setup(0,115200,8,uart.PARITY_NONE,uart.STOPBITS_1,1)
    
-- emergency delay, klidne dlouhej, u plynomeru fakt nezalezi kdy to zacne merit
    tmr.alarm(0, 2000, 0,  function() dofile("setup.lc") end)
    print(".")
    print(".") 
    print(".")


