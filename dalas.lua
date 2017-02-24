--------------------------------------------------------------------------------
-- Sensor measurement - DALAS
-- 
-- setup(casovac,prefix,dalaspin,dalaspin2) 
-- - nastavi casovac, ktery bude knihovna pouziva a spusti mereni
-- - prefix pro identifikaci zarizeni v pripade ze vice zarizeni posila v jednom node
-- - nastavi pin pro mereni dalasu
-- - prvni pin vyzaduje napajeni 3 dratove, druhy pin respektuje phantom napajeni
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
local PinDALAS,PinDALAS2,PinPOWER
local Name
local Finished = 0
local sensors,tsnimacu
local t,taddr,tcount
-- Nastaveno pro 3 dratove napajeni, druhy kanal potom prehazi hodnoty tak
-- aby to fungovalo s fantomovym napajenim
local CommandDelay = 25
local ReadoutDelay = 750

-------------------------------------------------------------------------------
-- Local used modules
--------------------------------------------------------------------------------
--local tmr = tmr
--local math = math
--local dht = dht
--local bmp085 = bmp085
--local gpio = gpio
--local print = print
--local require = require
--local Debug = Debug
--local package = package
--local table = table
--local string = string

-- Limited to local environment
--setfenv(1,M)
--------------------------------------------------------------------------------
-- Implementation
--------------------------------------------------------------------------------
local function AddressInHex(IN)
    local hexkody,out,high,low,w="0123456789ABCDEF",""
    for w = 1,8 do 
        high = (math.floor(IN:byte(w)) / 16) + 1
        low = ((IN:byte(w)) % 16) + 1
        out = out..string.sub(hexkody,high,high)..string.sub(hexkody,low,low)
    end
    return out
end

local function cleanupDALAS()
    sensors = sensors + tsnimacu
    tsnimacu = nil
    if PinDALAS2 ~= nil then
        PinDALAS,PinDALAS2 = PinDALAS2,nil
		CommandDelay,ReadoutDelay = ReadoutDelay,CommandDelay -- vymenenim promennych zpusobim ze mezi prikazy se ceka dlouho a vycte se to pak bez cekani
        taddr = nil
        tmr.alarm(Casovac, 25, 0,  function() startDALAS2() end)       
    else
        taddr,t = nil,nil
        ds18b20 = nil
        package.loaded["ds18b20"] = nil
        Data["t_cnt"] = sensors
        Casovac,Prefix,PinDALAS,sensors = nil,nil,nil,nil
		if PinPOWER ~= nil then -- pokud je nadefinovan pin na napajeni
			gpio.mode(PinPOWER,gpio.OUTPUT)
			gpio.write(PinPOWER,gpio.LOW) -- prepnu na tvrdo, nepouziva se to na setreni ale na reset sbernice v systemech, kde je nejake ruseni co to rusi
			PinPOWER = nil -- uklid
		end
        local time = (tmr.now() -((TimeStartLast or 0) * 1000))
        if time <= 0 then time = 1 end
        if Debug == 1 then 
			print("DS> end="..time)
		end
        Finished = time -- ukonci mereni a da echo odesilaci a tim konci tento proces
		time = nil
		
    end
end

local function readoutDALAS()
    if tcount > tsnimacu then -- presazen pocet snimacu, konec mereni, cekam dlouhou dobu
        tmr.alarm(Casovac, 25, 0,  function() cleanupDALAS() end)
	else
		local addr = taddr[tcount] -- vezmu adresu z pole
		local value = t.readNumber(addr) -- vyctu si zmerenou teplotu
		local textaddr = AddressInHex(addr) -- prevod adresy na hex
		addr = nil
		if (value ~= nil) then -- a ted pouze pokud se vycteni povedlo
			value = value/10000 -- teplotu to vraci v desitkach milicelsiu
			Data["t"..textaddr] = value -- data se zaradi do pole zmerenych hodnot
			if Debug == 1 then 
				print("DS> "..textaddr.." = "..value)
			end
		end
		textaddr,value = nil,nil
		tcount = tcount + 1
		tmr.alarm(Casovac, 25, 0,  function() readoutDALAS() end)
	end
end

local function measureDALAS()
    if tcount > tsnimacu then -- presazen pocet snimacu, konec mereni
		tcount = 1 -- vycitam zase poporade od prvniho
        tmr.alarm(Casovac, ReadoutDelay, 0,  function() readoutDALAS() end)
    else
        local addr = taddr[tcount] -- vezmu adresu z pole
        if addr ~= nil then -- bezpecnostni ochrana kdyby to vratilo nil
            t.startMeasure(addr) -- pozadam dalas o mereni
            addr = nil
			tcount = tcount + 1
            tmr.alarm(Casovac, CommandDelay, 0,  function() measureDALAS() end) -- cekam kratkou dobu a pustim dalsi mereni
        else
            -- pokud to vrati nulouvou adresu, zkusim dalsi index, bez dlouheho cekani
            tcount = tcount + 1
            tmr.alarm(Casovac, 25, 0,  function() measureDALAS() end)
        end
    end
end

local function startDALAS()
    if PinDALAS == nil then
        tmr.alarm(Casovac, 25, 0,  function() cleanupDALAS() end) -- pin1 nedefinovany, cleanup muze jeste pustint pin2
    else    
        t.setup(PinDALAS)
        taddr = t.addrs() -- nacte adresy vsechn dalasu na sbernici
        if (taddr ~= nil) then
            tsnimacu = table.getn(taddr)
        else
            tsnimacu = 0
        end
        if Debug == 1 then 
            print("DS> sens: "..tsnimacu) -- pocet senzoru 
        end 
        if tsnimacu > 0 then -- jsou nalezeny snimace
            tcount = 1
            tmr.alarm(Casovac, 25, 0,  function() measureDALAS() end)
        else
            tmr.alarm(Casovac, 25, 0,  function() cleanupDALAS() end)
        end
    end
end

function startDALAS2() -- kvuli volani z horni casti kodu kde lokalni funkce jeste neexistuji
    startDALAS()
end

local function setup(_casovac,_dalaspin,_dalaspin2,_dalaspower) 
    Casovac = _casovac or 4 
    PinDALAS, PinDALAS2, PinPOWER = _dalaspin,_dalaspin2,_dalaspower
    Data = {}
    Finished,sensors,tsnimacu = 0,0,0
	local timestart = 25 -- meren se spusti neprodlene cili za 25ms
	if PinPOWER ~= nil then -- pokud je nadefinovan pin na napajeni, prepnu ho do logicke 1
        gpio.mode(PinPOWER,gpio.OUTPUT)
        gpio.write(PinPOWER,gpio.HIGH) 
		timestart = 100 -- mereni se odlozi o 100ms nez nabehne napajeni
	end
    tmr.alarm(Casovac, timestart, 0,  function() 
        if Debug == 1 then 
            print("DS> start")
        end 
        t = require("ds18b20")
        startDALAS()
    end)
	timestart = nil
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
