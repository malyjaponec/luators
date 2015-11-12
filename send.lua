-- send.lua
    tmr.stop(0)
    
    local SentOK = 0

-- prepare reboot if something bad, timeout 15 s
    tmr.alarm(1, 10000, 0, function() node.restart() end)

-- pridam velikost heapu
    Fields[ReportFieldPrefix.."hp"] = node.heap()
    Fields[ReportFieldPrefix.."ID"] = node.chipid()

-- pridam velikost counter
    RunCounter = RunCounter + 1
    Fields[ReportFieldPrefix.."cnt"] = RunCounter
    
-- make conection to cloud
    print("Connecting to gate.jiffaco.cz...")
    local conn=net.createConnection(net.TCP, 0) 

    conn:on("receive", function(conn, payload)
        print("RX:"..payload) 
    end)

    conn:on("sent", function(conn) 
        print("Sent...") 
        tmr.alarm(0, 500, 0, function() conn:close() end)
    end)
    
    conn:on("disconnection", function(conn) 
        print("Got disconnection.") 
        tmr.stop(1)
        conn = nil
        if (SentOK == 1) then
            collectgarbage()
            tmr.stop(1) -- zastavim nouzovy casovac
            tmr.alarm(0, 50, 0, function() dofile("wait.lc") end)
        else
            tmr.alarm(0, 50, 0, function() dofile("reset.lc") end)
        end
    end)
    
    conn:on("connection", function(conn)
        SentOK = 1
        print("Connected, sending data...")
        -- debug print
          print("GET /emoncms/input/post.json?node=" .. ReportNode .. "&json=" .. cjson.encode(Fields) .. "&apikey=" .. ReportApiKey .. " HTTP/1.1\r\n")
        --
        conn:send("GET /emoncms/input/post.json?node=" .. ReportNode .. "&json=" .. cjson.encode(Fields) .. "&apikey=" .. ReportApiKey .. " HTTP/1.1\r\n")
        conn:send("Host: emon.jiffaco.cz\r\n") 
        conn:send("\r\n")
        conn:send("\r\n")
    end)

    -- jiffaco localne 192.168.129.3
    -- jiffaco externe i lokalne 77.104.219.2
    conn:connect(80,'77.104.219.2')



