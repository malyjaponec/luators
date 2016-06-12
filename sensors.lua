--------------------------------------------------------------------------------
-- Sensor measurement
-- 
-- setup(casovac,dhtpin,dhtpowerpin,dalaspin,dalasphantom) 
-- - nastavi casovac, ktery bude knihovna pouziva a spusti mereni
-- - nastavi pin pro mereni dht
-- - nastavi pin pro napajeni dht
-- - nastavi pin pro mereni dalasu
-- - nastavi zda dalas je phantom nebo ma napajeni
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
local PinDALAS
local Phantom
local Finished = 0
local t
local taddr

-------------------------------------------------------------------------------
-- Local used modules
--------------------------------------------------------------------------------
-- Timer module
local tmr = tmr
-- Mathematic module
local math = math
-- Debug
local Debug = Debug

-- Limited to local environment
setfenv(1,M)
--------------------------------------------------------------------------------
-- Implementation
--------------------------------------------------------------------------------

--local function pahntomreadout()
--    vycte hodnotu a zavola poantom command()
--end
--
--local function pahntomcommand()
--    prvnimu v seznamu posle prikaz pro mereni
--    s casovym zpozdenim zavola pantomreadout()
--    pokud je nahodou seznam prazdny zakonci mereni
--end
--
--local function readoutDALAS()
--
--end
--
--local function measureDALAS()
--    if 
--    -- pozada jeden dalas o zmereni teploty
--
--    -- skoci readout
--
--end
--
local function prepareDALAS()
  Finished = tmr.now()+1

--
--    if PinDALAS == nil then
--        tmr.alarm(Casovac, 25, 0,  function() finishDALAS() end)
--    else
--      t = require("ds18b20")
--        t.setup(PinDALAS)
--        local taddr = t.addrs() -- nacte adresy do lokalniho pole
--        local pocetsnimacu = 0
--        if (taddr ~= nil) then
--            pocetsnimacu = table.getn(addrs1)
--            if Debug == 1
--                print("m>temp sensors: "..pocetsnimacu) -- pocet senzoru 
--            end
--            Data[Prefix.."t_cnt"] = pocetsnimacu
--        end
--        if pocet snimacu == 0 then -- zadne snimace nenalezeny preskocime mereni
--            tmr.alarm(Casovac, 25, 0,  function() finishDALAS() end)
--        else
--            tmr.alarm(Casovac, 25, 0,  function() measureDALAS() end)
--        end
--    end
end

local function finishDHT()
    
    if PinDHTpower ~= nil then
        -- uklid napajeni DHT22
        gpio.write(PinDHTpower,gpio.LOW)
    end
    if PinDHT ~= nil then
        -- vypnu na nulu i datovy vodic
        gpio.mode(PinDHT,gpio.OUTPUT)
        gpio.write(PinDHT,gpio.LOW)
    end

    tmr.alarm(Casovac, 25, 0,  function() prepareDALAS() end)    
end

local function measureDHT()

    if PinDHT ~= nil then
        local result,T,H
        local Tavr,Havr,Cnt = 0,0,0
        local counter = 20 -- urcuje pocet opakovani mereni z DHT
        while (counter > 0) do
            result, T, H = dht.read(DHT22pin)
            if (result == 0) then
                Cnt = Cnt + 1
                Tavr = Tavr + T
                Havr = Havr + H
            end
            counter = counter - 1
        end
        
        if (Cnt > 0) then
            Tavr = Tavr / Cnt;
            Havr = Havr / Cnt;
    
            if Debug == 1 then 
                print ("m>Temp: "..Tavr)
                print ("m>Humi: "..Havr)
            end
            
            Data[Prefix.."t22"] = Tint
            Data[Prefix.."h22"] = Hint
            Data[Prefix.."dht_ok"] = 1
        else
            
            if Debug == 1 then print("m>DHT not found") end
            
            Data[Prefix.."dht_ok"] = 0
        end
    end

    tmr.alarm(Casovac, 25, 0,  function() finishDHT() end)    
end

local function prepareDHT()

    if PinDHTpower ~= nil then
        gpio.mode(PinDHTpower,gpio.OUTPUT)
        gpio.write(PinDHTpower,gpio.HIGH) 
        -- vypinani DHT behem sleepu usetri kolem 10uA
    end

    tmr.alarm(Casovac, 25, 0,  function() measureDHT() end)
end  

function setup(_casovac,_prefix,_dhtpin,_dhtpowerpin,_dalaspin,_dalasphantom) 
   
    Casovac = _casovac or 4 -- pokud to neuvedu 
    Prefix = _prefix or "noid" -- pokud neuvedu
    PinDHT = _dhtpin
    PinDHTpower = _dhtpiwerpin
    PinDALAS = _dalaspin
    Phantom = _dalasphantom
    Data = {}
    Finished = 0
  
    tmr.alarm(Casovac, 25, 0,  function() prepareDHT() end)
    
    return Casovac
end

function status()

    return Finished
end

function getvalues()

    if Finished > 0 then
        return Data
    else
        return {}
    end
end

-- Return module table
return M
