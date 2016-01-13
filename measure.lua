-- measure.lua
    tmr.stop(1)

-- nastaveni pro mereni
    local SendEnergyCounter = 11
    local PowerReportTimer = 5000
    local PulseEnergy = 0.5 -- 0,5 Wh
    -- Measure_Faze musi byt definovana z vnejsku

-- citace, casovace a akumulatory
    local SendCounter = 0 -- citac cyklujici odesilani vykonu a energie
    local SentEnergy = 0 -- indikace zda se posila energie nebo jen vykon
    local Energy_Faze = {0,0,0} -- akumulace energie pro jednotlive vstupy (ve Wh)
    local Power_Faze = {0,0,0} -- ukladani posledniho vykonu pro jednotlive vstupy (ve W) na zaklade posledni delky pulzu
    local Time_Faze = {0,0,0} -- cas predchoziho pulzu pro jednotlive vstupy (v uS - citac tmr.now)
    local SentEnergy_Faze = {0,0,0} -- ulozeni energie, ktera se predala k posilani, tak aby pri neuspechu se mohla vratit
        -- do citacu, ktere se s predanim dat k odeslani nuluji

-- Generalizovana citaci funkce
    local function CitacInterni(_kanal)
        -- jako prvni si zaznamenam cas pulzu aby to neyblo ovlivneno nejakym dalsimi nedeterministickymi vypocty
        local timenow = tmr.now()
        -- akumuluji energii, prictu energetiuckou hodnotu pulzu
        Energy_Faze[_kanal] = Energy_Faze[_kanal] + PulseEnergy
        -- spocitam cas od posledniho pulzu - periodu a ulozim si aktualni casovou znacku pro priste
        local timedif = timenow - Time_Faze[_kanal]
        Time_Faze[_kanal] = timenow
        timenow = nil
        -- kontroluji zda casva diference dava smysl pro aktualizaci vykonu a kdyz jo aktualizuji
        if timedif > 0 then -- Pri pretoceni casovace jednou za 40 minut vyjde zaporna hodnota a tu zahodim
            local power = 3600000000*PulseEnergy/timedif -- hodnota ve watech
            if power < 5000 then -- nepripustim ze bych meril neco pres 20A
                Power_Faze[_kanal] = power
            end
            power = nil
        end
        timedif = nil
    end
      
-- Citaci funkce 1 2 a 3
    function CitacPulzu1(_level)
        CitacInterni(1)
        gpio.trig(Measure_Faze[1], "down") 
        --if level == 1 then gpio.trig(Pulzy1, "down") else gpio.trig(Pulzy1, "up") end
    end
    function CitacPulzu2(_level)
        CitacInterni(2)
        gpio.trig(Measure_Faze[2], "down") 
        --if level == 1 then gpio.trig(Pulzy1, "down") else gpio.trig(Pulzy1, "up") end
    end
    function CitacPulzu3(_level)
        CitacInterni(3)
        gpio.trig(Measure_Faze[3], "down") 
        --if level == 1 then gpio.trig(Pulzy1, "down") else gpio.trig(Pulzy1, "up") end
    end

-- Odesilaci funkce
    local function ZpracujMereni()
        local i

        -- snizeni vykonu kdyz se nic nedeje
        local timedif,power
        local timenow = tmr.now()
        for i=1,3 do 
            local timedif = timenow - Time_Faze[i]
            if timedif > 0 then -- Pri pretoceni casovace jednou za 40 minut vyjde zaporna hodnota a tu zahodim
                power = 3600000000*PulseEnergy/timedif -- hodnota ve watech
                if power < 5000 then -- nepripustim ze bych meril neco pres 20A
                    if Power_Faze[i] > power then -- vypocteny vykon je nizsi nez predchozi, znamena to se ze se prodluzuji
                    -- pulzy a je rozumne pouzit cas ktery je ted protoze je nejspib blize realite nez predchozi perioda
                        Power_Faze[i] = power
                    end
                end
            end
        end
        power = nil
        timenow = nil
        timedif = nil

        -- kontrola dat z neuspesneho odeslani a pricteni k datum, ale jen pokud byla pred tim odesilana energie
        if (Send_Failed == 1) then
            if (SentEnergy == 1) then
                for i=1,3 do 
                    Energy_Faze[i] = Energy_Faze[i] + SentEnergy_Faze[i] -- vracim neodeslane hodnoty vykonu
                    -- nic dalsiho vracet nemusim, protoze o tyhle hodnoty bych jinak prisel, protoze jsem nuloval
                end
            end
            Send_Failed = 0 -- vymazu si indikaci, kterou muze nastavit odesilac, to delam vzdy i kdyz jsem nic nevracel
        end

        -- predani dat k odeslani
        if SendCounter < SendEnergyCounter then -- predava se jen aktualni vykon
            if (Send_Busy == 0) and (Send_Request == 0) then -- vysilam pozdaveky pouze pokud odesilac neni busy a neni jiny pozadavek ve vzduchu 
                rgb.set() -- zhasnu led, abych mohl radne zmerit okolni svetlo snad nasledujici kod bude stacit na stabilizaci hodnoty
                for i=1,3 do 
                    Rdat[Rpref.."p"..i] = Power_Faze[i]	-- prepisuji odesilaci data
                end
                Rdat[Rpref.."an"] = adc.read(0) -- prepocty se mohou delat na cloudu, poslu hodnotu
                Send_Request = 1
                SentEnergy = 0 -- nebyla odeslana energie
                rgb.set("blue")
                SendCounter = SendCounter + 1
            end
        else -- predava se i energii
            if (Send_Busy == 0) and (Send_Request == 0) then -- vysilam pozdaveky pouze pokud odesilac neni busy a neni jiny pozadavek ve vzduchu 
                for i=1,3 do 
                    Rdat[Rpref.."p"..i] = Power_Faze[i]
                    -- pocatek kriticke sekce
                        SentEnergy_Faze[i],Energy_Faze[i] = Energy_Faze[i],0
                    -- konec kriticke sekce
                    Rdat[Rpref.."e"..i] = SentEnergy_Faze[i]
                    Rdat[Rpref.."et"] = tmr.now()/1000000
                end
                Rdat[Rpref.."an"] = adc.read(0) -- analog moc nepouzivam a tak tam hodim hodnotu
                Send_Request = 1
                SentEnergy = 1 -- byla odeslana energie
                rgb.set("blue")
                SendCounter = 0 -- odeslani spotreby se v pripaden neuspechu odlozi zase o jednu dlouhou periodu
                -- nebudu se snazit to tlacit rychle v dalsi kratke periode ven, protoze o nic neprijdu, neodeslane
                -- energie si nactu zpet a pridam priste
            end
        end
        --collectgarbage()
    end
      
-- Nastaveni pinu na preruseni
    if Measure_Faze[1] ~= nil then
        gpio.mode(Measure_Faze[1], gpio.INPUT, gpioPULLUP)
        gpio.mode(Measure_Faze[1], gpio.INT, gpioPULLUP) 
        gpio.trig(Measure_Faze[1], "down", CitacPulzu1)
    end
    if Measure_Faze[2] ~= nil then
        gpio.mode(Measure_Faze[2], gpio.INPUT, gpioPULLUP)
        gpio.mode(Measure_Faze[2], gpio.INT, gpioPULLUP) 
        gpio.trig(Measure_Faze[2], "down", CitacPulzu2)
    end
    if Measure_Faze[3] ~= nil then
        gpio.mode(Measure_Faze[3], gpio.INPUT, gpioPULLUP)
        gpio.mode(Measure_Faze[3], gpio.INT, gpioPULLUP) 
        gpio.trig(Measure_Faze[3], "down", CitacPulzu3)
    end
    
-- Nacasu prvni odeslani
    tmr.alarm(1, PowerReportTimer, 1,  function() ZpracujMereni() end) 
    --collectgarbage()
