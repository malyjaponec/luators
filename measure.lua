-- measure.lua
    tmr.stop(0)
      
-- Knihovna na cteni z dalasu
    t = require("ds18b20")
    local q,v

-- Teploty z ds18b20 - zbrenice 1
    t.setup(Sb1,3)
    local a1 = t.addrs() -- nacte adresy do lokalniho pole
    local sc1 = 0
    if (a1 ~= nil) then
        sc1 = table.getn(a1)
        print("S1: "..sc1) -- pocet senzoru 
        if (sc1 > 0) then -- merit ma smysl jen pokud tam nejake senzory jsou
            -- Start measure for all sensors
            for q,v in pairs(a1) do
                t.startMeasure(v)
            end
        end
    end

-- Teploty z ds18b20 - sbernice 2
    t.setup(Sb2,3)
    local a2 = t.addrs() -- nacte adresy do lokalniho pole
    local sc2 = 0
    if (a2 ~= nil) then
        sc2 = table.getn(a2)
        print("S2: "..sc2) -- pocet senzoru 
        if (sc2 > 0) then -- merit ma smysl jen pokud tam nejake senzory jsou
            -- Start measure for all sensors
            for q,v in pairs(a2) do
                t.startMeasure(v)
            end
        end
    end

    local tdelay = 750000
    
-- Teploty z ds18b20 - zbrenice 3 mereni i vycitani
    t.setup(Sb3,Sb3p)
    local a3 = t.addrs() -- nacte adresy do lokalniho pole
    local sc3 = 0
    if (a3 ~= nil) then
        sc3 = table.getn(a3)
        print("S3: "..sc3) -- pocet senzoru 
        if (sc3 > 0) then -- merit ma smysl jen pokud tam nejake senzory jsou
            -- Start measure for all sensors
            for q,v in pairs(a3) do
                t.startMeasure(v)
                tmr.delay(Sb3d)
                tdelay = tdelay - Sb3d
            end
        end
    end

-- Wait until any measure is done
    if (tdelay >1000) then
        tmr.delay(tdelay)
    end
    totaldelay = nil

-- Vycitani hodnot - sbernice 3
    if (sc3 > 0) then -- vycitam jen jestli tam neco je
        t.setup(Sb3,Sb3p) --stale zustava od mereni ale nefunguje to musi se volat znova
        -- Read temperatures
        local value = ""
        local textaddr = ""
        for q,v in pairs(a3) do
            value = t.readNumber(v)
            textaddr = AddressInHex(v)
            if (value ~= nil) then
                value = value/10000
                Rdat[Rpref.."t"..textaddr] = value
                if (Debug == 1) then print("s3 t"..textaddr.." = "..value) end
                a3[q] = nil -- mazu z pole adresu, uz ji nebudu potrebovat
            else
                print("ERROR, "..textaddr.." returned nil")
            end
        end
        value = nil
        textaddr = nil
    end
    a3 = nil -- rusim pole adres
    sc3 = nil

-- Vycitani hodnot - sbernice 1
    if (sc1 > 0) then -- vycitam jen jestli tam neco je
        t.setup(Sb1,3)
        -- Read temperatures
        local value = ""
        local textaddr = ""
        for q,v in pairs(a1) do
            value = t.readNumber(v)
            textaddr = AddressInHex(v)
            if (value ~= nil) then
                value = value/10000
                Rdat[Rpref.."t"..textaddr] = value
                if (Debug == 1) then print("s1 t"..textaddr.." = "..value) end
                a1[q] = nil -- mazu z pole adresu, uz ji nebudu potrebovat
            else
                print("ERROR, "..textaddr.." returned nil")
            end
        end
        value = nil
        textaddr = nil
    end
    a1 = nil -- rusim pole adres
    sc1 = nil

-- Vycitani hodnot - sbernice 2
    if (sc2 > 0) then 
        t.setup(Sb2,3)
        -- Read temperatures
        local value = ""
        local textaddr = ""
        for q,v in pairs(a2) do
            value = t.readNumber(v)
            textaddr = AddressInHex(v)
            w = nil
            if (value ~= nil) then
                value = value/10000
                Rdat[Rpref.."t"..textaddr] = value
                if (Debug == 1) then print("s2 t"..textaddr.." = "..value) end
                a2[q] = nil -- mazu z pole adresu, uz ji nebudu potrebovat
            else
                print("ERROR, "..textaddr.." returned nil")
            end
        end
        value = nil
        textaddr = nil
    end
    a2 = nil -- rusim pole adres
    sc2 = nil
    
-- Don't forget to release library it after use
    t = nil
    ds18b20 = nil
    package.loaded["ds18b20"]=nil
    q,v = nil,nil


-- Analogovy vstup, neni zapojen
    Rdat[Rpref.."an"] = adc.read(0)


-- Pins
    local value = ""
    for q,v in pairs(Digi) do
        value = gpio.read(GP[q])
        Rdat[Rpref..v] = value
        if (Debug == 1) then print (v.."="..value) end
    end
    value = nil

-- Barometr
    bmp085.init(baroD,baroC)
    local value,valuet = 0,0
    for q = 1,30 do
        value = value + (bmp085.pressure() / 100)
        valuet =  valuet + (bmp085.temperature() / 10)
        tmr.delay(33)
        tmr.wdclr()
    end
    value,valuet = value/10,valuet/10

    if Debug == 1 then 
        print ("tlak="..value)
        print ("teplota="..valuet)
    end
    Rdat[Rpref.."tlak"] = value
    Rdat[Rpref.."teplota_t"] = valuet
    value,valuet = nil,nil
-- uklid
  tmr.alarm(0, 10, 0, function() dofile("send.lc") end)
