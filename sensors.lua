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

-------------------------------------------------------------------------------
-- Local used modules
--------------------------------------------------------------------------------
-- Timer module
local tmr = tmr
-- Mathematic module
local math = math

-- Limited to local environment
setfenv(1,M)
--------------------------------------------------------------------------------
-- Implementation
--------------------------------------------------------------------------------
local function pahntomreadout()
    vycte hodnotu a zavola poantom command()
end

local function pahntomcommand()
    prvnimu v seznamu posle prikaz pro mereni
    s casovym zpozdenim zavola pantomreadout()
    pokud je nahodou seznam prazdny zakonci mereni
end

local function pahntomscan()
    naplni pole adres dalasu 
    a zavola phandomcommand()
end

local function readoutdalas()
   vycte hodnoty s dalasu 
   a zakonci mereni
end

local function commandDALAS()
    if PinDALAS == nil then
        tmr.alarm(Casovac, 50, 0,  function() measuredatlas() end)
        

    else
   pozada o mereni vsechny nalezene dalasy
   s casovym zpozdenim zavola readoutdalas
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

    tmr.alarm(Casovac, 25, 0,  function() commandDALAS() end)    
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
                print ("Temp: "..Tavr)
                print ("Humi: "..Havr)
    |       end
            
            Data[ReportFieldPrefix."t22"] = Tint
            Fields[ReportFieldPrefix.."h22"] = Hint
            Fields[ReportFieldPrefix.."dht_ok"] = 1
        else
            Fields[ReportFieldPrefix.."dht_ok"] = 0
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

function setup(_casovac,_dhtpin,_dhtpowerpin,_dalaspin,_dalasphantom) 
   
    Casovac = _casovac or 4 -- pokud to neuvedu 
    PinDHT = _dhtpin
    PinDHTpower = _dhtpiwerpin
    PinDALAS = _dalaspin
    Phantom = _dalasphantom
    Data = {}
    Finished = 0
  
    tmr.alarm(Casovac, 50, 0,  function() prepareDHT() end)
    
    return Casovac
end

function status()

    return Finished
end

function getvalues()

    if Finished == 1 then
        return Data
    else
        return {"inprogress"=1}
end

-- Return module table
return M
