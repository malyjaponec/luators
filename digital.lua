--------------------------------------------------------------------------------
-- Digital measurement
-- 
-- capture(seznam pinu) - precte digitalni piny
-- getvalues() - vrati pole hodnot na pinech
-- params: seznam pgio pinu, pokud se pricte 64, tak hodnotu vyctenou z pinu
-- 		   logicky neguje a pokud se pricte 128, tak pred ctenim zapne pull up
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

-------------------------------------------------------------------------------
-- Local used modules
--------------------------------------------------------------------------------
-- String module
--local Debug = Debug
--local print = print

-- Limited to local environment
--setfenv(1,M)

--------------------------------------------------------------------------------
-- Implementation
--------------------------------------------------------------------------------
local function capture(...)
    Data = {}
    for i = 1, select("#",...) do
        local gpionumber = select(i,...)
	    if gpionumber >= 128 then -- je tam pozadavek na zapnuti pull upu
			gpio.mode(gpionumber,gpio.INPUT,gpio.PULLUP)
			gpionumber = gpionumber - 128
		end
		if gpionumber >= 64 then -- je pozadavek hodnotu negovat
			gpionumber = gpionumber - 64
			Data["io"..gpionumber] = 1 - gpio.read(gpionumber)
		else
			Data["io"..gpionumber] = gpio.read(gpionumber)
		end
    end
end
M.capture = capture

local function getvalues()
    return Data
end
M.getvalues = getvalues

-- Return module table
return M
