-- send.lua

local function Get_AP_MAC()
    local ssid,pass,bset,bssid
    ssid, pass, bset, bssid=wifi.sta.getconfig()
    if bssid:len() == 17 then -- delka je presne 17 znaku
        local hex,len = bssid:gsub(":","") -- odmazu :
        if len == 5 then -- odmazano presne 5 dvojtecek
            return hex;
        end
    end
    return "????"
end

--------------------------------------------------------------------------------
local function KonecAbnormal()
    dofile("sleep.lua")
end

--------------------------------------------------------------------------------
local function Konec(code, data)
    if (code == nil) then
        code = -100
    end
    if (code > 0) then
        if Debug == 1 then print("s>odeslano/" .. code) end
    else
        if Debug == 1 then print("s>chyba/".. code) end
    end
    dofile("sleep.lua")
end

--------------------------------------------------------------------------------
local function Start()
     if Debug == 1 then print("s>sedning...") end
     -- rozsvitim druhou led dodelat
    
    -- vytvorim zakladni data, ktera chci prenest na cloud
    Rdat = sensors.getvalues()

    -- bateriova data
    min,max,cnt = battery.getvalues()
    Rdat[ReportFieldPrefix.."bmin"] = min
    Rdat[ReportFieldPrefix.."bmax"] = max
    Rdat[ReportFieldPrefix.."bcnt"] = cnt

    -- doplnkova data
    Rdat[ReportFieldPrefix.."cnt"] = Rcnt
    Rdat[ReportFieldPrefix.."x"..Get_AP_MAC()] = 1
    Rdat[ReportFieldPrefix.."ti"] = network.status()/1000000
    Rdat[ReportFieldPrefix.."tm"] = sensors.status()/1000000
    Rdat[ReportFieldPrefix.."ts"] = tmr.now()/1000000
    Rdat[ReportFieldPrefix.."hp"] = node.heap() 

    -- prevedu na URL
    local url = "http://emon.jiffaco.cz/emoncms/input/post.json?node=" .. ReportNode .. 
                "&json=" .. cjson.encode(Rdat) .. 
                "&apikey=" .. ReportApiKey
    Rdat = nil -- data smazu explicitne
    http.get(url, nil, function(code,data) Konec(code,data) end )
    url = nil -- url uz taky mazu
    tmr.alarm(3, 15000, 0, function() KonecAbnormal() end) -- nacasuji kontrolu pokud nezavola callback a zasekne se to
end

--------------------------------------------------------------------------------
local function KontrolaOdeslani()

    if network.status() > 0 and sensors.status() > 0 then -- odesilame

        tmr.alarm(2, 100, 0,  function() Start() end) -- Spoustim predani dat na cloud

    else
        if network.status() == -1 then

            dofile("sleep.lua")

        else
            -- Nacasovat dalsi kontrolu pokud jsem nenacasoval neco jineho
            tmr.alarm(3, 100, 0,  function() KontrolaOdeslani() end)

        end
    end
end

--------------------------------------------------------------------------------
tmr.alarm(3, 500, 0,  function() KontrolaOdeslani() end)  -- Na zacatku klidne muzu cekat dele

