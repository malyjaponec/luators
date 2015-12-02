-- measure.lua

    tmr.stop(0)
    Fields[ReportFieldPrefix.."ti"] = tmr.now()/1000
    print("Measuring sensors.")
   
-- Temperature and Humidity

    local result,Tint,Hint,Tfrac,Hfrac
    counter = 20
    while (counter > 0) do
        if Debug == 1 then print("Reading DHT.") end
        result, Tint, Hint, Tfrac, Hfrac = dht.read(DHT22pin)
        if (result == 0) then
            break
        end
        if Debug == 1 then print(result) end
        counter = counter - 1
        tmr.delay(115000) -- cekani 115ms, nevim muze to treba pomoci
    end
    
    if (0 == result) then
        if Debug == 1 then 
            print ("Temp: "..Tint)
            print ("Humi: "..Hint)
        else
            print ("DHT4 ok")
        end
        
        Fields[ReportFieldPrefix.."teplota"] = Tint
        Fields[ReportFieldPrefix.."vlhkost"] = Hint
        Fields[ReportFieldPrefix.."dht4_ok"] = 1
    else
        Fields[ReportFieldPrefix.."dht4_ok"] = 0
    end

    -- uklid
    result = nil
    Tint, Hint, Tfrac, Hfrac = nil
    collectgarbage()

    -- uklid napajeni DHT22
    gpio.write(DHT22powerpin,gpio.LOW) -- vypnu napajeni DHT
    gpio.mode(DHT22pin,gpio.OUTPUT)
    gpio.write(DHT22pin,gpio.LOW) -- datovy drat taky dam na nulu

-- analog prevodnik, mereni alternativni hodnoty s pripojenim gpio14 na zem (fotoodpor)

    gpio.write(Lightpin,gpio.LOW) -- prijim fotoodpor na zem, cimz se pripravim na mereni svetla misto baterie

    Fields[ReportFieldPrefix.."an14"] =  adc.read(0)

    gpio.write(Lightpin,gpio.HIGH) -- fotoodpor na 1, tedy nepotece skrz nej nic

-- konec a spusteni odesilani
    
    collectgarbage()
    tmr.alarm(0, 10, 0, function() dofile("send.lc") end)
