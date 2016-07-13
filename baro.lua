--------------------------------------------------------------------------------
-- Sensor measurement
-- 
-- setup(casovac,prefix,pinA,pinB) 
-- - nastavi casovac, ktery bude knihovna pouziva a spusti mereni
-- - prefix pro identifikaci zarizeni v pripade ze vice zarizeni posila v jednom node
-- - nastavi piny pro mereni barometru, je to I2C a ja nevim ktery je ktery, resim metodou pokus omyl
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
local Finished = 0
local p,t,tcount
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
local function finishBARO()
    p = p + (bmp085.pressure() / 100) -- tlak
    t = t + (bmp085.temperature() / 10) -- teplota
    tcount = tcount + 1
    if (tcount <= 10) then
        tmr.alarm(Casovac, math.random(10,50), 0,  function() finishBARO() end)
        return
    end
    p,t = p/tcount, t/tcount -- nepocitam s tim ze by se mereni nepovedlo, vlastne to vzdy neco vycet
    if Debug == 1 then 
        print (Casovac..">P="..p)
        print (Casovac..">T(B)="..t)
    end
    Data[Prefix.."tlak"] = p
    Data[Prefix.."teplota_b"] = t
    p,t = nil,nil
    Prefix,Casovac = nil,nil
    Finished = tmr.now()+1 -- ukonci mereni a da echo odesilaci a tim konci tento proces
end

local function setup(_casovac,_prefix,_baroA,_baroB) 
    Casovac = _casovac or 5
    Prefix = _prefix or ""
    Data = {}
    Finished = 0
    -- startuji mereni
    if _baroA ~= nil and _baroB ~= nil then
        bmp085.init(_baroA,_baroB)
        PinBaro = nil
        p,t = 0,0 -- nuluji prumery resp. soucty
        tcount = 0 -- pocitadlo poctu mereni
        tmr.alarm(Casovac, 25, 0,  function() finishBARO() end)
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
