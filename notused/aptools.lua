-- aptools.lua
local moduleName = ...
local APTOOL = {}
_G[moduleName] = M
    local ap_was_found = false
    local ap_selected_ssid = ""
    local ap_selected_pass = ""

function APTOOL.select_ap(t)
    
	ap_was_found = false

    if nil == t then 
		print ("W: nemam seznam AP")
		return
	end

    local ssid = ""
    local cfg_ssid = ""
    local cfg_pass = ""
    local line = ""
    
    for ssid in pairs(t) do
        print ("Searching password for AP:"..ssid)
        file.open("passwd.ini", "r")
        if nil == file.open("passwd.ini", "r") then
            print ("PANIC: nemam seznam hesel")
            break
            -- fatal, tak se na vse vykaslu a koncim
        else
            repeat
                line = file.readline();
                if line ~= nil then
                    cfg_ssid, cfg_pass = string.match(line, '([^|]+)|([^|]+)|')           
                    --print("DEBUG: ssid"..cfg_ssid..", pass"..cfg_pass)
                    if ssid == cfg_ssid then
                        print ("Known ssid:"..ssid..", password:"..cfg_pass)
                        ap_selected_ssid = cfg_ssid
                        ap_selected_pass = cfg_pass
                        ap_was_found = true
                        break
                    end
                end
            until line == nil
            file.close()
            if ap_was_found == true then
                break
            end
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

function APTOOL.ssid()
    return ap_selected_ssid
end

function APTOOL.pass()
    return ap_selected_pass
end

return APTOOL
