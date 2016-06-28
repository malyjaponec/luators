--------------------------------------------------------------------------------
-- Battery measurement
-- 
-- setup(casovac) - nastavi casovac, ktery bude knihovna pouziva a spusti mereni
-- getvalues() - vrati minimum a maximum a pocet mereni a taky zastavi dalsi mereni
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
local Minimum
local Maximum
local Counter
-------------------------------------------------------------------------------
-- Local used modules
--------------------------------------------------------------------------------
-- String module
--local adc = adc
--local tmr = tmr
--local math = math
--local Debug = Debug

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
    Counter = Counter + 1
    tmr.alarm(Casovac, math.random(5,30), 0,  function() mesureanalog() end)
    return 1
end  

local function setup(_casovac)
    Casovac = _casovac or 2
    Minimum = 1024
    Maximum = 0
    Counter = 0
    adc.read(0) -- nekdy prvni prevod vrati nesmysl
    tmr.alarm(Casovac, math.random(5,30), 0,  function() mesureanalog() end)
    return Casovac
end
M.setup = setup

local function getvalues()
    tmr.stop(Casovac)
    return Minimum,Maximum,Counter
end
M.getvalues = getvalues

-- Return module table
return M
