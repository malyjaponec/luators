    tmr.stop(0)
    print("HEAP measure_data "..node.heap())
   
     Fields = {}   

    -- Temperature and Humidity
    gpio.mode(1, gpio.OUTPUT) -- GPIO5 napaji DHT22
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
        
        Fields["foliak_teplota"] = Tint.."."..Tfrac
        Fields["foliak_vlhkost"] = Hint.."."..Hfrac
    end

    -- uklid
    result = nil
    Tint, Hint, Tfrac, Hfrac = nil

    collectgarbage()

    -- analog prevodnik   
    analog_value = (1024 - adc.read(0))
    print ("Anal: "..analog_value)
    Fields["foliak_svetlo"] = analog_value
    Battery = nil

    collectgarbage()
    
    tmr.alarm(0, 200, 0, function() dofile("send.lc") end)
    print("Sending initiated...")
