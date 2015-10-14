-- measure.lua

    tmr.stop(0)
   
-- Temperature and Humidity
    gpio.write(1, gpio.HIGH)

    local result,Tint,Hint,Tfrac,Hfrac
    counter = 10
    while (counter > 0) do
        print("Measuring...")
        result, Tint, Hint, Tfrac, Hfrac = dht.read(2) -- pin 4=GPIO2, 2=GPIO5 
        if (result == 0) then
            break
        end
        print(result)
        counter = counter - 1
    end
    gpio.write(1, gpio.LOW)
    
    if (0 == result) then
        print ("Temp: "..Tint..","..Tfrac)
        print ("Humi: "..Hint..","..Hfrac)
        
        Fields[ReportFieldPrefix.."teplota"] = Tint
        Fields[ReportFieldPrefix.."vlhkost"] = Hint

        Fields[ReportFieldPrefix.."sensor_failed"] = 0
    else
        Fields[ReportFieldPrefix.."sensor_failed"] = 1
    end

    -- uklid
    result = nil
    Tint, Hint, Tfrac, Hfrac = nil

    collectgarbage()

-- analog prevodnik, pouze zpracovani dat, mereni se provadi pri startu

    baterie_voltage = 468 * AnalogMinimum / 100000
    print ("Batt min: "..baterie_voltage)
    Fields[ReportFieldPrefix.."baterie_min"] = baterie_voltage
    
    baterie_voltage = 468 * AnalogMaximum / 100000
    print ("Batt max: "..baterie_voltage)
    Fields[ReportFieldPrefix.."baterie_max"] = baterie_voltage

    baterie_voltage = nil

-- konec a spusteni odesilani
    
    collectgarbage()
    
    tmr.alarm(0, 100, 0, function() dofile("send.lc") end)
    print("Sending initiated...")
