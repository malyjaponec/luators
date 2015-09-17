    tmr.stop(0)
    print("HEAP measure_data "..node.heap())
   
    Fields = ""
        
    -- Temperature and Humidity
    local result,Tint,Hint,Tfrac,Hfrac
    counter = 10
    while (counter > 0) do
        print("Measuring...")
        result, Tint, Hint, Tfrac, Hfrac = dht.read(4) -- pin 4=GPIO2, 2=GPIO5 
        if (result == 0) then
            break
        end
        print(result)
        counter = counter - 1
    end

    if (0 == result) then
        print ("Temp: "..Tint..","..Tfrac)
        print ("Humi: "..Hint..","..Hfrac)
        
        Fields = "teplota:"..Tint.."."..Tfrac..",vlhkost:"..Hint.."."..Hfrac
    end

    -- uklid
    result = nil
    Tint, Hint, Tfrac, Hfrac = nil

    collectgarbage()

    -- analog prevodnik   
    local analog_value = adc.read(0)
    print ("Anal: "..analog_value)
    if (Fields ~= "") then Fields = Fields.."," end
    Fields = Fields.."tma:"..analog_value
    analog_value = nil

    collectgarbage()
    
    tmr.alarm(0, 200, 0, function() dofile("send.lc") end)
    print("Sending initiated...")
