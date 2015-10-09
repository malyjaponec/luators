-- init.lua
    StartTime = tmr.now()
    uart.setup(0,115200,0,1,1)

-- konstanty pro GPIO operace
    gpionum = {[0]=3,[1]=10,[2]=4,[3]=9,[4]=1,[5]=2,[10]=12,[12]=6,[13]=7,[14]=5,[15]=8,[16]=0}

-- Zapnu pridrzeni napajeni, jinak by se po resetu hodin vypnul
    gpio.mode(gpionum[13],gpio.OUTPUT)
    gpio.write(gpionum[13],gpio.HIGH)

-- toto cekani je pro pripad nutnosti to zastavit ale taky
-- protoze modul se sam prihlasi na wifi kdyz se necha chvili byt
    tmr.alarm(0, 10, 0,  function() dofile("setup.lc") end)
    print(" . ")
    print(" . ")
