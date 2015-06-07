local Humidity = -1
local Temperature = -1
local Battery = -1
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
        dofile("longsleep.lc")
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
  print("Measuring...")
    
  -- Temperature and Humidity
  local dht = require("dht22")
  if 0 == dht.read(2) then -- pin 4=GPIO2, 2=GPIO5 
    dht = nil
    counter = counter - 1
    if (counter > 0) then
      tmr.alarm(0, 500, 0, function() measure_data() end)
    else
      print("PANIC, data not aquired, end")
      dofile("sleep.lc") 
    end
    -- uklid
    dht = nil
    dht22 = nil
    package.loaded["dht22"] = nil
    return
  end

  Temperature = dht.getTemperatureString()
  Humidity = dht.getHumidityString()

  -- uklid
  dht = nil
  dht22 = nil
  package.loaded["dht22"] = nil

  -- Battery
  local analog_value = 468 * adc.read(0)
  Battery = (analog_value / 100000).."."..string.sub(string.format("%05d",(analog_value % 100000)),1,2)
  analog_value = nil

  print ("Temperature: "..Temperature)
  print ("Humidity: "..Humidity)
  print ("Battery: "..Battery)
 
  send_data()
end

--print("HEAP send2cloud.lua "..node.heap())
tmr.stop(0)
counter = 10
measure_data()
