-- measure.lua

    tmr.stop(0)
    print("HEAP measure_data "..node.heap())

    gpio.write(gpionum[12], gpio.HIGH) -- napajeni
 
    t = require("ds18b20")

-- Tepoloty z ds18b20 - lokalni senzory
    t.setup(gpionum[13]) -- sbernice na gpio 13 (vedlejsi pin vedle VCC)
    local addrs = t.addrs() -- nacte adresy do lokalniho pole
    if (addrs ~= nil) then
        print("Total DS18B20 sensors: "..table.getn(addrs)) -- pocet senzoru 
    
        -- Start measure for all sensors
        for q,v in pairs(addrs) do
            t.startMeasure(v)
        end
        -- Wait until measure is done
    --        tmr.wdclr()
        tmr.delay(750000)
    --        tmr.wdclr()
        -- Read temperatures
        local value = ""
        local textaddr = ""
        for q,v in pairs(addrs) do
            value = t.readNumber(v)/10000
            textaddr = v:byte(1).."-"..v:byte(2).."-"..v:byte(3).."-"..v:byte(4).."-"..v:byte(5).."-"..v:byte(6).."-"..v:byte(7).."-"..v:byte(8)
            Fields[ReportFieldPrefix.."t"..textaddr] = value
            print("t"..textaddr.." = "..value)
            addrs[q] = nil -- mazu z pole adresu, uz ji nebudu potrebovat
            tmr.wdclr()
        end
        value = nil
        textaddr = nil

        if (0 == table.getn(addrs)) then -- Zadny detekovany teplomer
            Fields[ReportFieldPrefix.."t0-0-0-0-0-0-0-1"] = math.random(0,100)
            Fields[ReportFieldPrefix.."t0-0-0-0-0-0-0-2"] = math.random(20,60)
            Fields[ReportFieldPrefix.."t0-0-0-0-0-0-0-3"] = math.random(-20,30)
        end
    end
    addrs = nil -- rusim pole adres
    
    -- Don't forget to release library it after use
    t = nil
    ds18b20 = nil
    package.loaded["ds18b20"]=nil

    -- vypnuti napajeni teplomeru
    gpio.write(gpionum[12], gpio.LOW) -- tento pin slouzi k napajeni 
    gpio.write(gpionum[13], gpio.LOW) -- vypnuti i datoveho pinu, zustava jinak svitit modra led na kitu, na finalu to zbytecne zere, funce ow.depower nefunguje

-- Analogovy vstup, nic na nem neni zapojeno
    analog_value = (adc.read(0))
    Fields[ReportFieldPrefix.."analog"] = analog_value

-- Pins
   local ReadScan = {[14] = "collector_pump", [16] = "transfer_pump", [5] = "exchanger", [4] = "NC"}
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
