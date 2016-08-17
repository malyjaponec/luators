--------------------------------------------------------------------------------
-- Sensor measurement - DALAS
-- 
-- setup(casovac,prefix,dalaspin) 
-- - nastavi casovac, ktery bude knihovna pouziva a spusti mereni
-- - prefix pro identifikaci zarizeni v pripade ze vice zarizeni posila v jednom node
-- - nastavi pin pro mereni dalasu
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
local PinDALAS,PinDALAS2
local Name
local Finished,sensors = 0,0
local t,taddr,tsnimacu,tcount
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
local function AddressInHex(IN)
    local hexkody,out,high,low,w="0123456789ABCDEF",""
    for w = 1,8 do 
        high = (math.floor(IN:byte(w)) / 16) + 1
        low = ((IN:byte(w)) % 16) + 1
        out = out..string.sub(hexkody,high,high)..string.sub(hexkody,low,low)
    end
    return out
end

local function cleanupDALAS()
    sensors = sensors + tsnimacu
    tsnimacu = nil
    if PinDALAS2 ~= nil then
        PinDALAS,PinDALAS2 = PinDALAS2,nil
        taddr = nil
        tmr.alarm(Casovac, 10, 0,  function() startDALAS2() end)       
    else
        taddr,t = nil,nil
        ds18b20 = nil
        package.loaded["ds18b20"] = nil
        Data["t_cnt"] = sensors
        Casovac,Prefix,PinDALAS,sensors = nil,nil,nil,nil
        local time = (tmr.now() - (TimeStartLast*1000 or 0))
        if time <= 0 then time = 1 end
        Finished = time -- ukonci mereni a da echo odesilaci a tim konci tento proces
        time = nil
    end
end

local function readoutDALAS()
    local addr = taddr[tcount] -- vezmu adresu z pole
    local value = t.readNumber(addr) -- vyctu si zmerenou teplotu
    local textaddr = AddressInHex(addr) -- prevod adresy na gex
    addr = nil
    if (value ~= nil) then -- a ted pouze pokud se vycteni povedlo
        value = value/10000 -- teplotu to vraci v desitkach milicelsiu
        Data["t"..textaddr] = value -- data se zaradi do pole zmerenych hodnot
        if Debug == 1 then 
            print(Casovac..">t"..textaddr.." = "..value)
        end
    end
    textaddr,value = nil,nil
    tcount = tcount + 1
    tmr.alarm(Casovac, 25, 0,  function() measureDALAS2() end)
end

local function measureDALAS()
    if tcount > tsnimacu then -- presazen pocet snimacu, konec mereni
        tmr.alarm(Casovac, 25, 0,  function() cleanupDALAS() end)
    else
        local addr = taddr[tcount] -- vezmu adresu z pole
        if addr ~= nil then -- bezpecnostni ochrana kdyby to vratilo nil
            t.startMeasure(addr) -- pozadam dalas o mereni
            addr = nil
            tmr.alarm(Casovac, 750, 0,  function() readoutDALAS() end)
        else
            -- pokud to vrati nulouvou adresu, zkusim dalsi index
            tcount = tcount + 1
            tmr.alarm(Casovac, 25, 0,  function() measureDALAS() end)
        end
    end
end

function measureDALAS2() -- kvuli volani z horni casti kodu kde lokalni funkce jeste neexistuji
    measureDALAS()
end

local function startDALAS()
    if PinDALAS == nil then
        tmr.alarm(Casovac, 25, 0,  function() cleanupDALAS() end)
    else    
        t.setup(PinDALAS)
        taddr = t.addrs() -- nacte adresy vsechn dalasu na sbernici
        if (taddr ~= nil) then
            tsnimacu = table.getn(taddr)
        else
            tsnimacu = 0
        end
        if Debug == 1 then 
            print(Casovac..">sens: "..tsnimacu) -- pocet senzoru 
        end 
        if tsnimacu > 0 then -- jsou nalezeny snimace
            tcount = 1
            tmr.alarm(Casovac, 25, 0,  function() measureDALAS() end)
        else
            tmr.alarm(Casovac, 25, 0,  function() cleanupDALAS() end)
        end
    end
end

function startDALAS2() -- kvuli volani z horni casti kodu kde lokalni funkce jeste neexistuji
    startDALAS()
end

local function setup(_casovac,_dalaspin,_dalaspin2) 
    Casovac = _casovac or 4 
    PinDALAS, PinDALAS2 = _dalaspin,_dalaspin2
    Data = {}
    Finished = 0
    tmr.alarm(Casovac, 25, 0,  function() 
        if Debug == 1 then 
            print(Casovac..">dalas")
        end 
        t = require("ds18b20")
        startDALAS()
    end)
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
