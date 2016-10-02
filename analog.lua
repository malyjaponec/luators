--------------------------------------------------------------------------------
-- Analog measurement
-- 
-- setup(casovac) - nastavi casovac, ktery bude knihovna pouziva a vynuluje
--                  prumerne floating hodnoty a zacne merit
-- status() - vrati zda je mereni dokonceno nebo se jeste meri s casem dokonceni
-- getvalues() - vrati vysledne hodnoty:
--               analog value, floating maximum, floating minimum,
--               floating thres hold, digital value
-- restart() - spusti dalsi opakovani mereni, ktere aktualizuje prumery atd.
--------------------------------------------------------------------------------
-- Set module name as parameter of require
local modname = ...
local M = {}
_G[modname] = M
--------------------------------------------------------------------------------
-- Local used variables
--------------------------------------------------------------------------------
local Casovac
local Repeat
local Minimum
local Maximum
local Average
local Counter
local Data
local Finished = 0
-------------------------------------------------------------------------------
-- Local used modules
--------------------------------------------------------------------------------
-- String module
--local adc = adc
--local tmr = tmr
--local math = math
--local Debug = Debug
--local print = print

-- Limited to local environment
--setfenv(1,M)
--------------------------------------------------------------------------------
-- Implementation
--------------------------------------------------------------------------------
local function mesureanalog()
    local AnalogValue = adc.read(0)
    if (AnalogValue > Maximum) then 
        Maximum = AnalogValue
    end
    if (AnalogValue < Minimum) then 
        Minimum = AnalogValue
    end
    Average = Average + AnalogValue
    Counter = Counter + 1
    if Counter < Repeat then
        tmr.alarm(Casovac, math.random(5,15), 0,  function() mesureanalog() end)
    else
        Counter = nil
        Average = Average / Repeat
        Data["A_avr"] = Average
        Data["A_max"] = Maximum
        Data["A_min"] = Minimum
        if Debug == 1 then 
            print ("A_avr="..Average)
            print ("A_max="..Maximum)
            print ("A_min="..Minimum)
        end
        Average,Maximum,Minimum = nil,nil,nil
        Casovac,Repeat = nil,nil
        local time = (tmr.now() - ((TimeStartLast or 0) * 1000))
        if time <= 0 then time = 1 end
        Finished = time -- ukonci mereni a da echo odesilaci a tim konci tento proces
        time = nil
    end
end  

local function setup(_casovac,_repeat)
    Casovac = _casovac or 2
    Repeat = _repeat or 1
    Minimum = 1024
    Maximum = 0
    Average = 0
    Counter = 0
    Data = {}
    Finished = 0
    adc.read(0) -- nekdy prvni prevod vrati nesmysl
    tmr.alarm(Casovac, math.random(10), 0,  function() mesureanalog() end)
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
