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
local Adresa = 0x4A
-- adresa je 1001 0100 alternativne 1001 0110 pokud je na A0 bit pripojeno VCC
-- posledni nejnizsi bit je 0/1 podle operace cteni/zapis
-- jenze do knihovny se posila 7 bitove cislo a ona si za to da posledni bit
-- cili adresy jsou 01001010 resp. 01001011 tedy 4A nebo 4B
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
	i2c.start(id)
    i2c.address(id, Adresa, i2c.RECEIVER)
	local reg3 = i2c.read(id, 1)
	i2c.start(id)
    i2c.address(id, Adresa, i2c.TRANSMITTER)
    i2c.write(id, 0x04) -- adresa 
	i2c.start(id)
    i2c.address(id, Adresa, i2c.RECEIVER)
	local reg4 = i2c.read(id, 1)
    i2c.stop(id)
	id = nil

	if reg3:byte(1) == 255 and reg4:byte(1) == 255 then
		-- nezapojeny senzor, hodnota maximalni kterou to asi nikdy nedosahne
		if Debug == 1 then 
			print ("LX>failed")
		end
		reg3,reg4 = nil, nil
		Data["l_ok"] = 0
	else
		-- vypocet dat
		local exponent = bit.band( bit.rshift(reg3:byte(1),4) , 0x0F) -- pouze horni 4 bity jsou exponent
		local mantisa = bit.bor( bit.lshift( bit.band(reg3:byte(1),0x0F),4) , bit.band(reg4:byte(1),0xF) ) -- slozeni ze dvou bajtu
		reg3, reg4 = nil, nil
		local vysledek = bit.lshift(2,exponent) * mantisa * 0.045
		exponent, mantisa = nil, nil
	
		if Debug == 1 then 
			print ("LX>="..vysledek)
		end
		Data["lux"] = vysledek
		Data["l_ok"] = 1
		vysledek = nil
	end
	local time = (tmr.now() - ((TimeStartLast or 0) * 1000))
    if time <= 0 then time = 1 end
    Finished = time -- ukonci mereni a da echo odesilaci a tim konci tento proces
    time = nil
end

local function preapreLUX(_busA,_busB,_podminka)
	-- Testuji zda je zbernice volna, toto mi vrati funkce podminka 
	if _podminka() ~= 0 then 
		-- pokud to vrati kladne nenulove cislo
		if Debug == 1 then 
			print ("LX>start")
		end
		i2c.setup(0, _busA, _busB, i2c.SLOW) -- nastavim zbernici a funkci co neco vycte
		measureLUX()
	else
		-- pokud to vraci nulu tak znova casuji test
		tmr.alarm(Casovac, 100, 0,  function() preapreLUX(_busA,_busB,_podminka) end) 
	end
end

local function setup(_casovac,_busA,_busB,_podminka) 
    Casovac = _casovac or 6
	if _podminka == nil then _podminka = function() return 1 end end
    Data = {}
    Finished = 0
    -- startuji mereni
    if _busA ~= nil and _busB ~= nil then
		tmr.alarm(Casovac, 20, 0,  function() preapreLUX(_busA,_busB,_podminka) end) 
		
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