--------------------------------------------------------------------------------
-- Sensor measurement - DHT
-- 
-- setup(casovac,dhtpin,dhtpowerpin) 
-- - nastavi casovac, ktery bude knihovna pouziva a spusti mereni
-- - prefix pro identifikaci zarizeni v pripade ze vice zarizeni posila v jednom node
-- - nastavi pin pro mereni dht
-- - nastavi pin pro napajeni dht
-- status() - vrati zda je mereni dokonceno nebo se jeste meri
-- getvalues() - vrati pole hodnot s namerenym hodnotami
-- 
--------------------------------------------------------------------------------
-- Set module name as parameter of require
local modname = ...
local M = {}
_G[modname] = M
--------------------------------------------------------------------------------
-- Local used variables
--------------------------------------------------------------------------------
local Casovac
local Data
local PinDHT
local PinDHTpower
local Counter
local Finished = 0
local Tavr,Havr,Cnt
-------------------------------------------------------------------------------
-- Local used modules
--------------------------------------------------------------------------------
--local tmr = tmr
--local math = math
--local dht = dht
--local bmp085 = bmp085
--local gpio = gpio
--local print = print
--local require = require
--local Debug = Debug
--local package = package
--local table = table
--local string = string

-- Limited to local environment
--setfenv(1,M)
--------------------------------------------------------------------------------
-- Implementation
--------------------------------------------------------------------------------
local function measureDHT()
    -- zde probiha mereni a casovani opakovani
    if (Counter > 0) then
        local result,T,H
        result, T, H = dht.read(PinDHT)
        if (result == 0) then
            Cnt = Cnt + 1
            Tavr = Tavr + T
            Havr = Havr + H
        end
        result,T,H = nil
        Counter = Counter - 1
        tmr.alarm(Casovac, math.random(10,50), 0,  function() measureDHT() end)
        return
    end
    -- zpracujeme vysledky a neni dobre delit nulou
    if (Cnt > 0) then 
        Tavr = Tavr / Cnt;
        Havr = Havr / Cnt;

        if Debug == 1 then 
            print ("m>22Temp: "..Tavr)
            print ("m>22Humi: "..Havr)
        end
        
        Data[Prefix.."t22"] = Tavr
        Data[Prefix.."h22"] = Havr
        Data[Prefix.."dht_ok"] = 1
    else
        if Debug == 1 then 
            print("m>DHT not found") 
        end
        Data[Prefix.."dht_ok"] = 0
    end
    Counter,Tavr,Havr,Cnt = nil,nil,nil,nil
    -- vypnu na nulu datovy vodic
        gpio.mode(PinDHT,gpio.OUTPUT)
        gpio.write(PinDHT,gpio.LOW)
    PinDHT = nil
    if PinDHTpower ~= nil then
        -- uklid napajeni DHT22
            gpio.write(PinDHTpower,gpio.LOW)
        PinDHTpower = nil
    end
    Finished = (tmr.now()+1) -- ukonci mereni a da echo odesilaci a tim konci tento proces
end

local function setup(_casovac,_prefix,_dhtpin,_dhtpowerpin) 
    Casovac = _casovac or 3
    Prefix = _prefix or "" 
    PinDHT = _dhtpin
    PinDHTpower = _dhtpiwerpin
    Data = {}
    Finished = 0
    if (nil ~= PinDHT) then
        Counter = 20
        Tavr,Havr,Cnt = 0,0,0
        -- a zacina mereni, jen se nacasuje, pro pripad ze by byl pouzit napajeci pin je dobre pockat 
        if PinDHTpower ~= nil then
            gpio.mode(PinDHTpower,gpio.OUTPUT)
            gpio.write(PinDHTpower,gpio.HIGH) 
            -- vypinani DHT behem sleepu usetri kolem 10uA ale nefunguje to moc dobre
            tmr.alarm(Casovac, 200, 0,  function() measureDHT() end)
        else
            tmr.alarm(Casovac, 25, 0,  function() measureDHT() end)
        end
    end
    return Casovac
end
M.setup = setup

local function status()
    return Finished
end
M.status = status

local function getvalues()
    if Finished > 0 then
        return Data
    else
        return {}
    end
end
M.getvalues = getvalues

-- Return module table
return M
