-- measure.lua

    tmr.stop(0)
   
-- Temperature and Humidity

    local result,Tint,Hint,Tfrac,Hfrac
    counter = 20
    while (counter > 0) do
        if Debug == 1 then print("Measuring...") end
        result, Tint, Hint, Tfrac, Hfrac = dht.read(DHT22pin)
        if (result == 0) then
            break
        end
        if Debug == 1 then print(result) end
        counter = counter - 1
        tmr.delay(115000) -- cekani 115ms, nevim muze to treba pomoci
    end
    
    if (0 == result) then
        -- tohle tisknu vzdy
        print ("Temp: "..Tint.." / "..Tfrac)
        print ("Humi: "..Hint.." / "..Hfrac)
        
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

-- analog prevodnik, mereni alternativni hodnoty s pripojenim gpio14 na zem (fotoodpor)

    gpio.write(gpionum[14],gpio.LOW) -- prijim fotoodpor na zem, cimz se pripravim na mereni svetla misto baterie

    local AnalogValue = adc.read(0)
    Fields[ReportFieldPrefix.."light"] = 1024-AnalogValue -- otoceni logiky hodnot
    AnalogValue = nil

    gpio.write(gpionum[14],gpio.HIGH) -- fotoodpor na 1, tedy nepotece skrz nej nic

-- konec a spusteni odesilani
    
    collectgarbage()
    
    tmr.alarm(0, 100, 0, function() dofile("send.lc") end)
    if Debug == 1 then print("Sending initiated...") end
