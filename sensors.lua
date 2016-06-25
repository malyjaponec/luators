--------------------------------------------------------------------------------
-- Sensor measurement
-- 
-- setup(_casovac,_prefix,_dhtpin,_dhtpowerpin,_dalaspin,_baroA,_baroB,_distance)  
--  _casovac - nastavi casovac, ktery bude knihovna pouziva a spusti mereni
--  _prefix - nastavi string na identifikaci zarizeni na cloudu (prefix dat)
--  _dhtpin - nastavi pin pro mereni dht
--  _dhtpowerpin - nastavi pin pro napajeni dht
--  _dalaspin - nastavi pin pro mereni dalasu, vzdy meri phantomove
--  _baroA a _baroB - nastavi piny kde je I2C siemens barometr
--  _distance - zvoli zda je pripojen seriovy meric vzdalenosti, kolik mereni se ma udelat
--      piny ma vzdalenost fixni, je to druha seriova linka gpio15 a 13 tusim
-- status() - vrati zda je mereni dokonceno nebo se jeste meri s casem dokonceni
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
local EnDist
local Finished = 0
-- pro mereni dalasu, barometr, atd...
local t
local p
local taddr
local tsnimacu
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

local function FinishDISK()
    -- zpracovat data
    t = t + (taddr:byte(1) - 45)
    -- zrusit handler
    uart.on("data")
    taddr = nil
    -- prepnout na 115200 a povolit interpret
    uart.setup(0, 115200, 8, uart.PARITY_NONE, uart.STOPBITS_1, 1)
    -- vratit seriovou linku na port 1 
    uart.alt(0)

    if EnDist < tcount then
        print("m>sound #"..tcount)
        startDIST()
    end
    
    -- export
    Data[Prefix.."delka"] = p/tcount
    Data[Prefix.."teplota_d"] = t/tcount
    tcount = nil
    
    -- debug print
    if Debug == 1 then 
        print("m>sound l="..p)
        print("m>soudn t="..t)
    end
    
    Finished = tmr.now()+1 -- ukonci mereni a da echo odesilaci a tim konci tento proces    
end

local function ProcessDIST()
    -- zpracovat data (vzdalenost v milimetrech)
    p = p + (taddr:byte(1) * 256 + taddr:byte(2))
    -- nastavit handler prijmu
    uart.on("data", 1, function(data) taddr = data end, 0)
    -- poslat 0x50
    uart.write(0, 0x50)
    -- nacasovat vycteni teploty
    tmr.alarm(1, 5, 0, function() FinishDISK() end)        
end

function startDIST()
        -- citac 
        tcount = tcount + 1
        -- poslat 0x55
        uart.write(0, 0x55)
        -- nacasovat vycteni delky
        tmr.alarm(1, 120, 0, function() ProcessDIST() end)
end

local function finishBARO()

    if PinBARO[1] ~= nil then
        p = p + (bmp085.pressure() / 100) -- tlak
        t = t + (bmp085.temperature() / 10) -- teplota
        tcount = tcount + 1

        if (tcount <= 10) then
            tmr.alarm(Casovac, math.random(10,50), 0,  function() finishBARO() end)
            return
        end

        p,t = p/tcount, t/tcount
        if Debug == 1 then 
            print ("m>baro P="..p)
            print ("m>baro t="..t)
        end
        Data[Prefix.."tlak"] = p
        Data[Prefix.."teplota_b"] = t
        p,t = nil,nil
    end

    if EnDist > 0 then -- povolene mereni vzdalenosti
        -- prepnout seriovou linku na 2. port
        uart.alt(1)
        -- nastavit rychlost 9600 a vypnout interpret
        uart.setup(0, 9600, 8, uart.PARITY_NONE, uart.STOPBITS_1, 0)
        -- nastavit handler prijmu
        uart.on("data", 2, function(data) tcount = data end, 0)
        -- nacasovat dalsi veci
        tcount = 0
        if Debug == 1 then print ("m>sound...")  end
        startDIST() 
    else
        Finished = tmr.now()+1 -- ukonci mereni a da echo odesilaci a tim konci tento proces
    end
end

local function prepareBARO()

    -- pro usporu pameti je finishDALAS() soucasti teto funkce, peknejsi by bylo to mit oddelene ale pameti je malo
    if PinDALAS ~= nil then
        gpio.mode(PinDALAS,gpio.OUTPUT)
        gpio.write(PinDALAS,gpio.LOW)

        taddr = nil
        t = nil
        ds18b20 = nil
        package.loaded["ds18b20"]=nil
        PinDALAS = nil
    end
    -- konec DALAS
    
    if PinBARO[1] ~= nil then
        bmp085.init(PinBARO[1],PinBARO[2])
        PinBaro = nil
        p,t = 0,0 -- nuluji prumery resp. soucty
        tcount = 0 -- pocitadlo mereni
    end
    tmr.alarm(Casovac, 25, 0,  function() finishBARO() end)
  
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
            print("m>t"..textaddr.." = "..value)
        end
    end
    textaddr = nil
    value = nil
    tcount = tcount + 1
    tmr.alarm(Casovac, 25, 0,  function() measureDALAS2() end)
end

local function measureDALAS()
    
    if tcount > tsnimacu then -- presazen pocet snimacu, konec mereni
        tmr.alarm(Casovac, 25, 0,  function() prepareBARO() end)
    else
        local addr = taddr[tcount] -- vezmu adresu z pole
        if addr ~= nil then -- bezpecnostni ochrana kdyby to vratilo nil
            t.startMeasure(addr) -- pozadam dalas o mereni
            addr = nil
            tmr.alarm(Casovac, 750, 0,  function() readoutDALAS() end)
        else
            -- pokud to vrati nulouvou adresu, zkusim dalsi index
            tcount = tcount + 1
            tmr.alarm(Casovac, 25, 0,  function() measureDALAS() end)
        end
    end
end

function measureDALAS2()
    measureDALAS()
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
                print ("m>22Temp: "..Tavr)
                print ("m>22Humi: "..Havr)
            end
            
            Data[Prefix.."t22"] = Tavr
            Data[Prefix.."h22"] = Havr
            Data[Prefix.."dht_ok"] = 1
        else
            
            if Debug == 1 then 
                print("m>DHT not found") 
            end
            
            Data[Prefix.."dht_ok"] = 0
        end
        counter = nil
        Tavr,Havr,Cnt = nil,nil,nil
        result,T,H = nil,nil,nil

        -- vypnu na nulu datovy vodic
        gpio.mode(PinDHT,gpio.OUTPUT)
        gpio.write(PinDHT,gpio.LOW)
    end

    if PinDHTpower ~= nil then
        -- uklid napajeni DHT22
        gpio.write(PinDHTpower,gpio.LOW)
    end
    
    PinDHT = nil
    PinDHTpower = nil

    -- pro usporu pameti prepareDALAS() je soucasti measureDHT() ale samozrejme by bylo peknejsi to oddelit
    if PinDALAS ~= nil then
        t = require("ds18b20")
        t.setup(PinDALAS)
        taddr = t.addrs() -- nacte adresy
        if (taddr ~= nil) then
            tsnimacu = table.getn(taddr)
            Data[Prefix.."t_cnt"] = tsnimacu
        else
            tsnimacu = 0
        end
        if Debug == 1 then
            print("m>temp sensors: "..tsnimacu) -- pocet senzoru 
        end
        if tsnimacu > 0 then -- jsou nalezeny snimace
            tcount = 1
            tmr.alarm(Casovac, 25, 0,  function() measureDALAS() end)
            return
        end
    end
    
    tmr.alarm(Casovac, 25, 0,  function() prepareBARO() end)
end

local function setup(_casovac,_prefix,_dhtpin,_dhtpowerpin,_dalaspin,_baroA,_baroB,_distance) 
   
    Casovac = _casovac or 4 -- pokud to neuvedu 
    Prefix = _prefix or "noid" -- pokud neuvedu
    PinDHT = _dhtpin
    PinDHTpower = _dhtpiwerpin
    PinDALAS = _dalaspin
    PinBARO = {_baroA,_baroB}
    EnDist = _distance or 0
    Data = {}
    Finished = 0
  
    if PinDHTpower ~= nil then
        gpio.mode(PinDHTpower,gpio.OUTPUT)
        gpio.write(PinDHTpower,gpio.HIGH) 
        -- vypinani DHT behem sleepu usetri kolem 10uA ale nefunguje to
        tmr.alarm(Casovac, 100, 0,  function() measureDHT() end)
    else
        tmr.alarm(Casovac, 10, 0,  function() measureDHT() end)
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
