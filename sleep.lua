-- sleep.lua    
    
    tmr.stop(0)
    tmr.stop(1)

    tmr.wdclr()
    
    print("OFF")
    gpio.write(gpionum[13],gpio.LOW) -- timto se vypnu
    tmr.delay(500000) -- cekam 0,5s na vypnuti
    print("Power gone, still running???...")



-- Nouzove usnuti, neresim jak dlouho luator bezel, usinam na definovany cas
-- interval probouzeni bude vyssi o dobu akci provadenych 
    local time = (ReportIntervalNoRTC*60000000)
    print("Emergency sleep ")
    node.dsleep(time, 1)

-- 2 bez kalibrace RF
-- 1 s kalibraci RF
-- 0 zalezi na bajtu 108, nevim co to znamena
-- 4 RF po startu vypnute

    -- dofile(sende.lc)
    -- zde je vize: spusti se druhe spojeni na cloud
    -- preda se promenna typu RTC_error = 1, v prnim prenosu se prenasi 0 nebo se neprenasi
    -- usne na stejnou dobu jako normalne ale s pomoci deep sleepu zavolanim sleape.lc z sende.lc
