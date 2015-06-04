local Humidity = -1
local Temperature = -1
local Battery = -1
local counter = 0

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
        dofile("sleep.lc")
    end)
    
    conn:on("connection", function(conn)
        print("Connected, sending data...")
        conn:send("GET /update?key=6XJ1AWU739JA0J9G&field1="..Temperature.."&field2="..Humidity.."&field3="..Battery.." HTTP/1.1\r\n") 
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
  local dht22 = require("dht22")
  if 0 == dht22.read(2) then -- pin 4=GPIO2, 2=GPIO5 
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

  -- Battery
  local analog_value = 46 * adc.read(0)
  Battery = (analog_value / 10000).."."..(analog_value % 10000)
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
