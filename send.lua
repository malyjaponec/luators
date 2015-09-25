local api_key = "***REMOVED***" -- jiffaco/emon
local node_id = "node=2" -- identifikace nodu

    tmr.stop(0)
    print("HEAP send_data "..node.heap())
    
    local SentOK = 0

    -- prepare reboot if something bad, timeout 15 s
    tmr.alarm(0, 15000, 0, function() node.restart() end)

 -- pridam velikost heapu
    Fields["heap"] = node.heap()
    
    -- pridam velikost heapu a counter
    RunCounter = RunCounter + 1
    Fields["run_count"] = RunCounter
    
    -- make conection to thingspeak.com
    print("Connecting to gate.jiffaco.cz...")
    local conn=net.createConnection(net.TCP, 0) 

    conn:on("receive", function(conn, payload)
        print("RX:"..payload) 
    end)

    conn:on("sent", function(conn) 
        print("Closing connection...") 
        tmr.alarm(1, 1000, 0, function() conn:close() end)
        --conn:close() 
    end)
    
    conn:on("disconnection", function(conn) 
        print("Got disconnection.") 
        tmr.stop(1)
        conn = nil
        if (SentOK == 1) then
            collectgarbage()
            tmr.alarm(0, 200, 0, function() dofile("wait.lc") end)
        else
            collectgarbage()
            tmr.alarm(0, 200, 0, function() dofile("reset.lc") end)
            -- alternativne podle baterije jeste jde exstrasl;ee[
        end
    end)
    
    conn:on("connection", function(conn)
        SentOK = 1
        print("Connected, sending data...")
        conn:send("GET /emoncms/input/post.json?" .. node_id .. "&json=" .. cjson.encode(Fields) .. "&apikey=" .. api_key .. " HTTP/1.1\r\n")
        conn:send("Host: emon.jiffaco.cz\r\n") 
        conn:send("Accept: */*\r\n") 
        conn:send("User-Agent: Mozilla/4.0 (compatible; esp8266 Lua; Windows NT 5.1)\r\n")
        conn:send("\r\n")
        conn:send("\r\n")
    end)

    -- api.thingspeak.com 184.106.153.149
    -- jiffaco localne 192.168.129.3
    -- jiffaco externe 77.104.219.2
    conn:connect(80,'77.104.219.2')



