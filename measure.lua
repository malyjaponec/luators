    tmr.stop(0)
    print("HEAP measure_data "..node.heap())
   
     Fields = {}   

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
        
        Fields["sklenik_teplota"] = Tint.."."..Tfrac
        Fields["sklenik_vlhkost"] = Hint.."."..Hfrac
    end

    -- uklid
    result = nil
    Tint, Hint, Tfrac, Hfrac = nil

    collectgarbage()

    -- analog prevodnik   
    analog_value = 468 * adc.read(0) / 100
    print ("Anal: "..analog_value)
    local Battery = (analog_value / 1000).."."..string.sub(string.format("%03d",(analog_value % 1000)),1,2)
    Fields["sklenik_baterie"] = Battery
    Battery = nil

    collectgarbage()
    
    tmr.alarm(0, 200, 0, function() dofile("send.lc") end)
    print("Sending initiated...")
