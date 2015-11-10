-- measure.lua
    tmr.stop(0)

-- Nastaveni
    -- sbernice 1 - zasobnik
    -- sbernice 2 - kolektor, phantom napajeni
    -- sbernice 3 - zasobnik 2
    local sbernice1 = 12
    local sbernice2 = 13
    local sbernice3 = 2
    local presnost = 3


-- Knihovna na cteni z dalasu
    t = require("ds18b20")

-- Teploty z ds18b20 - zbrenice 1
    t.setup(gpionum[sbernice1],presnost)
    local addrs1 = t.addrs() -- nacte adresy do lokalniho pole
    local senzorcount1 = 0
    if (addrs1 ~= nil) then
        senzorcount1 = table.getn(addrs1)
        print("Sbernice 1 sensors: "..senzorcount1) -- pocet senzoru 
        if (senzorcount1 > 0) then -- merit ma smysl jen pokud tam nejake senzory jsou
            -- Start measure for all sensors
            for q,v in pairs(addrs1) do
                t.startMeasure(v)
            end
        end
    end

-- Teploty z ds18b20 - zbrenice 3
    t.setup(gpionum[sbernice3],presnost)
    local addrs3 = t.addrs() -- nacte adresy do lokalniho pole
    local senzorcount3 = 0
    if (addrs3 ~= nil) then
        senzorcount3 = table.getn(addrs3)
        print("Sbernice 3 sensors: "..senzorcount3) -- pocet senzoru 
        if (senzorcount3 > 0) then -- merit ma smysl jen pokud tam nejake senzory jsou
            -- Start measure for all sensors
            for q,v in pairs(addrs3) do
                t.startMeasure(v)
            end
        end
    end

-- Teploty z ds18b20 - sbernice 2
    t.setup(gpionum[sbernice2],presnost) -- sbernice na gpio 13 (vedlejsi pin vedle VCC)
    local addrs2 = t.addrs() -- nacte adresy do lokalniho pole
    local senzorcount2 = 0
    if (addrs2 ~= nil) then
        senzorcount2 = table.getn(addrs2)
        print("Sbernice 2 sensors: "..senzorcount2) -- pocet senzoru 
        if (senzorcount2 > 0) then -- merit ma smysl jen pokud tam nejake senzory jsou
            -- Start measure for all sensors
            for q,v in pairs(addrs2) do
                t.startMeasure(v)
            end
            -- power with HIGH level
--            gpio.mode(gpionum[13],  gpio.OUTPUT) 
--            gpio.write(gpionum[13], gpio.HIGH)
        end
    end

-- Wait until any measure is done
    tmr.wdclr()
    tmr.delay(750000)
    tmr.wdclr()

-- Vycitani hodnot - sbernice 1
    if (senzorcount1 > 0) then -- vycitam jen jestli tam neco je
        t.setup(gpionum[sbernice1],presnost)
        -- Read temperatures
        local value = ""
        local textaddr = ""
        for q,v in pairs(addrs1) do
            value = t.readNumber(v)
            textaddr = v:byte(1).."-"..v:byte(2).."-"..v:byte(3).."-"..v:byte(4).."-"..v:byte(5).."-"..v:byte(6).."-"..v:byte(7).."-"..v:byte(8)
            if (value ~= nil) then
                value = value/10000
                Fields[ReportFieldPrefix.."t"..textaddr] = value
                if (Debug == 1) then print("s1 t"..textaddr.." = "..value) end
                addrs1[q] = nil -- mazu z pole adresu, uz ji nebudu potrebovat
                tmr.wdclr()
            else
                print("ERROR, "..textaddr.." returned nil")
            end
        end
        value = nil
        textaddr = nil
    end
    addrs1 = nil -- rusim pole adres
    senzorcount1 = nil

-- Vycitani hodnot - sbernice 2
    if (senzorcount2 > 0) then 
        t.setup(gpionum[sbernice2],presnost)
        -- Read temperatures
        local value = ""
        local textaddr = ""
        for q,v in pairs(addrs2) do
            value = t.readNumber(v)
            textaddr = v:byte(1).."-"..v:byte(2).."-"..v:byte(3).."-"..v:byte(4).."-"..v:byte(5).."-"..v:byte(6).."-"..v:byte(7).."-"..v:byte(8)
            if (value ~= nil) then
                value = value/10000
                Fields[ReportFieldPrefix.."t"..textaddr] = value
                if (Debug == 1) then print("s2 t"..textaddr.." = "..value) end
                addrs2[q] = nil -- mazu z pole adresu, uz ji nebudu potrebovat
                tmr.wdclr()
            else
                print("ERROR, "..textaddr.." returned nil")
            end
        end
        -- power resume, pin 13 na HIGH
        gpio.mode(gpionum[13],  gpio.OUTPUT) 
        gpio.write(gpionum[13], gpio.HIGH)
        value = nil
        textaddr = nil
    end
    addrs2 = nil -- rusim pole adres
    senzorcount2 = nil
    
-- Vycitani hodnot - sbernice 3
    if (senzorcount3 > 0) then -- vycitam jen jestli tam neco je
        t.setup(gpionum[sbernice3],presnost)
        -- Read temperatures
        local value = ""
        local textaddr = ""
        for q,v in pairs(addrs3) do
            value = t.readNumber(v)
            textaddr = v:byte(1).."-"..v:byte(2).."-"..v:byte(3).."-"..v:byte(4).."-"..v:byte(5).."-"..v:byte(6).."-"..v:byte(7).."-"..v:byte(8)
            if (value ~= nil) then
                value = value/10000
                Fields[ReportFieldPrefix.."t"..textaddr] = value
                if (Debug == 1) then print("s3 t"..textaddr.." = "..value) end
                addrs3[q] = nil -- mazu z pole adresu, uz ji nebudu potrebovat
                tmr.wdclr()
            else
                print("ERROR, "..textaddr.." returned nil")
            end
        end
        value = nil
        textaddr = nil
    end
    addrs3 = nil -- rusim pole adres
    senzorcount3 = nil
    
-- Don't forget to release library it after use
    t = nil
    ds18b20 = nil
    package.loaded["ds18b20"]=nil


-- Analogovy vstup, testovaci HW tam ma fotoodpor
    Fields[ReportFieldPrefix.."analog_max"] = AnalogMaximum
    Fields[ReportFieldPrefix.."analog_min"] = AnalogMinimum


-- Pins
   local ReadScan = {[14] = "GPIO14", [16] = "GPIO16", [5] = "GPIO5", [4] = "GPIO4"}
   local value = ""
   for q,v in pairs(ReadScan) do
        value = gpio.read(gpionum[q])
        Fields[ReportFieldPrefix..v] = value
        if (Debug == 1) then print (v.."="..value) end
   end
   value = nil
   ReadScan = nil  

-- uklid
  collectgarbage()
  tmr.alarm(0, 100, 0, function() dofile("send.lc") end)
  print("Sending initiated...")
