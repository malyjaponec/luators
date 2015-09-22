    tmr.stop(0)
    print("HEAP measure_data "..node.heap())
    
    Fields = ""

    gpio.write(6, gpio.HIGH) -- zapnuti napajeni
    print("Measuring...")
    
    -- Tepolot z ds18b20
    t = require("ds18b20")

    t.setup(7) -- sbernice na gpio 13 (vedlejsi pin vedle VCC)
    local addrs = t.addrs() -- nacte adresy do lokalniho pole
    local textvalue = ""
    if (addrs ~= nil) then
        print("Total DS18B20 sensors: "..table.getn(addrs)) -- pocet senzoru 

        -- Start measure for all sensors
        for q,v in pairs(addrs) do
            t.startMeasure(v)
        end
        -- Wait until first measure is done
--        tmr.wdclr()
        tmr.delay(750000)
--        tmr.wdclr()
        -- Read temperatures
        local value 
        local textvalue
        for q,v in pairs(addrs) do
            value = nil
            value = t.readNumber(v)
            textvalue = nil
            textvalue = (value / 10000).."."..string.sub(string.format("%04d",(value % 10000)),1,4)
            print("Temperature "..q.." = "..textvalue)
            addrs[q] = nil -- mazu z pole adresu, uz ji nebudu potrebovat
            if (Fields ~= "") then Fields = Fields.."," end
            Fields = Fields.."temp"..q..":"..textvalue
            tmr.wdclr()
        end

-- nefunguje teplomer, simuluju to
        if (Fields ~= "") then Fields = Fields.."," end
        Fields = Fields.."temp1:"..math.random(10,85)..
                         ",temp2:"..math.random(10,85)..
                         ",temp3:"..math.random(10,85)..
                         ",temp4:"..math.random(10,85)..
                         ",temp5:"..math.random(10,85)..
                         ",temp6:"..math.random(10,85)..
                         ",pump1:"..math.random(0,1)..
                         ",pump2:"..math.random(0,1)..
                         ",exch:"..math.random(1,2)

    end
    addrs = nil -- rusim pole adres
    textvalue = nil 
    value = nil

    -- Don't forget to release library it after use
    t = nil
    ds18b20 = nil
    package.loaded["ds18b20"]=nil

    -- vypnuti napajeni teplomeru
    gpio.write(6, gpio.LOW) -- tento pin slouzi k napajeni 
    gpio.write(7, gpio.LOW) -- vypnuti i datoveho pinu, zustava jinak svitit modra led na kitu, na finalu to zbytecne zere, funce ow.depower nefunguje

    -- Battery
    -- Battery = (468 * adc.read(0)) / 100

    collectgarbage()
    tmr.alarm(0, 200, 0, function() dofile("send.lc") end)
    print("Sending initiated...")




