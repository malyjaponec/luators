--------------------------------------------------------------------------------
-- Sensor measurement
-- 
-- setup(casovac,prefix,pinA,pinB) 
-- - nastavi casovac, ktery bude knihovna pouziva a spusti mereni
-- - prefix pro identifikaci zarizeni v pripade ze vice zarizeni posila v jednom node
-- - nastavi piny pro mereni barometru, je to I2C a ja nevim ktery je ktery, resim metodou pokus omyl
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
local SeaLevel = 512 -- Tady se musi nastavit nadmorska vyska aby tlak prepocteny na hladinu more byl spravne
local Casovac
local Data
local Finished = 0
local p,t,h,ps
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
local function finishTRIPLE()
    t,p,h,ps = bme280.read(SeaLevel)

	if (nil ~= t) and (nil ~= h) then -- kontroluji pokud by to nahodou nevratilo teplotu tak mereni neprobehlo
		d = bme280.dewpoint(h, t)

		-- uprava na jednotky C,hPa,%,hPa
		t = t / 100 or -100
		p = p / 1000 
		h = h / 1000 
		ps = ps / 1000
		d = d / 100
		
		if Debug == 1 then 
			print ("TR>P="..p)
			print ("TR>T="..t)
			print ("TR>H="..h)
		end

		Data["3tlak"] = p
		Data["3tlak0"] = ps
		Data["3teplo"] = t
		Data["3vlhko"] = h
		Data["3rosa"] = d
		Data["3ok"] = 1 -- indikace ze senzor je ok
	end

    p,t,h,ps,d = nil,nil,nil,nil,nil
    
	local time = (tmr.now() - ((TimeStartLast or 0) * 1000))
    if time <= 0 then time = 1 end
    Finished = time -- ukonci mereni a da echo odesilaci a tim konci tento proces
    time = nil
end

local function setup(_casovac,_baroA,_baroB) 
    Casovac = _casovac or 5
    Data = {}
    Finished = 0
    -- startuji mereni
    if _baroA ~= nil and _baroB ~= nil then
		if Debug == 1 then 
			print ("TR>start")
		end
		-- stara verze initu, funguje a krici warovani
			--local result = bme280.init(_baroA,_baroB) -- inicializace senzoru, standardni parametry
		-- nova verze initue
			i2c.setup(0, _baroA,_baroB, i2c.SLOW)
			local result = bme280.setup() -- inicializace senzoru, standardni parametry
		-- init konec
		if result ~= nil and result == 2 then -- je to spravny senzor a je pripojen 
			tmr.alarm(Casovac, 170, 0,  function() finishTRIPLE() end) -- volam to pres casovac tak aby se vycteni hodnoty zpozdilo od initu
		else
			if Debug == 1 then 
				print ("TR>fail")
				if result ~= nil then
					print("TR>r="..result)
				end
			end
			Data["3ok"] = 0 -- indikace ze senzor nefunguje
			Finished = 1 -- cas jedna ale dokonceno, pri chybe to tahle nastavim
		end
		result = nil
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