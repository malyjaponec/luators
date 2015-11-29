--setup.lua

-- prevede ID luatoru do 36-kove soustavy
    function IDIn36(IN)
        local kody,out,znak="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ",""
        while (IN>0) do 
            IN,znak=math.floor(IN/36),(IN % 36)+1
            out = string.sub(kody,znak,znak)..out
        end
        return out
    end
    Rpref = IDIn36(node.chipid()).."_"

-- vice vypisu
    Debug = 0
    if (file.open("debug.ini", "r") ~= nil) then Debug = 1 end

-- konstanty pro reportovani
    Rcnt = 0
    Rint = 5 -- sekund
    Rnod = "4"
    file.open("apikey.ini", "r") -- soubor tam musi byt a ze neni neosetruji
        Rapik = file.readline() -- soubor nesmi obsahovat ukonceni radku, jen apikey!!!
    file.close()
    Rdat = {}

-- konstanty a jednorazova priprava pro mereni, zavisi na measure.lua
    -- teploty
    Sb1 = GP[4] -- normalni 3 dratove dalasy
        -- pul up je realizovany tim ze je mezi GPIO4 a GPIO5, takze aby to chodilo
        -- je potreba GPIO5 dat na tvrdou 1
        gpio.mode(GP[5], gpio.OUTPUT) 
        gpio.write(GP[5], gpio.HIGH)
    Sb2 = GP[14]  -- normalni 3 dratove dalasy
    Sb3 = GP[15] -- zapojeni 2 dratove phantom napajeni
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
    Digi = {}
    
    for q,v in pairs(Digi) do
        gpio.mode(GP[q], gpio.INPUT, gpio.FLOAT) 
    end

-- a ted spustim bezne odesilani
    tmr.alarm(0, 100, 1, function() dofile("start.lc") end)
