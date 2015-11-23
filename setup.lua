--setup.lua

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

-- konstanty a jednorazova priprava pro snimani opentherm
    -- teploty
    Din = GP[13] --
    Dout = GP[12] -- 
    
    gpio.mode(Din, gpio.INPUT, gpioFLOAT) 
    gpio.mode(Dout, gpio.INPUT, gpioFLOAT) 

    -- binarni vstupy
    --Digi = {[14] = "d14", [16] = "d16", [5] = "d5", [4] = "d4"}
    Digi = {}
    
    for q,v in pairs(Digi) do
        gpio.mode(GP[q], gpio.INPUT, gpio.FLOAT) 
    end


-- pomocne funkce globalni
    -- prevede adresu DS18B20 do hexadecimalniho tvaru (8 bajtu)
    function AddressInHex(IN)
        local hexkody,out,high,low,w="0123456789ABCDEF",""
        for w = 1,8 do 
            high = (math.floor(IN:byte(w)) / 16) + 1
            low = ((IN:byte(w)) % 16) + 1
            out = out..string.sub(hexkody,high,high)..string.sub(hexkody,low,low)
        end
        return out
    end

    -- prevede ID luatoru do 36-kove soustavy
    function IDIn36(IN)
        local kody,out,znak="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ",""
        while (IN>0) do 
            IN,znak=math.floor(IN/36),(IN % 36)+1
            out = string.sub(kody,znak,znak)..out
        end
        return out
    end

-- a ted spustim bezne odesilani
    --tmr.alarm(0, 100, 1, function() dofile("start.lc") end)
    if (file.open("scan.lua", "r") ~= nil) then 
        tmr.alarm(0, 100, 1, function() dofile("scan.lc") end)
    else
        print("scan.lc missing")
    end
