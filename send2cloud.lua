local Humidity = -1
local Temperature = -1
local Battery = -1
CloudInterval = 60 -- sekund

local function measure_data()

  -- Temperature and Humidity
  local dht22 = require("dht22")
  if 0 == dht22.read(2) then -- pin 4=GPIO2, 2=GPIO5 
    dht22 = nil
    return 0 -- vracim chybu cteni dat
  end

  Temperature = dht22.getTemperatureString()
  Humidity = dht22.getHumidityString()
  dht22 = nil

  -- Battery
  local analog_value = 47 * adc.read(0)
  Battery = (analog_value / 10000).."."..(analog_value % 10000)
  analog_value = nil

  print ("Temperature: "..Temperature)
  print ("Humidity: "..Humidity)
  print ("Battery: "..Battery)
  return 1
end


function sendData()
    local q
    for q = 1, 10 do -- cist data se pokusim 10x po sobe
        if 1 == measure_data() then
            -- time new start
                local time = (CloudInterval * 1000) - (tmr.now()/1000)
                if time < 15000 then time = 15000 end
                tmr.alarm(0, time, 0, function() dofile("start.lc") end)
                print("New measurement in "..(time/1000).." s") 
            -- make conection to thingspeak.com
            print("Connecting to thingspeak.com...")
            local conn=net.createConnection(net.TCP, 0) 

            conn:on("receive", function(conn, payload)
                --print((tmr.now()/1000).." RX:"..payload) 
                print("RX:"..payload) 
            end)
            conn:on("sent", function(conn) 
                --print((tmr.now()/1000).." Closing connection...") 
                print("Closing connection...") 
                conn:close() 
            end)
            conn:on("disconnection", function(conn) 
                --print((tmr.now()/1000).." Got disconnection.") 
                print("Got disconnection.") 
                conn = nil
            end)
            conn:on("connection", function(conn)
                --print((tmr.now()/1000).." Connected, sending data...")
                print("Connected, sending data...")
                conn:send("GET /update?key=6XJ1AWU739JA0J9G&field1="..Temperature.."&field2="..Humidity.."&field3="..Battery.." HTTP/1.1\r\n") 
                conn:send("Host: api.thingspeak.com\r\n") 
                conn:send("Accept: */*\r\n") 
                conn:send("User-Agent: Mozilla/4.0 (compatible; esp8266 Lua; Windows NT 5.1)\r\n")
                conn:send("\r\n")
                conn:send("\r\n")
                --print((tmr.now()/1000).." sent.")
            end)
            -- api.thingspeak.com 184.106.153.149
            conn:connect(80,'184.106.153.149') 
            break
        else
            print("W: Data not aquired, retry #"..q)
            tmr.delay(1500000)
            if 10 == q then
              print("E: Restart in 5 s") 
              tmr.alarm(0, 5000, 0, function() node.restart() end)
            end
        end
    end
    q = nil
end

-- a rovnou to zmer
sendData()
