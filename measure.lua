-- measure.lua

    local function AddressInHex(IN)
        local hexkody,out,high,low,w="0123456789ABCDEF",""
        for w = 1,8 do 
            high = (math.floor(IN:byte(w)) / 16) + 1
            low = ((IN:byte(w)) % 16) + 1
            out = out..string.sub(hexkody,high,high)..string.sub(hexkody,low,low)
        end
        return out
    end


    tmr.stop(0)
    Fields[ReportFieldPrefix.."ti"] = tmr.now()/1000
    print("Measuring sensors.")

-- Knihovna na cteni z dalasu
    t = require("ds18b20")
    local q,v

-- Teploty z ds18b20 - zbrenice 3 mereni i vycitani
    t.setup(Sb3,Sb3p)
    local a3 = t.addrs() -- nacte adresy do lokalniho pole
    local sc3 = 0
    if (a3 ~= nil) then
        sc3 = table.getn(a3)
        print("S3: "..sc3) -- pocet senzoru 
        if (sc3 > 0) then -- merit ma smysl jen pokud tam nejake senzory jsou
            -- Start measure for all sensors
            for q,v in pairs(a3) do
                t.startMeasure(v)
                tmr.delay(Sb3d)
            end
        end
    end

-- Vycitani hodnot - sbernice 3
    if (sc3 > 0) then -- vycitam jen jestli tam neco je
        t.setup(Sb3,Sb3p) --stale zustava od mereni ale nefunguje to musi se volat znova
        -- Read temperatures
        local value = ""
        local textaddr = ""
        for q,v in pairs(a3) do
            value = t.readNumber(v)
            textaddr = AddressInHex(v)
            if (value ~= nil) then
                value = value/10000
                Fields[ReportFieldPrefix.."t"..textaddr] = value
                if Debug == 1 then print("s3 t"..textaddr.." = "..value) end
                if value > 30 then -- Teplota je vyssi nez klidovy stav, neco se deje
                    ReportFast = 1 -- rychly reportovani
                end
                a3[q] = nil -- mazu z pole adresu, uz ji nebudu potrebovat
            else
                print("ERROR, "..textaddr.." returned nil")
            end
        end
        value = nil
        textaddr = nil
    end
    a3 = nil -- rusim pole adres
    sc3 = nil

    
-- Don't forget to release library it after use
    t = nil
    ds18b20 = nil
    package.loaded["ds18b20"]=nil
    q,v = nil,nil    
   
-- Temperature and Humidity
-- konec a spusteni odesilani
    
    collectgarbage()
    tmr.alarm(0, 2000, 0, function() dofile("measure.lc") end)
