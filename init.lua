-- init.lua
    StartTime = tmr.now()
    uart.setup(0,115200,0,1,1)
    
-- konstanty pro GPIO operace
    gpionum = {[0]=3,[1]=10,[2]=4,[3]=9,[4]=1,[5]=2,[10]=12,[12]=6,[13]=7,[14]=5,[15]=8,[16]=0}
    

-- Nastaveni sbernice s teplomery (vypnuto)
   gpio.mode(gpionum[12],  gpio.OUTPUT) -- 12
   gpio.write(gpionum[12], gpio.LOW)
   gpio.mode(gpionum[13],  gpio.OUTPUT) -- 13
   gpio.write(gpionum[13], gpio.LOW)

-- Nastaveni vsutpnich pinu   
   gpio.mode(gpionum[14], gpio.INPUT, gpio.FLOAT) -- 14
   gpio.mode(gpionum[16], gpio.INPUT, gpio.FLOAT) -- 16
   gpio.mode(gpionum[4],  gpio.INPUT, gpio.FLOAT) -- 4
   gpio.mode(gpionum[5],  gpio.INPUT, gpio.FLOAT) -- 5

-- toto cekani je pro pripad nutnosti to zastavit ale taky
-- protoze modul se sam prihlasi na wifi kdyz se necha chvili byt
    tmr.alarm(0, 2000, 0,  function() dofile("setup.lc") end)
    print(" . ")
    print(" . ")
