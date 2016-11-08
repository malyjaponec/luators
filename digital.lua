--------------------------------------------------------------------------------
-- Digital measurement
-- 
-- capture(seznam pinu) - precte digitalni piny
-- getvalues() - vrati pole hodnot na pinech
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
	   Data["io"..gpionumber] = gpio.read(gpionumber)
    end
end
M.capture = capture

local function getvalues()
    return Data
end
M.getvalues = getvalues

-- Return module table
return M
