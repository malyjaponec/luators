--local api_key = "DXF1QV45IV9PKGJU" -- sklenik
local api_key = "JD83443A1SBDLGUG" -- solarni system
--local api_key = "S4TJMXTW8AJY6L1P" -- testovaci kanal

    tmr.stop(0)
    print("HEAP send_data "..node.heap())
    
    local SentOK = 0

    -- prepare reboot if something bad, timeout 15 s
    tmr.alarm(0, 15000, 0, function() dofile("reboot.lc") end)

    -- pridam velikost heapu
    Fields = Fields.."&field8="..node.heap()
    
    print(Fields) -- debug
        
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
       if (SentOK == 1) then
            collectgarbage()
            tmr.alarm(0, 200, 0, function() dofile("wait.lc") end)
        else
            collectgarbage()
            tmr.alarm(0, 200, 0, function() dofile("reboot.lc") end)
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



