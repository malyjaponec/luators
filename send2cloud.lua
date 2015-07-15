local Temperature = 0
local Humidity = 0
local TempList = {}
local Battery = 0
local counter = 0
local SentOK = 0

--local api_key = "***REMOVED***" -- sklenik
local api_key = "***REMOVED***" -- solarni system
--local api_key = "***REMOVED***" -- testovaci kanal

local function send_data()
    --print("HEAP send_data "..node.heap())
    
    tmr.stop(0)
    -- prepare reboot if something bad, timeout 15 s
    tmr.alarm(0, 15000, 0, function() dofile("reboot.lc") end)

    -- prepocet pole teplot na URL retezec
    collectgarbage()
    local Fields = ""
    for q,v in pairs(TempList) do
        Fields = Fields.."&field"..q.."="..v
        TempList[q]=nil -- mazu po sobe prvky pole
    end
    TempList = nil -- zrusim praznde pole

    -- pridam velikost heapu
    --Fields = Fields.."&field7="..Battery
    Fields = Fields.."&field5="..math.random(100)
    
    -- pridam napeti baterie
    Fields = Fields.."&field8="..node.heap()
    
    print(Fields) -- debug
    collectgarbage()
        
    -- make conection to thingspeak.com
    SentOK = 0
    print("Connecting to thingspeak.com...")
    local conn=net.createConnection(net.TCP, 0) 

    conn:on("receive", function(conn, payload)
        print("RX:"..payload) 
    end)

    conn:on("sent", function(conn) 
        print("Closing connection...") 
        conn:close() 
    end)
    
    conn:on("disconnection", function(conn) 
        print("Got disconnection.") 
        conn = nil
        if (SentOK == 1) then
            SentOK = nil
            dofile("wait.lc")
        else
            dofile("reboot.lc")
        end
    end)
    
    conn:on("connection", function(conn)
        SentOK = 1
        print("Connected, sending data...")
--        conn:send("GET /update?key="..api_key.."&field1="..Temperature.."&field2="..Humidity.."&field3="..Battery.." HTTP/1.1\r\n") 
        conn:send("GET /update?api_key="..api_key..Fields.." HTTP/1.1\r\n") 
        conn:send("Host: api.thingspeak.com\r\n") 
        conn:send("Accept: */*\r\n") 
        conn:send("User-Agent: Mozilla/4.0 (compatible; esp8266 Lua; Windows NT 5.1)\r\n")
        conn:send("\r\n")
        conn:send("\r\n")
    end)

    -- api.thingspeak.com 184.106.153.149
    conn:connect(80,'184.106.153.149')
end

local function measure_data()
    --print("HEAP measure_data "..node.heap())
    
    tmr.stop(0)
    print("Measuring...")
    
    -- Temperature and humidity DHT2
--    require("dht22")
--    if 0 == dht22.read(2) then -- pin 2=GPIO5 
--        dht22 = nil
--        counter = counter - 1
--        if (counter > 0) then
--            tmr.alarm(0, 500, 0, function() measure_data() end)
--        else
--            print("PANIC, data not aquired, end")
--            dofile("reboot.lc")
--        end
--        return
--    end
--    
--    Temperature = dht22.getTemperatureString()
--    Humidity = dht22.getHumidityString()
--    
--    dht22 = nil
--    package.loaded["dht22"]=nil
--    
--    print ("Temperature: "..Temperature)
--    print ("Humidity: "..Humidity)

    -- Tepolot z ds18b20
    t = require("ds18b20")

    t.setup(7) -- sbernice na gpio 13 (vedlejsi pin vedle VCC)
    local addrs = t.addrs() -- nacte adresy do lokalniho pole
    local textvalue = ""
    if (addrs ~= nil) then
        print("Total DS18B20 sensors: "..table.getn(addrs)) -- pocet senzoru 

        -- Start measure for all sensors
        for q,v in pairs(addrs) do
            t.measure(v)
        end
        -- Wait until first measure is done
        tmr.wdclr()
        tmr.delay(750000)
        tmr.wdclr()
        -- Read temperatures
        local value = 0
        local textvalue = ""
        for q,v in pairs(addrs) do
            value = t.read(v)
            textvalue = (value / 10000).."."..string.sub(string.format("%04d",(value % 10000)),1,4)
            TempList[q] = textvalue
            print("Temperature "..q.." = "..textvalue)
            addrs[q] = nil -- mazu z pole adresu, uz ji nebudu potrebovat
        end
    end
    addrs = nil -- rusim pole adres
    textvalue = nil 
    value = nil

    -- Don't forget to release library it after use
    t = nil
    ds18b20 = nil
    package.loaded["ds18b20"]=nil

    -- Battery
    Battery = (468 * adc.read(0)) / 100
    print ("Battery: "..Battery)

end

--print("HEAP send2cloud.lua "..node.heap())
tmr.stop(0)
--counter = 5 -- pouziva se pouze s dht, pro ds18b20 neni napsana podpora opakovani mereni
measure_data()
collectgarbage()
-- nevolam ze send data, protoze se nic neopakuje a tak je lepsi aby lokalni promenne 
-- send data zhynuli, realne to ma efekt asi 300 bajtu na heapu, takze nic moc
send_data() 
collectgarbage()

