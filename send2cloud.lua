PIN = 4 --  data pin, GPIO2

function getTemp()
  Humidity = 0
  Temperature = 0

  dht22 = require("dht22")
  dht22.read(PIN)
  Temperature = dht22.getTemperature()
  Humidity = dht22.getHumidity()

  if Humidity == nil then
    return 0 -- vracim chybu cteni dat
  end
  
  Temperature = Temperature / 10
  Humidity = Humidity / 10

  print ("Temperature: "..Temperature)
  print ("Humidity: "..Humidity)
  return 1
end

function sendData()
    for q = 1, 10 do -- cist data se pokusim 10x po sobe
        if 1 == getTemp() then
            -- make conection to thingspeak.com
            print("Sending data to thingspeak.com")
            conn=net.createConnection(net.TCP, 0) 
            conn:on("receive", function(conn, payload) print(payload) end)
            
            -- api.thingspeak.com 184.106.153.149
            conn:connect(80,'184.106.153.149') 
            conn:send("GET /update?key=6XJ1AWU739JA0J9G&field1="..Temperature.."&field2="..Humidity.." HTTP/1.1\r\n") 
            conn:send("Host: api.thingspeak.com\r\n") 
            conn:send("Accept: */*\r\n") 
            conn:send("User-Agent: Mozilla/4.0 (compatible; esp8266 Lua; Windows NT 5.1)\r\n")
            conn:send("\r\n")
            conn:on("sent", function(conn)
                print("Closing connection")
                conn:close()
            end)
            conn:on("disconnection", function(conn)
                print("Got disconnection...")
            end)
            break
        else
            print("Chyba cteni dat, opakovani "..q..".")
            tmr.delay(1000000)
        end
    end
end

-- send data every X ms to thing speak
tmr.alarm(2, 60000, 1, function() sendData() end )
-- a rovnou to zmer
sendData()
