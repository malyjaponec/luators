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
    local value
    for i = 1, select("#",...) do
        local gpionumber = select(i,...)
        local D_neg,D_pul = 0,0
	    if gpionumber >= 128 then -- je tam pozadavek na zapnuti pull upu
			gpionumber = gpionumber - 128
            D_pul = 1
		end
		if gpionumber >= 64 then -- je pozadavek hodnotu negovat
			gpionumber = gpionumber - 64
            D_neg = 1
        end
        if D_pul == 1 then
            gpio.mode(gpionumber,gpio.INPUT,gpio.PULLUP)
        end
        if D_neg == 1 then
			value = 1 - gpio.read(gpionumber)
		else
			value = gpio.read(gpionumber)
		end
        if Debug == 1 then 
                print("DG> "..gpionumber.." = "..value.."("..D_neg..")")
        end
        D_neg,D_pu = nil,nil
        Data["io"..gpionumber] = value
   end
    value = nil
end
M.capture = capture

local function getvalues()
    return Data
end
M.getvalues = getvalues

-- Return module table
return M
