-- measure.lua
    tmr.stop(0)

-- Nastaveni dalas
    -- sbernice 1 - napajene paralelni mereni
    -- sbernice 2 - napajene paralelni mereni
    -- sbernice 3 - phantom sekvencni mereni cidlo po cidle s nizsi presnosti
    local sbernice1 = 12 -- 12
    local sbernice2 = 2 -- 2
    local sbernice3 = 13-- 13
    local presnost_phantom = 2
    local delay_phantom = 400000
    
-- Nastavedi digital IO
    local ReadScan = {[14] = "d14", [16] = "d16", [5] = "d5", [4] = "d4"}

    gpio.mode(gpionum[sbernice1], gpio.INPUT, gpioFLOAT) 
    gpio.mode(gpionum[sbernice1], gpio.OUTPUT) 
    gpio.write(gpionum[sbernice1], gpio.HIGH)
    gpio.mode(gpionum[sbernice2], gpio.INPUT, gpioFLOAT) 
    gpio.mode(gpionum[sbernice2], gpio.OUTPUT) 
    gpio.write(gpionum[sbernice2], gpio.HIGH)
    gpio.mode(gpionum[sbernice3], gpio.INPUT, gpioFLOAT) 
    gpio.mode(gpionum[sbernice3], gpio.OUTPUT) 
    gpio.write(gpionum[sbernice3], gpio.HIGH)
   
-- Funkce na prevod cisla na hex
function DEC_HEX(IN,COUNT)
    local B,K,OUT,D=16,"0123456789ABCDEF","",0
    while COUNT>0 do
        COUNT=COUNT-1
        IN,D=math.floor(IN/B),(IN % B)+1
        OUT=string.sub(K,D,D)..OUT
    end
    return OUT
end

-- Knihovna na cteni z dalasu
    t = require("ds18b20")

-- Teploty z ds18b20 - zbrenice 1
    t.setup(gpionum[sbernice1],3)
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
    collectgarbage()

-- Teploty z ds18b20 - sbernice 2
    t.setup(gpionum[sbernice2],3)
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
        end
    end
    collectgarbage()

    local totaldelay = 750000
    tmr.wdclr()
    
-- Teploty z ds18b20 - zbrenice 3 mereni i vycitani
    t.setup(gpionum[sbernice3],presnost_phantom)
    local addrs3 = t.addrs() -- nacte adresy do lokalniho pole
    local senzorcount3 = 0
    if (addrs3 ~= nil) then
        senzorcount3 = table.getn(addrs3)
        print("Sbernice 3 sensors: "..senzorcount3) -- pocet senzoru 
        if (senzorcount3 > 0) then -- merit ma smysl jen pokud tam nejake senzory jsou
            -- Start measure for all sensors
            local value = ""
            local textaddr = ""
            for q,v in pairs(addrs3) do
                t.startMeasure(v)
                tmr.wdclr()
                tmr.delay(delay_phantom)
                totaldelay = totaldelay - delay_phantom
                value = t.readNumber(v)
                textaddr = ""
                local w
                for w = 1,8 do textaddr = textaddr..DEC_HEX(v:byte(w),2) end
                w = nil
                if (value ~= nil) then
                    value = value/10000
                    Fields[ReportFieldPrefix.."t"..textaddr] = value
                    if (Debug == 1) then print("s3 t"..textaddr.." = "..value) end
                    tmr.wdclr()
                else
                    print("ERROR, "..textaddr.." returned nil")
                end
                addrs3[q] = nil -- mazu z pole adresu, uz ji nebudu potrebovat
            end
            value = nil
            textaddr = nil
        end
    end
    addrs3 = nil -- rusim pole adres
    senzorcount3 = nil
    delay_phantom = nil
    collectgarbage()

-- Wait until any measure is done
    if (totaldelay >1000) then
        tmr.wdclr()
        tmr.delay(totaldelay)
        tmr.wdclr()
    end
    totaldelay = nil
    print(node.heap())

-- Vycitani hodnot - sbernice 1
    if (senzorcount1 > 0) then -- vycitam jen jestli tam neco je
        t.setup(gpionum[sbernice1],3)
        -- Read temperatures
        local value = ""
        local textaddr = ""
        for q,v in pairs(addrs1) do
            value = t.readNumber(v)
            textaddr = ""
            local w
            for w = 1,8 do textaddr = textaddr..DEC_HEX(v:byte(w),2) end
            w = nil
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
    collectgarbage()

-- Vycitani hodnot - sbernice 2
    if (senzorcount2 > 0) then 
        t.setup(gpionum[sbernice2],3)
        -- Read temperatures
        local value = ""
        local textaddr = ""
        for q,v in pairs(addrs2) do
            value = t.readNumber(v)
            textaddr = ""
            local w
            for w = 1,8 do textaddr = textaddr..DEC_HEX(v:byte(w),2) end
            w = nil
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
        value = nil
        textaddr = nil
    end
    addrs2 = nil -- rusim pole adres
    senzorcount2 = nil
    collectgarbage()
    
-- Don't forget to release library it after use
    t = nil
    ds18b20 = nil
    package.loaded["ds18b20"]=nil


-- Analogovy vstup, testovaci HW tam ma fotoodpor
    Fields[ReportFieldPrefix.."ax"] = AnalogMaximum
    Fields[ReportFieldPrefix.."an"] = AnalogMinimum


-- Pins
   local value = ""
   for q,v in pairs(ReadScan) do
        gpio.mode(gpionum[q], gpio.INPUT, gpio.FLOAT) 
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
