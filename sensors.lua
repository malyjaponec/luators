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

local function dommanddalas()
   pozada o mereni vsechny nalezene dalasy
   s casovym zpozdenim zavola readoutdalas
end

local function measuredht()

    if PinDHTpower ~= nil then
        gpio.mode(PinDHTpower,gpio.OUTPUT)
        gpio.write(PinDHTpower,gpio.HIGH) 
        -- vypinani DHT behem sleepu usetri kolem 10uA
    end

    tmr.alarm(Casovac, 50, 0,  function() measuredatlas() end)
end  

function setup(_casovac,_dhtpin,_dhtpowerpin,_dalaspin,_dalasphantom) 
   
    Casovac = _casovac or 4 -- pokud to neuvedu 
    PinDHT = _dhtpin
    PinDHTpower = _dhtpiwerpin
    PinDALAS = _dalaspin
    Phantom = _dalasphantom
    Data = {}
    Finished = 0
  
    tmr.alarm(Casovac, 50, 0,  function() measuredht() end)
    
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
