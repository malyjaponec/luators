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

    -- analog prevodnik   
    analog_value = adc.read(0)
    baterie_voltage = analog_value * 0.003436
    print ("Anal: "..baterie_voltage)
    Fields[ReportFieldPrefix.."baterie"] = baterie_voltage
    baterie_voltage = nil
    analog_value = nil

    collectgarbage()
    
    tmr.alarm(0, 200, 0, function() dofile("send.lc") end)
    print("Sending initiated...")
