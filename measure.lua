-- measure.lua

    tmr.stop(0)
   
-- Temperature and Humidity

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

-- analog prevodnik, nejdrive priprava na mereni svetla a zpracovani dat z uvodniho cekani

    gpio.mode(gpionum[14],gpio.OUTPUT)
    gpio.write(gpionum[14],gpio.LOW) -- prijim fotoodpor na zem

    baterie_voltage = 468 * AnalogMinimum / 100000
    print ("Batt min: "..baterie_voltage)
    Fields[ReportFieldPrefix.."baterie_min"] = baterie_voltage
    
    baterie_voltage = 468 * AnalogMaximum / 100000
    print ("Batt max: "..baterie_voltage)
    Fields[ReportFieldPrefix.."baterie_max"] = baterie_voltage

    baterie_voltage = nil
    
-- analog prevodni, mereni svetla, posilam co zmerim bez prepoctu, jen otocim logiku

    local AnalogValue = adc.read(0)
    Fields[ReportFieldPrefix.."light"] = 1024-AnalogValue
    AnalogValue = nil

-- konec a spusteni odesilani
    
    collectgarbage()
    
    tmr.alarm(0, 100, 0, function() dofile("send.lc") end)
    print("Sending initiated...")
