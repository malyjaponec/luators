--local api_key = "DXF1QV45IV9PKGJU" -- sklenik
--local api_key = "JD83443A1SBDLGUG" -- solarni system
--local api_key = "S4TJMXTW8AJY6L1P" -- testovaci kanal
--local api_key = "5N8YZG6DZMJJ0ZRG" -- jiffaco/testovaci
--local api_key = "5K9G8GD0UTF5KIK0" -- jiffaco/sklenik

local api_key = "3e6176fb0367dfc59d914940f95c1007" -- jiffaco/emon
local node_id = "node=3" -- identifikace nodu


    tmr.stop(0)
    print("HEAP send_data "..node.heap())
    
    local SentOK = 0

    -- prepare reboot if something bad, timeout 15 s
    ReportInterval = 300
    tmr.alarm(0, 15000, 0, function() node.restart() end)

    -- pridam velikost heapu
    Fields["foliak_heap"] = node.heap()
    
    print(Fields) -- debug
        
    -- make conection to thingspeak.com
    print("Connecting to gate.jiffaco.cz...")
    local conn=net.createConnection(net.TCP, 0) 

    conn:on("receive", function(conn, payload)
        print("RX:"..payload) 
    end)

    conn:on("sent", function(conn) 
        print("Sent...") 
        tmr.alarm(1, 1000, 0, function() conn:close() end)
    end)
    
    conn:on("disconnection", function(conn) 
        print("Got disconnection.") 
        conn = nil
        ReportInterval = 300
        dofile("sleep.lc")
    end)

    conn:on("connection", function(conn)
        SentOK = 1
        print("Connected, sending data...")
        conn:send("GET /emoncms/input/post.json?" .. node_id .. "&json=" .. cjson.encode(Fields) .. "&apikey=" .. api_key .. " HTTP/1.1\r\n")
        conn:send("Host: emon.jiffaco.cz\r\n") 
        --conn:send("Accept: */*\r\n") 
        --conn:send("User-Agent: Mozilla/4.0 (compatible; esp8266 Lua; no OS)\r\n")
        conn:send("\r\n")
        conn:send("\r\n")
    end)

    -- api.thingspeak.com 184.106.153.149
    -- jiffaco localne 192.168.129.3
    -- jiffaco externe i lokalne 77.104.219.2
    conn:connect(80,'77.104.219.2')



