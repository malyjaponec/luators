--------------------------------------------------------------------------------
-- Sensor measurement - DHT
-- 
-- setup(casovac,dhtpin,dhtpowerpin) 
-- - nastavi casovac, ktery bude knihovna pouziva a spusti mereni
-- - prefix pro identifikaci zarizeni v pripade ze vice zarizeni posila v jednom node
-- - nastavi pin pro mereni dht
-- - nastavi pin pro napajeni dht
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
local Counter
local Averaging
local Finished = 0
local Tavr,Havr,Cnt
-------------------------------------------------------------------------------
-- Local used modules
--------------------------------------------------------------------------------
--local tmr = tmr
--local math = math
--local dht = dht
--local gpio = gpio
--local print = print
--local Debug = Debug

-- Limited to local environment
--setfenv(1,M)
--------------------------------------------------------------------------------
-- Implementation
--------------------------------------------------------------------------------
local function measureDHT()
    -- zde probiha mereni a casovani opakovani
    if (Counter > 0) and (Averaging > 0) then
        local result,T,H
        result, T, H = dht.readxx(PinDHT)
        if (result == dht.OK) then
            Cnt = Cnt + 1
            Tavr = Tavr + T
            Havr = Havr + H
            Averaging = Averaging - 1 -- odcitam pouze pokud se povede mereni
        end
        result,T,H = nil
        Counter = Counter - 1
        tmr.alarm(Casovac, 400, 0,  function() measureDHT() end)
        return
    end
    -- zpracujeme vysledky a neni dobre delit nulou
    if (Cnt > 0) then 
        Tavr = Tavr / Cnt;
        Havr = Havr / Cnt;

        if Debug == 1 then 
            print (">22 T: "..Tavr)
            print (">22 H: "..Havr)
            print (">22 Cnt/Cou: "..Cnt.."/"..(75-Counter))
        end
        
        Data["t22"] = Tavr
        Data["h22"] = Havr
        Data["c22"] = Cnt
        Data["r22"] = 75 - Counter -- pri zmene maximalniho poctu pokusu nezapomenou zmenit i zde
        Data["dht_ok"] = 1
    else
        if Debug == 1 then 
            print(Casovac..">DHT not found") 
        end
        Data["c22"] = 0
        Data["dht_ok"] = 0
    end
    Counter,Tavr,Havr,Cnt,Casovac = nil,nil,nil,nil,nil
    -- vypnu na nulu datovy vodic
        gpio.mode(PinDHT,gpio.OUTPUT)
        gpio.write(PinDHT,gpio.LOW)
    PinDHT = nil
    if PinDHTpower ~= nil then
        -- uklid napajeni DHT22
            gpio.write(PinDHTpower,gpio.LOW)
        PinDHTpower = nil
    end
    local time = (tmr.now() - ((TimeStartLast or 0) * 1000))
    if time <= 0 then time = 1 end
    Finished = time -- ukonci mereni a da echo odesilaci a tim konci tento proces
end

local function setup(_casovac,_dhtpin,_dhtpowerpin,_averaging) 
    Casovac = _casovac or 3
    PinDHT = _dhtpin
    PinDHTpower = _dhtpowerpin
    Averaging = _averaging or 1
    Data = {}
    Finished = 0
    if (nil ~= PinDHT) then
        Counter = 75 -- maximalni pocet pokusu o zmereni DHT, dela to 30s, pri zmene zmenit i vypocet v odesilani dat!!!
        Tavr,Havr,Cnt = 0,0,0
        -- a zacina mereni, jen se nacasuje, pro pripad ze by byl pouzit napajeci pin je dobre pockat 
        if PinDHTpower ~= nil then
            gpio.mode(PinDHTpower,gpio.OUTPUT)
            gpio.write(PinDHTpower,gpio.HIGH) 
            -- vypinani DHT behem sleepu usetri kolem 10uA ale nefunguje to moc dobre
        end
        tmr.alarm(Casovac, 400, 0,  function() measureDHT() end)
        -- puvodne jsem zde rozlisoval zda se pripojuje napajeni nebo ne, a cekal jen 10ms
        -- ale vzhledem k tomu ze nove sdk asi meri dht skoro sekundu je to jedno, zvlast
        -- kdyz chci delat nekolik mereni
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
