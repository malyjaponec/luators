-- measure.lua
    tmr.stop(0)

-- zapnu napajeni na fantom sbernici
    gpio.mode(Sb3, gpio.INPUT, gpioFLOAT) 
    gpio.mode(Sb3, gpio.OUTPUT) 
    gpio.write(Sb3, gpio.HIGH)

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

-- Vypne napejni fantom zbernice
    gpio.mode(Sb3, gpio.INPUT, gpioFLOAT) 
    gpio.mode(Sb3, gpio.OUTPUT) 
    gpio.write(Sb3, gpio.LOW)

-- Analogovy vstup, napeti baerie systemu
    Rdat[Rpref.."an"] = adc.read(0)

-- Pins
    local value = ""
    for q,v in pairs(Digi) do
        value = gpio.read(GP[q])
        Rdat[Rpref..v] = value
        if (Debug == 1) then print (v.."="..value) end
    end
    value = nil


-- uklid
  if (Debug == 1) then print("Sending initiated...") end
  tmr.alarm(0, 200, 0, function() dofile("send.lc") end)
