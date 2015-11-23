-- init.lua
    uart.setup(0,115200,0,1,1)
    
-- konstanty pro GPIO operace
    GP = {[0]=3,[1]=10,[2]=4,[3]=9,[4]=1,[5]=2,[10]=12,[12]=6,[13]=7,[14]=5,[15]=8,[16]=0}

-- rizeni casovani
    Stime = tmr.now()

-- toto cekani je pro pripad nutnosti to zastavit ale taky
-- protoze modul se sam prihlasi na wifi kdyz se necha chvili byt
    print(" . ")
    print(" . ")
    tmr.alarm(0, 3000, 0,  function() dofile("setup.lc") end)
