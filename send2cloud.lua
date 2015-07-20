local Humidity = -1
local Temperature = -1
local Battery = -1
local analog_value = 4000
local counter = 0
local api_key = "***REMOVED***" -- smradoch tours garage
--local api_key = "6XJ1AWU739JA0J9G" -- testovaci kanal

local function send_data()
    --print("HEAP send_data "..node.heap())
    
    tmr.stop(0)
    -- prepare reboot if something bad, timeout 15 s
    tmr.alarm(0, 15000, 0, function() dofile("sleep.lc") end)
    
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
        if analog_value > 3800 then 
            dofile("longsleep.lc")
        else
            dofile("extrasleep.lc")
        end
    end)
    
    conn:on("connection", function(conn)
        print("Connected, sending data...")
        conn:send("GET /update?key="..api_key.."&field1="..Temperature.."&field2="..Humidity.."&field3="..Battery.." HTTP/1.1\r\n") 
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
    
  -- Temperature and Humidity
  local dht = require("dht22")
  local result
  counter = 10
  while (counter > 0) do
        print("Measuring...")
        result = dht.read(2) -- pin 4=GPIO2, 2=GPIO5 
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
  end

  -- uklid
  dht = nil
  dht22 = nil
  package.loaded["dht22"] = nil

  -- Battery
  analog_value = 468 * adc.read(0) / 100
  Battery = (analog_value / 1000).."."..string.sub(string.format("%03d",(analog_value % 1000)),1,2)

  print ("Battery: "..Battery)
  return result
end

--print("HEAP send2cloud.lua "..node.heap())

local result = 0
result = measure_data()
collectgarbage()

if (result == 1) then
   tmr.alarm(0, 200, 0, function() send_data() end)
else 
    print("PANIC, data not aquired, end")
    dofile("sleep.lc") 
end


