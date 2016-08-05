--------------------------------------------------------------------------------
-- Distancer measurement
-- 
-- setup(_averaging)  
--  _casovac - ktery casovac se ma pro mereni pouzit
--  _averaging - kolik mereni se ma udelat
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
local Average
local Finished = 0
local ZalohaDebug
-- pro mereni 
local adelka
local ateplota
local cntdelka
local cntteplota
local counter
local distdata
local dataok 

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

local function FinishDIST()
    -- zpracovat data
    if dataok == 1 then
        ateplota = ateplota + (distdata:byte(1) - 45)
        cntteplota = cntteplota + 1 -- pocitam pouze korektni hodnoty
    end

    if Average > counter then
        tmr.alarm(Casovac, 20, 0, function() StartDIST2() end)        
        return
    end
    counter = nil
  
    -- zrusit handler
    uart.on("data")
    distdata = nil
    -- prepnout na 115200 a povolit interpret
    uart.setup(0, 115200, 8, uart.PARITY_NONE, uart.STOPBITS_1, 1)
    -- vratit seriovou linku na port 1 
    uart.alt(0)
    -- obnovit debug
    Debug,ZalohaDebug = ZalohaDebug,nil
    -- export
    if cntdelka > 0 then 
        adelka = adelka/cntdelka
        Data["delka"] = adelka
    end
    Data["cnt_d"] = cntdelka
    if cntteplota > 0 then 
        ateplota = ateplota/cntteplota
        Data["teplota_d"] = ateplota
    end
    Data["cnt_t"] = cntteplota
    if Debug == 1 then 
        print("m>sound l="..(adelka).." ("..cntdelka..")")
        print("m>sound t="..(ateplota).." ("..cntteplota..")")
    end

    adelka,cntdelka,ateplota,cntteplota = nil,nil,nil,nil
    Finished = tmr.now()+1 -- ukonci mereni a da echo odesilaci a tim konci tento proces    
end

local function ProcessDIST()
    -- zpracovat data (vzdalenost v milimetrech)
    if dataok == 1 then
        local delka = (distdata:byte(1) * 256 + distdata:byte(2))
        if delka < 10000 then -- nepocitam hodnoty nad 5 metru
            adelka = adelka + delka
            cntdelka = cntdelka + 1 -- pocitam pouze korektni hodnoty
        end
    end
    -- nastavit handler prijmu
    distdata = nil    
    uart.on("data", 1, function(data) 
                           distdata = data
                           dataok = 1
                       end, 0)
    -- poslat 0x50 - mereni teploty
    dataok = 0
    uart.write(0, 0x50)
    -- nacasovat vycteni teploty
    tmr.alarm(Casovac, 10, 0, function() FinishDIST() end)        
end

local function StartDIST()
    -- nastavit handler prijmu
    distdata = nil
    uart.on("data", 2, function(data)
                           distdata = data
                           dataok = 1
                       end, 0)
    -- citac 
    counter = counter + 1
    -- poslat 0x55 - mereni vzdalenosti
    dataok = 0
    uart.write(0, 0x55)
    -- nacasovat vycteni delky
    tmr.alarm(Casovac, 120, 0, function() ProcessDIST() end)
end

function StartDIST2()
    StartDIST()
end

local function PrepareDIST()
    -- vynulovat promenne
    counter = 0
    adelka,cntdelka,ateplota,cntteplota = 0,0,0,0
    -- Globalni promennou debug nastavim na 0
    ZalohaDebug,Debug = Debug,0
    -- prepnout seriovou linku na 2. port - OD TED SE NESMI DELAT DEBUG PRINT
    uart.alt(1)
    -- nastavit rychlost 9600 a vypnout interpret
    uart.setup(0, 9600, 8, uart.PARITY_NONE, uart.STOPBITS_1, 0)
    -- nacasovat dalsi veci
    tmr.alarm(Casovac, 10, 0, function() StartDIST() end)        
end

local function setup(_casovac,_averaging) 
   
    Casovac = _casovac or 5 -- pokud to neuvedu 
    Average = _averaging or 10
    Data = {}
    Finished = 0
    tmr.alarm(Casovac, 10, 0,  function() PrepareDIST() end)
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
