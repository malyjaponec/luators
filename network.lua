--------------------------------------------------------------------------------
-- Network setup
-- 
-- setup(casovac,functionok,functionfail) 
-- - nastavi casovac, ktery bude knihovna pouziva a spusti inicializaci site
-- - funkce kterou to spusti po dokonceni pripojeni k wifi
-- - funkce kterou to spusti pokud neni pokryti
--
-- !!! POZOR je pro firmware nekdy od cervence srpna 2017 - pouziva jiny zpusob nastaveni
-- apn takze se starym firmware nebude umet nastavit wifi a opacne na novy firmware se nemuze
-- nechat starou knihovnu network
-- 
--------------------------------------------------------------------------------

-- Set module name as parameter of require
local modname = ...
local M = {}
_G[modname] = M

--------------------------------------------------------------------------------
-- Local used variables
--------------------------------------------------------------------------------
local Finished
local Casovac
local Counter
local LedIO
local LedNegative
local ApWasFound 
-------------------------------------------------------------------------------
-- Local used modules
--------------------------------------------------------------------------------
-- Timer module
--local tmr = tmr
--local math = math
--local wifi = wifi
--local file = file
--local print = print
--local gpio = gpio
--local pairs = pairs
--local string = string
--local Debug = Debug

-- Limited to local environment
--setfenv(1,M)
--------------------------------------------------------------------------------
-- Implementation
-------------------------------------------------------------------------------

local function writeled(_level)
	-- Pokud je definovana promenna LedNegative otocim hodnotu
	if  LedNegative ~= nil then
		_level = 1 - _level
	end
	-- A nyni upravenou honotu poslu na gpio
	if _level == 1 then
        gpio.write(LedIO, gpio.HIGH)
    else
        gpio.write(LedIO, gpio.LOW)
	end
end 

local function led(_stav)
    if LedIO == nil then return end
    -- Kladne hodnoty GPIO vystupu zapinaji ledku do H, zatimco zaporna hodnota predpoklada ledku proti VCC a rozsveci ledku do L
    gpio.mode(LedIO, gpio.OUTPUT, gpio.FLOAT) 
    if -1 == _stav then
        writeled(0)
        gpio.mode(LedIO, gpio.INPUT, gpio.FLOAT) 
    else 
        if 1 == _stav then
    		writeled(1)
        else
            if 2 == _stav then
		    	-- zmena stavu se deje podle hodnoty ledky nezavisle na tom zda je negovana nebo ne
                if gpio.LOW == gpio.read(LedIO) then
                    gpio.write(LedIO, gpio.HIGH)
                else
                    gpio.write(LedIO, gpio.LOW)
                end 
            else
			    writeled(0)
            end
        end
	end
end

local function ap_select(t)
    if nil == t then 
        if Debug == 1 then print ("ip> Scan returned empty list.") end
        ApWasFound = 0
        return
    end

    if file.open("passwd.ini", "r") == nil then
        ApWasFound = 3
        return
    end
        
    local ssid
    local cfg_ssid
    local cfg_pass
    local line
    
    for ssid in pairs(t) do
        if Debug == 1 then print ("ip> Searching password for AP "..ssid) end
        file.seek("set") -- jdu na zacatek souboru hesel
        repeat
            line = file.readline();
            if line ~= nil then
                cfg_ssid, cfg_pass = string.match(line, '([^|]+)|([^|]+)|')           
                if ssid == cfg_ssid then
                    if Debug == 1 then print ("ip> Known ssid "..ssid..", password "..cfg_pass) end
                    ApWasFound = 1
                    file.close()
					station_cfg={}
					station_cfg.ssid=cfg_ssid
					station_cfg.pwd=cfg_pass
					station_cfg.auto=true
					station_cfg.save=true
					wifi.sta.config(station_cfg)
                    station_cfg = nil
                    wifi.sta.connect()
                    wifi.sta.autoconnect(1)
                    return
                end
            end
        until line == nil
    end
    file.close()
    ApWasFound = 0
end

local function check_new_ip()
    led(2)
    if nil == wifi.sta.getip() then 
        if Debug == 1 and Counter % 10 == 0 then print("ip> Connecting AP...") end
        Counter = Counter - 1
        if (Counter > 0) then
            tmr.alarm(Casovac, 100, 0, function() check_new_ip() end)
        else
            print(wifi.sta.status())
            print("ip> PANIC, not IP assigned, end")
            led(0)
            Finished = -1
            tmr.alarm(Casovac, 100, 1, function() led(2) end)
        end
    else 
        if Debug == 1 then print("Reconfig done, IP is "..wifi.sta.getip()) end
        tmr.stop(Casovac)
        led(-1)
        local time = (tmr.now() - ((TimeStartLast or 0) * 1000))
        if time <= 0 then time = 1 end
        Finished = time -- ukonci mereni a da echo odesilaci a tim konci tento proces
        time = nil
    end
end

local function reset_apn_result()
    if ApWasFound == 1 then -- nalezeno, konfiguruji
        Counter = 200 -- opet cekam 20s na IP
        tmr.alarm(Casovac, 2000, 0, function() check_new_ip() end) -- zacnu cekat na IP
        return
    end
    
    if ApWasFound == 3 then -- neni soubor, jiz nastavena ch
        print ("ip> PANIC: file passwd.ini missing")
        led(0)
        Finished = -1
        tmr.alarm(Casovac, 100, 1, function() led(2) end)
        return
    end      
    
    if ApWasFound == -1 then -- zatim neni dohledano, jen kvuli debugu 
        if Debug == 1 then print("ip> AP search timeout") end
    end      
    
    -- vse ostatni nejspis 0
    if (Counter > 0) then
        if Debug == 1 then print("ip> Scan unsucessful, trying again...") end
        Counter = Counter - 1
        ApWasFound = -1 -- nastavim si ze nevim jestli neco nebo nic
        if Debug == 1 then print("ip> Rescanning APs...") end
        wifi.sta.getap(ap_select) -- spoustim hledani
        tmr.alarm(Casovac, 3000, 0, function() reset_apn_result() end) -- za 3 sekundu spust kontrolu vysledku
    else
        print("ip> PANIC, not wifi coverage, end")
        wifi.setmode(wifi.STATION) -- pro jistotu pred vypnutim rekonfiguruji, nechci to delat jindy, aby to neblokovalo nacitani AP a nebo pripojeni
        tmr.stop(Casovac)
        led(-1)
        Finished = -1
        --tmr.alarm(Casovac, 100, 1, function() led(2) end)
    end
end

local function change_apn()
    led(1)
    if Debug == 1 then print("ip> Reselecting AP...") end
    Counter = 3 -- skenuji 3x a pak reknu ze neni
    wifi.setmode(wifi.STATION) -- nove moduly jsou prepnute do softap a nerozjede se to, jiz pouzitemu je to jedno    
    ApWasFound = -1 -- nastavim si ze nevim jestli neco nebo nic
    if Debug == 1 then print("ip> Scanning APs...") end
    wifi.sta.getap(ap_select) -- spoustim hledani
    tmr.alarm(Casovac, 3000, 0, function() reset_apn_result() end) -- za 3 sekundu spust prvni kontrolu vysledku
end

local function check_ip()
    led(2)
    if nil ~= wifi.sta.getip() then 
        if Debug == 1 then print("ip> IP is "..wifi.sta.getip()) end
        tmr.stop(Casovac)
        led(-1)
        local time = (tmr.now() - ((TimeStartLast or 0) * 1000))
        if time <= 0 then time = 1 end
        Finished = time -- ukonci mereni a da echo odesilaci a tim konci tento proces
        time = nil
    else
        if Debug == 1 and Counter % 10 == 0 then print("ip> Connecting AP...") end
        Counter = Counter - 1
        if (Counter > 0) and (1 == wifi.sta.status()) then
            tmr.alarm(Casovac, 100, 0, function() check_ip() end)
        else
            if Debug == 1 then print("ip> connect failed, status:"..wifi.sta.status()) end
            change_apn()
        end
    end
end

local function setup(_casovac,_led)

    Finished = 0
    Casovac = _casovac or 0 -- pokud to neuvedu 
	if _led == nil then -- pokud neni led definovan
		LedIO = nil
	else
		if _led < 0 then
			LedIO = -_led 
			LedNegative = 1
		else
			LedIO = _led
			LedNegative = nil
		end
	end
    led(0)
    
    Counter = 200 -- po 100ms to je 20s
    tmr.alarm(Casovac, 1000, 0,  function() check_ip() end)
    
    return Casovac
end
M.setup = setup

local function status()

    return Finished
end
M.status = status

-- Return module table
return M
