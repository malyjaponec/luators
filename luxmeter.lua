--------------------------------------------------------------------------------
-- Sber dat ze senzoru MAX44009
-- 
-- setup(casovac,prefix,pinA,pinB) 
-- - nastavi casovac, ktery bude knihovna pouziva a spusti mereni
-- - nastavi piny pro komunikaci I2C a ja nevim ktery je ktery, resim metodou pokus omyl
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
local Adresa = 1001 0100 -- alternativne 1001 0110 pokud je na A0 bit pripojeno VCC
local Casovac
local Data
local Finished = 0
-------------------------------------------------------------------------------
-- Local used modules
--------------------------------------------------------------------------------
--local tmr = tmr
--local math = math
--local bmp085 = bmp085
--local print = print
--local Debug = Debug

-- Limited to local environment
--setfenv(1,M)
--------------------------------------------------------------------------------
-- Implementation
--------------------------------------------------------------------------------

local function measureLUX()
	-- vycteni z I2C

	local id = 0
	i2c.start(id)
    i2c.address(id, Adresa, i2c.TRANSMITTER)
    i2c.write(id, 0x03) -- adresa prvniho bajtu co me zajima je 3 a druhy je za nim
	i2c.stop(id)
	
    i2c.start(id)
    i2c.address(id, dev_addr, i2c.RECEIVER)
    local B3,B4
	B3,B4 = i2c.read(id, 2)
    i2c.stop(id)
	id = nil
	
	-- vypocet dat
	
	exponent = B3/16 -- pouze horni 4 bity jsou exponent
	mantisa = 
	
	if Debug == 1 then 
		print ("LX>="..vysledek)
	end
		
	Data["lux"] = vysledek
	
	hodnota_h,hodnota_l,vysledek = nil, nil, nil
	Adresa = 
	
	local time = (tmr.now() - ((TimeStartLast or 0) * 1000))
    if time <= 0 then time = 1 end
    Finished = time -- ukonci mereni a da echo odesilaci a tim konci tento proces
    time = nil
end

local function preapreLUX(_busA,_busB,_podminka)
	-- Testuji zda je zbernice volna, toto mi vrati funkce podminka 
	if _podminka() ~= 0 then 
		-- pokud to vrati kladne nenulove cislo
		i2c.setup(0, _busA, _busB, i2c.SLOW) -- nastavim zbernici a funkci co neco vycte
		measureLUX()
	else
		-- pokud to vraci nulu tak znova casuji test
		tmr.alarm(Casovac, 200, 0,  function() measureLUX(_busA,_busB,_podminka) end) 
	end
end

local function setup(_casovac,_busA,_busB,_podminka) 
    Casovac = _casovac or 6
	if _podminka == nil then _podminka() = function() return 1 end end
    Data = {}
    Finished = 0
    -- startuji mereni
    if _busA ~= nil and _busB ~= nil then
			
		tmr.alarm(Casovac, 20, 0,  function() measureLUX(_busA,_busB,_podminka) end) 

	else			
		Finished = 1 -- cas jedna ale dokonceno, pri chybe to tahle nastavim
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