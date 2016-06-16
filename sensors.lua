--------------------------------------------------------------------------------
-- Sensor measurement
-- 
-- setup(casovac,dhtpin,dhtpowerpin,dalaspin,dalasphantom) 
-- - nastavi casovac, ktery bude knihovna pouziva a spusti mereni
-- - nastavi pin pro mereni dht
-- - nastavi pin pro napajeni dht
-- - nastavi pin pro mereni dalasu
-- - nastavi zda dalas je phantom nebo ma napajeni
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
local PinDHT
local PinDHTpower
local PinDALAS
local PinBARO
local Finished = 0
-- pro mereni dalasu
local t
local taddr
local tsnimacu
-- pro barometr
local p
local pt
-- pro oba
local tcount

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

-- Limited to local environment
--setfenv(1,M)

--------------------------------------------------------------------------------
-- Implementation
--------------------------------------------------------------------------------
     
local function finishBARO()
    if PinBaro[1] == nil then
        p,pt = p/tcount, pt/tcount
        if Debug == 1 then 
            print ("Pres="..p)
            print ("Temp(B)="..pt)
        end
        Data[Prefix.."tlak"] = p
        Data[Prefix.."teplota_b"] = pt
        p,t = nil,nil
    end
    -- -- --
    Finished = tmr.now()+1 -- ukonci mereni a da echo odesilaci a tim konci tento proces
end

local function measureBARO()

    p = p + (bmp085.pressure() / 100) -- tlak
    pt = pt + (bmp085.temperature() / 10) -- teplota
    tcount = tcount + 1
    if (tcount >= 10) then
        tmr.alarm(Casovac, 25, 0,  function() finishBARO() end)
    else
        tmr.alarm(Casovac, math.random(10,50), 0,  function() measureBARO() end)
    end
end

local function prepareBARO()
    if PinBaro[1] == nil then
        tmr.alarm(Casovac, 25, 0,  function() finishBARO() end)
    else
        bmp085.init(PinBARO[1],PinBARO[2])
        p,pt = 0,0 -- nuluji prumery resp. soucty
        tcount = 0 -- pocitadlo mereni
        tmr.alarm(Casovac, 25, 0,  function() measureBARO() end)
    end
end

local function finishDALAS()

    if PinDALAS ~= nil then
        gpio.mode(PinDALAS,gpio.OUTPUT)
        gpio.write(PinDALAS,gpio.LOW)
    end
    addr = nil
    taddr = nil
    t = nil
    ds18b20 = nil
    package.loaded["ds18b20"]=nil
    tmr.alarm(Casovac, 25, 0,  function() prepareBARO() end)
end

local function readoutDALAS()

    local addr = taddr[tcount] -- vezmu adresu z pole
    local value = t.readNumber(addr) -- vyctu si zmerenou teplotu
    local textaddr = AddressInHex(addr) -- prevod adresy na gex
    addr = nil
    if (value ~= nil) then -- a ted pouze pokud se vycteni povedlo
        value = value/10000 -- teplotu to vraci v desitkach milicelsiu
        Data[Prefix.."t"..textaddr] = value -- data se zaradi do pole zmerenych hodnot
        if Debug == 1 then 
            print("t"..textaddr.." = "..value)
        end
    end
    textaddr = nil
    value = nil
    tcount = tcount + 1
    tmr.alarm(Casovac, 25, 0,  function() measureDALAS() end)
end

local function measureDALAS()
    
    if tcount > tsnimacu then -- presazen pocet snimacu, konec mereni
        tmr.alarm(Casovac, 25, 0,  function() finishDALAS() end)
    else
        local addr = taddr[tcount] -- vezmu adresu z pole
        if Debug == 1 then
                print("m>addr: "..addr) -- pocet senzoru 
        end
        t.startMeasure(addr) -- pozadam dalas o mereni
        addr = nil
        tmr.alarm(Casovac, 750, 0,  function() readoutDALAS() end)
    end
end

local function prepareDALAS()

    if PinDALAS == nil then
        tmr.alarm(Casovac, 25, 0,  function() finishDALAS() end)
    else
        t = require("ds18b20")
        t.setup(PinDALAS)
        local taddr = t.addrs() -- nacte adresy do lokalniho pole
        if (taddr ~= nil) then
            tsnimacu = table.getn(taddr)
            if Debug == 1 then
                print("m>temp sensors: "..tsnimacu) -- pocet senzoru 
            end
            Data[Prefix.."t_cnt"] = tsnimacu
        end
        if tsnimacu == 0 then -- zadne snimace nenalezeny preskocime mereni
            tmr.alarm(Casovac, 25, 0,  function() finishDALAS() end)
        else
            tcount = 1
            tmr.alarm(Casovac, 25, 0,  function() measureDALAS() end)
        end
    end
end

local function finishDHT()
    
    if PinDHTpower ~= nil then
        -- uklid napajeni DHT22
        gpio.write(PinDHTpower,gpio.LOW)
    end
    if PinDHT ~= nil then
        -- vypnu na nulu i datovy vodic
        gpio.mode(PinDHT,gpio.OUTPUT)
        gpio.write(PinDHT,gpio.LOW)
    end

    tmr.alarm(Casovac, 25, 0,  function() prepareDALAS() end)    
end

local function measureDHT()

    if PinDHT ~= nil then
        local result,T,H
        local Tavr,Havr,Cnt = 0,0,0
        local counter = 20 -- urcuje pocet opakovani mereni z DHT
        while (counter > 0) do
            result, T, H = dht.read(PinDHT)
            if (result == 0) then
                Cnt = Cnt + 1
                Tavr = Tavr + T
                Havr = Havr + H
            end
            counter = counter - 1
        end
        
        if (Cnt > 0) then
            Tavr = Tavr / Cnt;
            Havr = Havr / Cnt;
    
            if Debug == 1 then 
                print ("m>Temp: "..Tavr)
                print ("m>Humi: "..Havr)
            end
            
            Data[Prefix.."t22"] = Tint
            Data[Prefix.."h22"] = Hint
            Data[Prefix.."dht_ok"] = 1
        else
            
            if Debug == 1 then print("m>DHT not found") end
            
            Data[Prefix.."dht_ok"] = 0
        end
    end

    tmr.alarm(Casovac, 25, 0,  function() finishDHT() end)    
end

local function prepareDHT()

    if PinDHTpower ~= nil then
        gpio.mode(PinDHTpower,gpio.OUTPUT)
        gpio.write(PinDHTpower,gpio.HIGH) 
        -- vypinani DHT behem sleepu usetri kolem 10uA
    end

    tmr.alarm(Casovac, 25, 0,  function() measureDHT() end)
end  

function setup(_casovac,_prefix,_dhtpin,_dhtpowerpin,_dalaspin,_baroA,_baroB) 
   
    Casovac = _casovac or 4 -- pokud to neuvedu 
    Prefix = _prefix or "noid" -- pokud neuvedu
    PinDHT = _dhtpin
    PinDHTpower = _dhtpiwerpin
    PinDALAS = _dalaspin
    PinBaro = {_baroA,_baroB}
    Data = {}
    Finished = 0
  
    tmr.alarm(Casovac, 25, 0,  function() prepareDHT() end)
    
    return Casovac
end
M.setup = setup

function status()

    return Finished
end
M.status = status

function getvalues()

    if Finished > 0 then
        return Data
    else
        return {}
    end
end
M.getvalues = getvalues

-- Return module table
return M
