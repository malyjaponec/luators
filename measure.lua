    tmr.stop(0)
    print("HEAP measure_data "..node.heap())
   
    Fields = ""

    gpio.write(3, gpio.HIGH) -- zapnuti napajeni gpio0
    
    -- Temperature and Humidity
    local dht = require("dht22")
    local result
    counter = 10
    while (counter > 0) do
        print("Measuring...")
        result = dht.read(4) -- pin 4=GPIO2, 2=GPIO5 
        if (result == 1) then
            break
        end
        print(result)
        counter = counter - 1
    end

    if (1 == result) then
        Temperature = dht.getTemperatureString()
        Humidity = dht.getHumidityString()

        print ("Temperature: "..Temperature)
        print ("Humidity: "..Humidity)
        
        Fields = Fields.."&field1="..Temperature.."&field2="..Humidity
    end

    -- uklid
    dht = nil
    dht22 = nil
    package.loaded["dht22"] = nil

    -- vypnuti napajeni teplomeru
    -- gpio0 se nemusi vypinat, rozsvitila by se led
    
    -- Battery
--    analog_value = 468 * adc.read(0) / 100
--    Battery = (analog_value / 1000).."."..string.sub(string.format("%03d",(analog_value % 1000)),1,2)
    Battery = adc.read(0)
--    analog_value = nil

    print ("Battery: "..Battery)
    Fields = Fields.."&field3="..Battery
    Battery = nil

    collectgarbage()
    tmr.alarm(0, 200, 0, function() dofile("send.lc") end)
    print("Sending initiated...")
