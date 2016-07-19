--------------------------------------------------------------------------------
-- Battery measurement
-- 
-- setup(casovac) - nastavi casovac, ktery bude knihovna pouziva a spusti mereni
-- getvalues() - vrati minimum a maximum a pocet mereni a taky zastavi dalsi mereni
-- getlight() - zmeri parazitni metoodu svetlo (k baterii je pripojen jeste fotodpor), pouzito ve foliaku
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
local LightPIN
local Minimum
local Maximum
local Counter
-------------------------------------------------------------------------------
-- Local used modules
--------------------------------------------------------------------------------
-- String module
local adc = adc
local tmr = tmr
local math = math
local Debug = Debug
local gpio = gpio

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
    tmr.alarm(Casovac, math.random(5,15), 0,  function() mesureanalog() end)
    return 1
end  

local function setup(_casovac,_lightpin)
    Casovac = _casovac or 2
    LightPIN = _lightpin
    Minimum = 1024
    Maximum = 0
    Counter = 0
    adc.read(0) -- nekdy prvni prevod vrati nesmysl
    if LightPin ~= nil then -- je definovan pin pro mereni svetla
        -- musim ho prepnout na high aby neovlivnoval mereni baterie
        gpio.mode(Lightpin,gpio.OUTPUT)
        gpio.write(Lightpin,gpio.HIGH) 
    end
    tmr.alarm(Casovac, math.random(5,15), 0,  function() mesureanalog() end)
    return Casovac
end
M.setup = setup

local function getvalues()
    tmr.stop(Casovac)
    return Minimum,Maximum,Counter
end
M.getvalues = getvalues

local function getlight()
    if LightPIN == nil then return -1 end -- ochrana proti nespravnemu pusteni
    tmr.stop(Casovac)
    gpio.write(LightPIN,gpio.LOW) -- prijim fotoodpor na zem, cimz se pripravim na mereni svetla misto baterie
    local light = 0
    for q = 1,10,1 do
       light = light + adc.read(0)
    end
    gpio.write(LightPIN,gpio.HIGH) -- fotoodpor na 1, tedy nepotece skrz nej nic
    return light/10
end
M.getlight = getlight

-- Return module table
return M
