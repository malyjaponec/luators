--------------------------------------------------------------------------------
-- Battery measurement
-- 
-- setup(casovac) - nastavi casovac, ktery bude knihovna pouziva a spusti mereni
-- stop() - zastavi mereni
-- getvalues() - vrati minimum a maximum a pocet mereni
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
local adc = adc
-- Timer module
local tmr = tmr
-- Mathematic module
local math = math

-- Limited to local environment
setfenv(1,M)
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

    tmr.alarm(Casovac, math.random(2,10), 0,  function() mesureanalog() end)
   
    return 1
end  

function setup(_casovac)
   
    Casovac = _casovac or 5 -- pokud to neuvedu 
    Minimum = 1024
    Maximum = 0
    Counter = 0

    adc.read(0) -- nekdy prvni prevod vrati nesmysl

    tmr.alarm(Casovac, math.random(2,10), 0,  function() mesureanalog() end)
    
    return Casovac
end

function stop()

    tmr.stop(Casovac)
end

function getvalues()

    return Minimum,Maximum,Counter
end

-- Return module table
return M
