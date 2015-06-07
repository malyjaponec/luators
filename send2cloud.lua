local Temperature = -1
local Humidity = -1
local TempList = {}
local Battery = -1
local counter = 0
--local api_key = "***REMOVED***" -- smradoch tours garage
local api_key = "6XJ1AWU739JA0J9G" -- testovaci kanal

local function send_data()
    --print("HEAP send_data "..node.heap())
    
    tmr.stop(0)
    -- prepare reboot if something bad, timeout 15 s
    tmr.alarm(0, 15000, 0, function() dofile("sleep.lc") end)

    local Fields = ""
    for q,temp in pairs(TempList) do
        Fields = Fields.."&field"..q.."="..temp
    end
    Fields = Fields.."&field8="..Battery
    print(Fields)
    
    -- make conection to thingspeak.com
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
        --dofile("longsleep.lc")
        dofile("sleep.lc")
    end)
    
    conn:on("connection", function(conn)
        print("Connected, sending data...")
--        conn:send("GET /update?key="..api_key.."&field1="..Temperature.."&field2="..Humidity.."&field3="..Battery.." HTTP/1.1\r\n") 
        conn:send("GET /update?key="..api_key..Fields.." HTTP/1.1\r\n") 
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
    
    -- Temperatures
    if nil ~= use_dht22 then
        require("dht22")
        if 0 == dht22.read(2) then -- pin 2=GPIO5 
            dht22 = nil
            counter = counter - 1
            if (counter > 0) then
                tmr.alarm(0, 500, 0, function() measure_data() end)
            else
                print("PANIC, data not aquired, end")
                dofile("sleep.lc") 
            end
            return
        end

        Temperature = dht22.getTemperatureString()
        Humidity = dht22.getHumidityString()

        dht22 = nil
        package.loaded["dht22"]=nil
    
        print ("Temperature: "..Temperature)
        print ("Humidity: "..Humidity)
     end

    -- Mereni pomoci 18b20
    t = require("ds18b20")

    t.setup(7) -- gpio 13
    addrs = t.addrs()
    if (addrs ~= nil) then
        print("Total DS18B20 sensors: "..table.getn(addrs))
  
    -- Just read temperature
        local value = -1
        local textvalue = ""
        for a,b in pairs(addrs) do
            value = t.read(b) -- zde probiha mereni vycitani dat
            if (value == 850000) then value = t.read(b) end
            if (value == 850000) then value = t.read(b) end
            textvalue = (value / 10000).."."..string.sub(string.format("%04d",(value % 10000)),1,4)
            print("Temperature "..a.." = "..textvalue)
            TempList[a] = textvalue
        end
        value = nil
        textvalue = nil
    end

    -- Don't forget to release it after use
    t = nil
    ds18b20 = nil
    package.loaded["ds18b20"]=nil


    -- Battery
    local analog_value = 468 * adc.read(0)
    Battery = (analog_value / 100000).."."..string.sub(string.format("%05d",(analog_value % 100000)),1,2)
    analog_value = nil

    print ("Battery: "..Battery)
 
    send_data()
end

--print("HEAP send2cloud.lua "..node.heap())
tmr.stop(0)
counter = 10
measure_data()
