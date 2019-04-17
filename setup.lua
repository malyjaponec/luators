--setup.lua

-- konstanty pro GPIO operace
    GP = {[0]=3,[1]=10,[2]=4,[3]=9,[4]=1,[5]=2,[10]=12,[12]=6,[13]=7,[14]=5,[15]=8,[16]=0}

-- vice vypisu
    Debug = 0
    if (file.open("debug.ini", "r") ~= nil) then Debug = 1 end

-- konstanty pro reportovani
    Rcnt = 0
    Rint = 5 -- sekund
    Rnod = "2"
    Rpref = "sh_" -- jako solar heater
    file.open("apikey.ini", "r") -- soubor tam musi byt a ze neni neosetruji
        Rapik = file.readline() -- soubor nesmi obsahovat ukonceni radku, jen apikey!!!
    file.close()
    Rdat = {}

-- konstanty a jednorazova priprava pro mereni, zavisi na measure.lua
    -- teploty
    Sb1 = GP[12] -- normalni 3 dratove dalasy
    Sb2 = GP[2]  -- normalni 3 dratove dalasy
    Sb3 = GP[13] -- zapojeni 2 dratove phantom napajeni
    Sb3p = 2 -- volba presnosti pro phantom
    Sb3d = 375000 -- odpovidajici cekaci doby
    
    gpio.mode(Sb1, gpio.INPUT, gpioFLOAT) 
    gpio.mode(Sb1, gpio.OUTPUT) 
    gpio.write(Sb1, gpio.HIGH)
    gpio.mode(Sb2, gpio.INPUT, gpioFLOAT) 
    gpio.mode(Sb2, gpio.OUTPUT) 
    gpio.write(Sb2, gpio.HIGH)
    gpio.mode(Sb3, gpio.INPUT, gpioFLOAT) 
    gpio.mode(Sb3, gpio.OUTPUT) 
    gpio.write(Sb3, gpio.HIGH)

    function AddressInHex(IN)
        local hexkody,out,high,low,w="0123456789ABCDEF",""
        for w = 1,8 do 
            high = (math.floor(IN:byte(w)) / 16) + 1
            low = ((IN:byte(w)) % 16) + 1
            out = out..string.sub(hexkody,high,high)..string.sub(hexkody,low,low)
        end
        return out
    end

    -- binarni vstupy
    Digi = {[14] = "d14", [16] = "d16", [5] = "d5", [4] = "d4"}
    
    for q,v in pairs(Digi) do
        gpio.mode(GP[q], gpio.INPUT, gpio.FLOAT) 
    end

-- a ted spustim bezne odesilani
    tmr.alarm(0, 100, 1, function() dofile("start.lc") end)
