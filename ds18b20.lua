--------------------------------------------------------------------------------
-- DS18B20 one wire module for NODEMCU
-- NODEMCU TEAM
-- LICENCE: http://opensource.org/licenses/MIT
-- Vowstar <vowstar@nodemcu.com>
-- 2015/02/14 sza2 <sza2trash@gmail.com> Fix for negative values
--------------------------------------------------------------------------------

-- Set module name as parameter of require
local modname = ...
local M = {}
_G[modname] = M
--------------------------------------------------------------------------------
-- Local used variables
--------------------------------------------------------------------------------
-- DS18B20 dq pin
local pin = nil
local res = nil
-- DS18B20 default pin
local defaultPin = 9
local defaultResolution = 3
--------------------------------------------------------------------------------
-- Local used modules
--------------------------------------------------------------------------------
-- Table module
local table = table
-- String module
local string = string
-- One wire module
local ow = ow
-- Timer module
local tmr = tmr
-- Limited to local environment
setfenv(1,M)
--------------------------------------------------------------------------------
-- Implementation
--------------------------------------------------------------------------------
C = 0
F = 1
K = 2
-- dq - index pinu (prepocteny) na kterem se ma komunikovat
-- dres - rozliseni mereni (prvni udaj zmeri tim co v teplomeru je a pak to prenastavi)
--  moznosti 0 - 9 bitu, 1 - 10 bitu, 2 - 11 bitu, 3 (default) - 12 bitu
function setup(dq, dr)
  pin = dq
  if (pin == nil) then
    pin = defaultPin
  end
  res = dr
  if (res == nil) then
    res = defaultResolution
  end
  ow.setup(pin)
end

function addrs()
  setup(pin)
  tbl = {}
  ow.reset_search(pin)
  repeat
    addr = ow.search(pin)
    if(addr ~= nil) then
      table.insert(tbl, addr)
    end
    tmr.wdclr()
  until (addr == nil)
  ow.reset_search(pin)
  return tbl
end

function startMeasure(addr)
  if(addr == nil) then
    return
  end
  setup(pin,res)
  crc = ow.crc8(string.sub(addr,1,7))
  if (crc == addr:byte(8)) then
    if ((addr:byte(1) == 0x10) or (addr:byte(1) == 0x28)) then
      -- print("Device is a DS18S20 family device.")
      ow.reset(pin)
      ow.select(pin, addr)
      ow.write(pin, 0x44, 1)
    end
  end
end

function readNumber(addr)
  result = nil
  setup(pin,res)
  flag = false
  if(addr == nil) then
    return result
  end
  crc = ow.crc8(string.sub(addr,1,7))
  if (crc == addr:byte(8)) then
    if ((addr:byte(1) == 0x10) or (addr:byte(1) == 0x28)) then
      -- print("Device is a DS18S20 family device.")
      present = ow.reset(pin)
      ow.select(pin, addr)
      ow.write(pin,0xBE,1)
      -- print("P="..present)
      data = nil
      data = string.char(ow.read(pin))
      for i = 1, 8 do
        data = data .. string.char(ow.read(pin))
      end
      -- print(data:byte(1,9))
      crc = ow.crc8(string.sub(data,1,8))
      -- print("CRC="..crc)
      if (crc == data:byte(9)) then
        t = (data:byte(1) + data:byte(2) * 256)
        if (t > 32767) then
          t = t - 65536
        end
        -- prepocet jen vzdy na stupne celsia
        t = t * 625

        -- Kontrola zda je nastavena pozadovana presnost na snimaci
          if ( ((res*32)+0x1F) ~= data:byte(5) ) then 
            -- print ("Reseting to x-bit resolution for next mesurement.")
            data = string.char(0x4E,0x00,0x00,((res*32)+0x1F)) -- store new configuration into scratchpad
            ow.reset(pin)
            ow.select(pin, addr)
            ow.write_bytes(pin, data, 1)
            ow.reset(pin)
            ow.select(pin, addr)
            ow.write(pin, 0x48, 1)
            t = -1
          end
        
        return t
      end
--      tmr.wdclr() zpusobovalo nahodne problemy s otevrenim TCP, bez toho se zdalo ze to funguje
    else
    -- print("Device family is not recognized.")
    end
  else
   -- print("CRC is not valid!")
  end
  return result
end

-- Return module table
return M
