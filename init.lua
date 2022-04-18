-- init.lua
    uart.setup(0,115200,8,uart.PARITY_NONE,uart.STOPBITS_1,1)
    
-- emergency delay, je rozumne si ho tam nechat aspon 1s aby se to dalo v nouzi zastavit
    tmrS = tmr.create()
	tmrS:alarm(2000, tmr.ALARM_SINGLE,  function() dofile("setup.lc") end)
	tmrS = nil
    print(".")
    print(".") 
    print(".")


