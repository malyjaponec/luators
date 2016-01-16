--------------------------------------------------------------------------------
-- OpenEnergyMonitor sender for NODEMCU
-- 
-- 
-- 
-- 
--------------------------------------------------------------------------------

-- Set module name as parameter of require
local modname = ...
local M = {}
_G[modname] = M
--------------------------------------------------------------------------------
-- Local used variables
--------------------------------------------------------------------------------
-- ulozeni odesilaneho pole dat
local Data = nil
-- ulozeni klice pro pristup k serveru
local ApiKey = nil
-- ulozeni IP adresy serveru
local EmonIP = nil
-- ulozeni cisla nodu pro Emon
local Node = nil
-- ulozeni nazvu host (pro virtual host)
local Host = nil
-- pouzivany timer
local TimerNo = nil
-- Stav operace
local Status = -1
local Confirmed = 0
--------------------------------------------------------------------------------
-- Local used modules
--------------------------------------------------------------------------------
-- Table module
local table = table
-- String module
local string = string
-- Timer module
local tmr = tmr
-- Net module
local net = net
-- Json
local cjson = cjson

-- Limited to local environment
setfenv(1,M)
--------------------------------------------------------------------------------
-- Implementation
--------------------------------------------------------------------------------

-- Konfigurace serveru a apiklice
function setup(emonip, apikey, node, host, timerno)
    EmonIP = emonip
    if EmonIP == nil then
        return -1 -- error
    end
    ApiKey = apikey
    if ApiKey == nil then
        return -1 -- error
    end
    Node = node
    if Node == nil then
        Node = 1 -- default
    end
    Host = host
    if Host == nil then
        Host = EmonIP -- pokud neudam virtaulniho hosta, posle tam to co jsem uvedl v IP
    end
    TimerNo = timer
    if TimerNo == nil then
        TimerNo = 6 -- default
    end
    return 0
end

-- Odeslani dat
function send(data)
    Status = 0 -- operace probiha
    Confirmed = 0 -- neni potvrzeno doruceni dat
    local Data = data
    if Data == nil then
        return -1
    end

    local c=net.createConnection(net.TCP, 0) 

    c:on("receive", function(c, payload)
        Status = 3 -- prijata odpoved
        Confirmed = 1 -- zatim nekontroluji obsah, dulezite je ze jsem dostal odpoved
        tmr.alarm(TimerNo, 100, 0, function() c:close() end)
    end)

    c:on("sent", function(c) 
        Status = 2 -- data odeslana
        tmr.alarm(TimerNo, 2000, 0, function() c:close() end)
    end)
    
    c:on("disconnection", function(c) 
        Status = 4 -- disconnected
        tmr.stop(TimerNo)
        c = nil
    end)
    
    c:on("connection", function(c)
        Status = 1 -- navazano TCP spojeni
        c:send("GET /emoncms/input/post.json?node=" .. Node .. "&json=" .. cjson.encode(data) .. 
               "&apikey=" .. ApiKey.. " HTTP/1.1\r\nHost: ".. Host .."\r\n\r\n\r\n")
        
    end)

    c:connect(80,EmonIP)
    tmr.alarm(TimerNo, 10000, 0, function() c:close() end) -- 10s timeout pak vzdy koncim
end  

-- Vraci vysledek operace (nebo jeji prubeh)
function get_state()
    return Status,Confirmed
end

function abort()
    c.close()
end
   
  
-- Return module table
return M
