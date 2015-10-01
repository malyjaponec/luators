    tmr.stop(0)
    print("HEAP send_data "..node.heap())
    
    local SentOK = 0

    -- pridam velikost heapu
    Fields["sklenik_heap"] = node.heap()
    
    print(Fields) -- debug
        
    -- make conection to thingspeak.com
    print("Connecting to gate.jiffaco.cz...")
    local conn=net.createConnection(net.TCP, 0) 

    conn:on("receive", function(conn, payload)
        print("RX:"..payload) 
    end)

    conn:on("sent", function(conn) 
        print("Sent...") 
        tmr.alarm(0, 1000, 0, function() conn:close() end)
    end)
    
    conn:on("disconnection", function(conn) 
        print("Got disconnection.") 
        conn = nil
        dofile("sleep.lc")
    end)

    conn:on("connection", function(conn)
        SentOK = 1
        print("Connected, sending data...")
        print("GET /emoncms/input/post.json?node=" .. ReportNode .. "&json=" .. cjson.encode(Fields) .. "&apikey=" .. ReportApiKey .. " HTTP/1.1\r\n")
        conn:send("GET /emoncms/input/post.json?node=" .. ReportNode .. "&json=" .. cjson.encode(Fields) .. "&apikey=" .. ReportApiKey .. " HTTP/1.1\r\n")
        conn:send("Host: emon.jiffaco.cz\r\n") 
        --conn:send("Accept: */*\r\n") 
        --conn:send("User-Agent: Mozilla/4.0 (compatible; esp8266 Lua; no OS)\r\n")
        conn:send("\r\n")
        conn:send("\r\n")
    end)

    -- jiffaco localne 192.168.129.3
    -- jiffaco externe i lokalne 77.104.219.2
    conn:connect(80,'77.104.219.2')



