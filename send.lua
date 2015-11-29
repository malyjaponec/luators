-- send.lua
    tmr.stop(0)
    
    local SentOK = 0
    local ConnOK = 0

-- prepare reboot if something bad, timeout 10 s
    tmr.alarm(1, 10000, 0, function() node.restart() end)

-- pridam velikost heapu
    Rdat[Rpref.."hp"] = node.heap()

-- pridam velikost counter
    Rcnt = Rcnt + 1
    Rdat[Rpref.."cnt"] = Rcnt
    
-- make conection to cloud
    print("Connecting...")
    local conn=net.createConnection(net.TCP, 0) 

    conn:on("receive", function(conn, payload)
        if (Debug == 1) then print("Received:"..payload) end
        SentOK = 1 -- pouze pokud prijde odpoved ze serveru povazuji to za ok
        tmr.alarm(0, 100, 0, function() conn:close() end)
    end)

    conn:on("sent", function(conn) 
        if (Debug == 1) then print("Sent.") end
        tmr.alarm(0, 2000, 0, function() conn:close() end)
    end)
    
    conn:on("disconnection", function(conn) 
        if (Debug == 1) then print("Got disconnection.") end
        tmr.stop(1)
        conn = nil
        tmr.stop(1) -- zastavim nouzovy casovac
        if (SentOK == 1) then
            print("Seding OK.") 
        else
            print("Sending FAILED.") 
        end
        if (ConnOK == 1) then
            dofile("wait.lc") 
        else
            dofile("reset.lc") 
        end
    end)
    
    conn:on("connection", function(conn)
        ConnOK = 1
        if (Debug == 1) then
            print("Connected, sending data:")
            print("GET /emoncms/input/post.json?node=" .. Rnod .. "&json=" .. cjson.encode(Rdat) .. "&apikey=" .. Rapik.. " HTTP/1.1")
        end
        conn:send("GET /emoncms/input/post.json?node=" .. Rnod .. "&json=" .. cjson.encode(Rdat) .. "&apikey=" .. Rapik.. " HTTP/1.1\r\n")
        conn:send("Host: emon.jiffaco.cz\r\n") 
        conn:send("\r\n")
        conn:send("\r\n")
        Rdat = nil
    end)

    -- jiffaco localne 192.168.129.3
    -- jiffaco externe i lokalne 77.104.219.2
    conn:connect(80,'77.104.219.2')



