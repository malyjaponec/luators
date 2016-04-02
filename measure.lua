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
   
-- Temperature and Humidity

    local result,Tint,Hint,Tfrac,Hfrac
    counter = 20
    while (counter > 0) do
        if Debug == 1 then print("Reading DHT.") end
        result, Tint, Hint, Tfrac, Hfrac = dht.read(gpionum[2])
        if (result == 0) then
            break
        end
        if Debug == 1 then print(result) end
        counter = counter - 1
        tmr.delay(115000) -- cekani 115ms, nevim muze to treba pomoci
    end
    
    if (0 == result) then
        if Debug == 1 then 
            print ("Temp: "..Tint)
            print ("Humi: "..Hint)
        else
            print ("DHT ok")
        end

        Fields[ReportFieldPrefix.."teplota"] = Tint
        Fields[ReportFieldPrefix.."vlhkost"] = Hint
        Fields[ReportFieldPrefix.."dht_ok"] = 1
    else
        Fields[ReportFieldPrefix.."dht_ok"] = 0
    end

    -- uklid
    result = nil
    Tint, Hint, Tfrac, Hfrac = nil
    collectgarbage()

    -- Sbernice DALASu
    t = require("ds18b20")
    t.setup(gpionum[4])
    local addrs1 = t.addrs() -- nacte adresy do lokalniho pole
    if (addrs1 ~= nil) then
        local pocetsnimacu = table.getn(addrs1)
        print("temp sensors: "..pocetsnimacu) -- pocet senzoru 
        Fields[ReportFieldPrefix.."t_cnt"] = pocetsnimacu
        if (pocetsnimacu > 0) then

            -- Start measure for all sensors
            for q,v in pairs(addrs1) do
                t.startMeasure(v)
                -- Wait until measure is done
                tmr.delay(750000)
            end

            -- Read temperatures
            local value = ""
            local textaddr = ""
            pocetsnimacu = 0 -- zase to vynuluju
            for q,v in pairs(addrs1) do
                value = t.readNumber(v)
                textaddr = AddressInHex(v)
                if (value ~= nil) then
                    value = value/10000
                    Fields[ReportFieldPrefix.."t"..textaddr] = value
                    if (Debug == 1) then print("t"..textaddr.." = "..value) end
                    addrs1[q] = nil -- mazu z pole adresu, uz ji nebudu potrebovat
                    tmr.wdclr()
                    pocetsnimacu = pocetsnimacu+1 -- pocitam si jen ty co vratili hodnotu
                else
                    print("ERROR, "..textaddr.." returned nil")
                end
            end
        end
        Fields[ReportFieldPrefix.."t_cnt"] = pocetsnimacu
        pocetsnimacu = nil
        value = nil
        textaddr = nil
    end
    addrs1 = nil -- rusim pole adres
    -- Don't forget to release library it after use
    t = nil
    ds18b20 = nil
    package.loaded["ds18b20"]=nil

-- Barometr, provede se nekolik mereni a posle se prumer
    bmp085.init(gpionum[12],gpionum[14]) -- a nebo opacne, stejne I2C jako pro RTC
    local value,valuet = 0,0
    for q = 1,10 do 
        value = value + (bmp085.pressure() / 100)
        valuet =  valuet + (bmp085.temperature() / 10)
        tmr.delay(math.random(10,50)) -- doba mezi merenim nahodna, nevim zda to ma smysl, ale proc ne
        tmr.wdclr()
    end
    value,valuet = value/10,valuet/10

    if Debug == 1 then 
        print ("Pres="..value)
        print ("Temp(B)="..valuet)
    end
    Fields[ReportFieldPrefix.."tlak"] = value
    Fields[ReportFieldPrefix.."teplota_b"] = valuet
    value,valuet = nil,nil    

    -- Mereni dokoncena 
    tmr.alarm(0, 200, 0, function() dofile("send.lc") end)

