--------------------------------------------------------------------------------
-- RGB led driver
-- 
-- 
-- 
-- 
--------------------------------------------------------------------------------

-- Set module name as parameter of require
local modname = ...
local M = {}
_G[modname] = M
--------------------------------------------------------------------------------
-- Local used variables
--------------------------------------------------------------------------------
-- ulozeni vyvodu RGB led
local RedIO
local GreenIO 
local BlueIO 
-- inicializace ok
--local Configured = 0

-------------------------------------------------------------------------------
-- Local used modules
--------------------------------------------------------------------------------
-- String module
local string = string
-- gpio module
local gpio = gpio

-- Limited to local environment
setfenv(1,M)
--------------------------------------------------------------------------------
-- Implementation
--------------------------------------------------------------------------------
-- Konfigurace GPIO pinu s defaultem pro kit
function setup(_red,_green,_blue)
    --Configured = 0
    RedIO = _red
    if RedIO == nil then
        RedIO = 8 -- GPIO 15
    end
    GreenIO = _green
    if GreenIO == nil then
        GreenIO = 6 -- GPIO 12 
    end
    BlueIO = _blue
    if BlueIO == nil then
        BlueIO = 7 -- GPIO 13
    end
    --Configured = 1

    gpio.mode(RedIO, gpio.OUTPUT)     
    gpio.write(RedIO, gpio.LOW)
    gpio.mode(GreenIO, gpio.OUTPUT)     
    gpio.write(GreenIO, gpio.LOW)
    gpio.mode(BlueIO, gpio.OUTPUT)     
    gpio.write(BlueIO, gpio.LOW)
    
    return 1
end

-- Nastaveni cistych barev
function set(_color)
	if Configured == 0 then
		return 0
	end
    local R,G,B = gpio.LOW,gpio.LOW,gpio.LOW
    if (_color == "red") then
        R = gpio.HIGH
    end        
    if (_color == "green") then
        G = gpio.HIGH
    end        
    if (_color == "blue") then
        B = gpio.HIGH
    end        
    if (_color == "orange") then
        R = gpio.HIGH
        G = gpio.HIGH
    end        
    if (_color == "magenta") then
        R = gpio.HIGH
        B = gpio.HIGH
    end        
    if (_color == "cyan") then
        G = gpio.HIGH
        B = gpio.HIGH
    end        
    if (_color == "white") then
        R = gpio.HIGH
        G = gpio.HIGH
        B = gpio.HIGH
    end        

    gpio.write(RedIO, R)
    gpio.write(GreenIO, G)
    gpio.write(BlueIO, B)
    return 1
end  

-- Return module table
return M
