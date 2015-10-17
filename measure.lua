    tmr.stop(0)
    print("HEAP measure_data "..node.heap())
   
     Fields = {}   

    -- Temperature and Humidity
    local result,Tint,Hint,Tfrac,Hfrac
    counter = 10
    while (counter > 0) do
        print("Measuring...")
        result, Tint, Hint, Tfrac, Hfrac = dht.read(gpionum[2])
        if (result == 0) then
            break
        end
        print(result)
        counter = counter - 1
    end

    if (0 == result) then
        print ("Temp: "..Tint..","..Tfrac)
        print ("Humi: "..Hint..","..Hfrac)

        -- frac hodnoty se pouziji jen pro integer preklad, tohle pouziva float a je to primo v prvni promenne
        Fields[ReportFieldPrefix.."teplota"] = Tint
        Fields[ReportFieldPrefix.."vlhkost"] = Hint
    end

    -- uklid
    result = nil
    Tint, Hint, Tfrac, Hfrac = nil

    collectgarbage()

    -- analog prevodnik, pouze zpracovani dat, mereni se provadi pri startu
    baterie_voltage = AnalogMinimum * 0.003436
    print ("Batt min: "..baterie_voltage)
    Fields[ReportFieldPrefix.."baterie_min"] = baterie_voltage
    baterie_voltage = AnalogMaximum * 0.003436
    print ("Batt max: "..baterie_voltage)
    Fields[ReportFieldPrefix.."baterie_max"] = baterie_voltage
    baterie_voltage = nil

    collectgarbage()

    -- Sbernice DALASu
    t = require("ds18b20")
    t.setup(gpionum[4])
    local addrs1 = t.addrs() -- nacte adresy do lokalniho pole
    if (addrs1 ~= nil) then
        local pocetsnimacu = table.getn(addrs1)
        print("ds18b20 sensors: "..pocetsnimacu) -- pocet senzoru 
        if (pocetsnimacu > 0) then
            -- Start measure for all sensors
            for q,v in pairs(addrs1) do
                t.startMeasure(v)
            end
            -- Pro pripad fantom napajeni radeji zapnu HIGH na datovem vodici, od jisteho FW to umi OW sama
            gpio.mode(gpionum[4],  gpio.OUTPUT) 
            gpio.write(gpionum[4], gpio.HIGH)
            -- Wait until measure is done
            tmr.delay(750000)
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
        end
        pocetsnimacu = nil
        value = nil
        textaddr = nil
    end
    addrs1 = nil -- rusim pole adres
    -- Don't forget to release library it after use
    t = nil
    ds18b20 = nil
    package.loaded["ds18b20"]=nil

    -- Mereni dokoncena 
    tmr.alarm(0, 200, 0, function() dofile("send.lc") end)
    print("Sending initiated...")
