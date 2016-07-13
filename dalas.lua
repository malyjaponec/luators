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
local Prefix
local Data
local PinDALAS
local Finished = 0
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
    taddr,t = nil,nil
    ds18b20 = nil
    package.loaded["ds18b20"] = nil
    Casovac,Prefix,PinDALAS = nil,nil,nil
    Finished = tmr.now()+1 -- ukonci mereni a da echo odesilaci a tim konci tento proces
end

local function readoutDALAS()
    local addr = taddr[tcount] -- vezmu adresu z pole
    local value = t.readNumber(addr) -- vyctu si zmerenou teplotu
    local textaddr = AddressInHex(addr) -- prevod adresy na gex
    addr = nil
    if (value ~= nil) then -- a ted pouze pokud se vycteni povedlo
        value = value/10000 -- teplotu to vraci v desitkach milicelsiu
        Data[Prefix.."t"..textaddr] = value -- data se zaradi do pole zmerenych hodnot
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
        tmr.alarm(Casovac, 25, 0,  function() prepareBARO() end)
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

function measureDALAS2()
    measureDALAS()
end

local function startDALAS()
    if Debug == 1 then 
        print(Casovac..">dalas")
    end 
    if PinDALAS ~= nil then
        t = require("ds18b20")
        t.setup(PinDALAS)
        taddr = t.addrs() -- nacte adresy vsechn dalasu na sbernici
        if (taddr ~= nil) then
            tsnimacu = table.getn(taddr)
            Data[Prefix.."t_cnt"] = tsnimacu
        else
            tsnimacu = 0
        end
        if Debug == 1 then 
            print(Casovac..">temp sensors: "..tsnimacu) -- pocet senzoru 
        end 
        if tsnimacu > 0 then -- jsou nalezeny snimace
            tcount = 1
            tmr.alarm(Casovac, 25, 0,  function() measureDALAS() end)
        else
            tmr.alarm(Casovac, 25, 0,  function() cleanupDALAS() end)
        end
    end
end

local function setup(_casovac,_prefix,_dalaspin) 
    Casovac = _casovac or 4 
    Prefix = _prefix or ""
    PinDALAS = _dalaspin
    Data = {}
    Finished = 0
    tmr.alarm(Casovac, 25, 0,  function() startDALAS() end)
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
