-- measure.lua

    tmr.stop(0)
    print("HEAP measure_data "..node.heap())

    t = require("ds18b20")

-- Teploty z ds18b20 - zasobnik senzory
    t.setup(gpionum[12])
    local addrs1 = t.addrs() -- nacte adresy do lokalniho pole
    if (addrs1 ~= nil) then
        print("Input 2 sensors: "..table.getn(addrs1)) -- pocet senzoru 
    
        -- Start measure for all sensors
        for q,v in pairs(addrs1) do
            t.startMeasure(v)
        end
    end

-- Teploty z ds18b20 - kolektor senzory
    t.setup(gpionum[13]) -- sbernice na gpio 13 (vedlejsi pin vedle VCC)
    local addrs2 = t.addrs() -- nacte adresy do lokalniho pole
    if (addrs2 ~= nil) then
        print("Input 1 sensors: "..table.getn(addrs2)) -- pocet senzoru 
    
        -- Start measure for all sensors
        for q,v in pairs(addrs2) do
            t.startMeasure(v)
        end
        -- power with hard 1
        gpio.mode(gpionum[13],  gpio.OUTPUT) 
        gpio.write(gpionum[13], gpio.HIGH)

        -- Wait until measure is done
        tmr.delay(750000)

        -- Read temperatures
        local value = ""
        local textaddr = ""
        for q,v in pairs(addrs2) do
            value = t.readNumber(v)
            textaddr = v:byte(1).."-"..v:byte(2).."-"..v:byte(3).."-"..v:byte(4).."-"..v:byte(5).."-"..v:byte(6).."-"..v:byte(7).."-"..v:byte(8)
            if (value ~= nil) then
                value = value/10000
                Fields[ReportFieldPrefix.."t"..textaddr] = value
                print("t"..textaddr.." = "..value)
                addrs2[q] = nil -- mazu z pole adresu, uz ji nebudu potrebovat
                tmr.wdclr()
            else
                print("ERROR, "..textaddr.." returned nil")
            end
        end
        gpio.mode(gpionum[13],  gpio.OUTPUT) 
        gpio.write(gpionum[13], gpio.HIGH)
        value = nil
        textaddr = nil
    
    end
    addrs2 = nil -- rusim pole adres
    
-- Teploty z ds18b20 - zasobnikove senzory pokracovani
    if (addrs1 ~= nil) then
        t.setup(gpionum[12])

        -- Read temperatures
        local value = ""
        local textaddr = ""
        for q,v in pairs(addrs1) do
            value = t.readNumber(v)
            textaddr = v:byte(1).."-"..v:byte(2).."-"..v:byte(3).."-"..v:byte(4).."-"..v:byte(5).."-"..v:byte(6).."-"..v:byte(7).."-"..v:byte(8)
            if (value ~= nil) then
                value = value/10000
                textaddr = v:byte(1).."-"..v:byte(2).."-"..v:byte(3).."-"..v:byte(4).."-"..v:byte(5).."-"..v:byte(6).."-"..v:byte(7).."-"..v:byte(8)
                Fields[ReportFieldPrefix.."t"..textaddr] = value
                print("t"..textaddr.." = "..value)
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

    
    -- Don't forget to release library it after use
    t = nil
    ds18b20 = nil
    package.loaded["ds18b20"]=nil

    -- Analogovy vstup, nic na nem neni zapojeno
    analog_value = (adc.read(0))
    Fields[ReportFieldPrefix.."analog"] = analog_value

-- Pins
   local ReadScan = {[14] = "GPIO14", [16] = "GPIO16", [5] = "GPIO5", [4] = "GPIO4"}
   local value = ""
   for q,v in pairs(ReadScan) do
        value = gpio.read(gpionum[q])
        Fields[ReportFieldPrefix..v] = value
   end
   value = nil
   ReadScan = nil  

-- uklid
  collectgarbage()
  tmr.alarm(0, 100, 0, function() dofile("send.lc") end)
  print("Sending initiated...")
