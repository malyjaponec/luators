--------------------------------------------------------------------------------
-- Sber dat ze senzoru HX711
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
local Casovac
local Data
local Finished = 0
-------------------------------------------------------------------------------
-- Local used modules
--------------------------------------------------------------------------------
--local tmr = tmr
--local math = math
--local hx711 = hx711
--local print = print
--local Debug = Debug

-- Limited to local environment
--setfenv(1,M)
--------------------------------------------------------------------------------
-- Implementation
--------------------------------------------------------------------------------

local function startWEIGHT(_busClock,_busData,_podminka)
	-- Testuji zda je sbernice volna, toto mi vrati funkce podminka 
	if _podminka() ~= 0 then 
		-- pokud to vrati kladne nenulove cislo
		if Debug == 1 then 
			print ("WT>start")
		end
		local ok_inputs = 0
		local key,data
		for key,data in pairs(_busData) do 
			if Debug == 1 then 
				print ("WT>in:"..key)
			end
			hx711.init(_busClock, data) -- nastavim zbernici 
			local vysledek = hx711.read(0) -- prectu data
			if vysledek ~= nil then
				if Debug == 1 then 
					print ("WT>w="..vysledek)
				end
				Data["w_"..key] = vysledek
				ok_inputs = ok_inputs + 1
			end
		end
		data,key = nil,nil
		Data["w_ok"] = ok_inputs
		vysledek,ok_inputs = nil,nil
		local time = (tmr.now() - ((TimeStartLast or 0) * 1000))
		if time <= 0 then time = 1 end
		Finished = time -- ukonci mereni a da echo odesilaci a tim konci tento proces
		time = nil
	else
		-- pokud to vraci nulu tak znova casuji test jestli uz mohu zbernici pouzit
		tmr.alarm(Casovac, 100, 0,  function() startWEIGHT(_busClock,_busData,_podminka) end) 
	end
end

local function setup(_casovac,_busCL,_busDA,_podminka) 
    Casovac = _casovac or 6
	if _podminka == nil then _podminka = function() return 1 end end
    Data = {}
    Finished = 0
	-- startuji casovani mereni
    if _busCL ~= nil and _busDA ~= nil then
		tmr.alarm(Casovac, 20, 0,  function() startWEIGHT(_busCL,_busDA,_podminka) end) 
	else			
		Finished = 1 -- cas nenulovy, znaci ze jest dokonceno, pri chybe to tahle nastavim
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