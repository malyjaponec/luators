-- aptools.lua
local moduleName = ...
local APTOOL = {}
_G[moduleName] = M
    local ap_was_found = 0


function APTOOL.select_ap(t)
    
	ap_was_found = 0

    if nil == t then 
		print ("W: nemam seznam AP")
		return
	end

    local ssid = ""
    local cfg_ssid = ""
    local cfg_pass = ""
    local line = ""
    
    for ssid in pairs(t) do
        --print ("Kontrola AP:"..ssid)
        file.open("passwd.ini", "r")
        if nil == file.open("passwd.ini", "r") then
            print ("E: nemam seznam hesel")
            return; -- fatal, tak se na vse vykaslu a koncim
        else
            repeat
                line = file.readline();
                if line ~= nil then
                    cfg_ssid, cfg_pass = string.match(line, '(%w+) (%w+)')           
                    if ssid == cfg_ssid then
                        print ("AP:"..cfg_ssid.." Pass:"..cfg_pass)
                        wifi.sta.config(cfg_ssid,cfg_pass)
                        ap_was_found = 1
                        break
                    end
                end
            until line == nil
            file.close()
        end
    end

    ssid = nil
    line = nil
    cfg_ssid = nil
    cfg_pass = nil
    line = nil
end

function APTOOL.found()
  return ap_was_found
end

return APTOOL
