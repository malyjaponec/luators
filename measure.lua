tmr.stop(0)
print("HEAP measure_data "..node.heap())

Fields = {}

-- Tepolot z ds18b20
    t = require("ds18b20")
    
    t.setup(7) -- sbernice na gpio 13 (vedlejsi pin vedle VCC)
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
        for q,v in pairs(addrs) do
            value = t.readNumber(v)
            Fields["temp"..addrs[q]] = value
            print("temp"..addrs[q].." = "..value)
            addrs[q] = nil -- mazu z pole adresu, uz ji nebudu potrebovat
            tmr.wdclr()
        end
        value = nil
    
    -- nefunguje teplomer, simuluju to
        if (table.getn(addrs) == 0) then
            Fields["temp111"] = math.random(10,85)
            Fields["temp222"] = math.random(10,85)
            Fields["temp333"] = math.random(10,85)
        end
    
    end
    addrs = nil -- rusim pole adres
    
    -- Don't forget to release library it after use
    t = nil
    ds18b20 = nil
    package.loaded["ds18b20"]=nil

-- Battery
    analog_value = (adc.read(0))
    Fields["analog"] = analog_value

-- Pins
   local ReadScan = {[5] = "collector_pump", [0] = "transfer_pump", [2] = "exchanger", [1] = "NC"}
   local value = ""
   for q,v in pairs(ReadScan) do
        value = gpio.read(q)
        Fields[v] = value
   end
   value = nil
   ReadScan = nil  

collectgarbage()
tmr.alarm(0, 200, 0, function() dofile("send.lc") end)
print("Sending initiated...")
