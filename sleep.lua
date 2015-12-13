-- sleep.lua    
    
    tmr.stop(0)
    tmr.stop(1)

    tmr.wdclr()
    
    print("OFF")
    gpio.write(gpionum[13],gpio.LOW) -- timto se vypnu
    tmr.delay(500000) -- cekam 0,5s na vypnuti
    print("Power gone, still running???...")

-- nouzove usnuti nelze realizovat protoze neni propojen reset a GPIO16
-- Nouzove usnuti, neresim jak dlouho luator bezel, usinam na definovany cas
-- interval probouzeni bude vyssi o dobu akci provadenych 
--    local time = (ReportIntervalNoRTC*60000000)
--    print("Emergency sleep ")
--    node.dsleep(time, 1)

-- misto nouzoveho usnuti restartuji modul za 60s, nic jineho se 
-- s tim asi udelat neda, jedine tim ze budou chodit data casto
-- poznam ze je neco spatne
    tmr.alarm(0, 60000, 1, function() node.restart() end)