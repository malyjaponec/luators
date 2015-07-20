local SentOK = 0
local Fields

--local api_key = "***REMOVED***" -- sklenik
local api_key = "***REMOVED***" -- solarni system
--local api_key = "***REMOVED***" -- testovaci kanal

local function send_data()
    --print("HEAP send_data "..node.heap())
    
    tmr.stop(0)
    -- prepare reboot if something bad, timeout 15 s
    tmr.alarm(0, 15000, 0, function() dofile("reboot.lc") end)

    -- pridam velikost heapu
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
            dofile("wait.lc")
        else
            dofile("reboot.lc")
        end
    end)
    
    conn:on("connection", function(conn)
        SentOK = 1
        print("Connected, sending data...")
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
    gpio.write(6, gpio.HIGH) -- zapnuti napajeni
    print("Measuring...")
    
    -- Tepolot z ds18b20
    t = require("ds18b20")

    t.setup(7) -- sbernice na gpio 13 (vedlejsi pin vedle VCC)
    local addrs = t.addrs() -- nacte adresy do lokalniho pole
    local textvalue = ""
    if (addrs ~= nil) then
        print("Total DS18B20 sensors: "..table.getn(addrs)) -- pocet senzoru 

        -- Start measure for all sensors
        for q,v in pairs(addrs) do
            t.startMeasure(v)
        end
        -- Wait until first measure is done
--        tmr.wdclr()
        tmr.delay(750000)
--        tmr.wdclr()
        -- Read temperatures
        local value 
        local textvalue
        Fields = ""
        for q,v in pairs(addrs) do
            value = nil
            value = t.readNumber(v)
            textvalue = nil
            textvalue = (value / 10000).."."..string.sub(string.format("%04d",(value % 10000)),1,4)
            print("Temperature "..q.." = "..textvalue)
            addrs[q] = nil -- mazu z pole adresu, uz ji nebudu potrebovat
            Fields = Fields.."&field"..q.."="..textvalue
            collectgarbage()
        end
--        Fields = Fields.."&field1=1.0001&field2=2.0002&field3=3.0003&field4=4.0004&field5=5.0005"
    end
    addrs = nil -- rusim pole adres
    textvalue = nil 
    value = nil

    -- Don't forget to release library it after use
    t = nil
    ds18b20 = nil
    package.loaded["ds18b20"]=nil

    -- vypnuti napajeni teplomeru
    gpio.write(6, gpio.LOW) -- tento pin slouzi k napajeni 
    gpio.write(7, gpio.LOW) -- vypnuti i datoveho pinu, zustava jinak svitit modra led na kitu, na finalu to zbytecne zere, funce ow.depower nefunguje

    -- Battery
    -- Battery = (468 * adc.read(0)) / 100

end

--print("HEAP send2cloud.lua "..node.heap())
tmr.stop(0)
measure_data()
collectgarbage()
-- nevolam ze send data, protoze se nic neopakuje a tak je lepsi aby lokalni promenne 
-- send data zhynuli, realne to ma efekt asi 300 bajtu na heapu, takze nic moc
  tmr.alarm(0, 500, 0, function() send_data() end)
--send_data() 

