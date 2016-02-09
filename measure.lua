--[[ measure.lua
    Tento kod nespocita vykon drive nez dostane 2 pulzy. Z jednoho pulzu si to neovodi a ceka dokud neprijde druhy
    To mi prislo blbe, kdyz se zapne system na 0 spotrebe a proto je zde podmika, ktera rika ze pokud je klid 
    dobu delsi nez odpovida spotrebe MinmalPower tak se na cloud zacne posilat nula, hodnota se definuje nize.
    Nijak to neovlivni minimalni mozny zmereny vykon, ten muze byt klidne 0,01W pokud ovsem behem mereni nedojde
    k pretoceni casovace coz je asi 40 minut pak kdo vi co se zacne dit, ne vzdy vyjde zaporne cislo, ktere se 
    samozrejme zahazuje. Zatim jsem nevidel takovou situaci, ale nejspis ji jednou uvidim a pak ji zacnu resit.
--]]
    tmr.stop(1)
    local MinimalPower = 6 -- pro 0,5Wh pulzy to je vlastne mene nez 3W, 
    local MaximalPower = 10000 -- pro 0,5Wh pulze je to 5kW, rychlejsi sled pulzu to jiz ignoruje

-- citace, casovace a akumulatory
    local Time_Faze = {0,0,0} -- cas predchoziho pulzu pro jednotlive vstupy (v uS - citac tmr.now)
        -- do citacu, ktere se s predanim dat k odeslani nuluji

-- Generalizovana citaci funkce
    local function CitacInterni(_kanal)
        -- jako prvni si zaznamenam cas pulzu aby to neyblo ovlivneno nejakym dalsimi nedeterministickymi vypocty
        local timenow = tmr.now()
        -- spocitam cas od posledniho pulzu - periodu a ulozim si aktualni casovou znacku pro priste
        local timedif = timenow - Time_Faze[_kanal]
        if Time_Faze[_kanal] == 0 then -- po startu nevim kdy byl predchozi pulz, pouze ulozim cas a necham power na -1
            Time_Faze[_kanal] = timenow
        else
            Time_Faze[_kanal] = timenow
            -- kontroluji zda casva diference dava smysl pro aktualizaci vykonu a kdyz jo aktualizuji
            if timedif > 0 then -- Pri pretoceni casovace jednou za 40 minut vyjde zaporna hodnota a tu zahodim
                local power = 3600000000/timedif -- hodnota ve watech, pokud je pulz 1Wh (jinak se to musi prepocitat na serveru
                if power < 10000 then -- nepripustim ze bych meril neco velkeho, to uz zavani zakmity (10kW pri 1Wh, 5kW pri 0,5Wh na pulz)
                    Power_Faze[_kanal] = power
                    -- TODO: zapisu si hodnotu tez do RTC memory pro pripad restartu
                end
                power = nil
            end
        end
        timedif = nil
        timenow = nil
        -- akumuluji energii, prictu energetiuckou hodnotu pulzu

        -- zacatek kriticke sekce
            Energy_Faze[_kanal] = Energy_Faze[_kanal] + 1
        -- konec kriticke sekce

    end
      
-- Citaci funkce 1 2 a 3
    local function CitacPulzu1(_level)
        CitacInterni(1)
    end
    local function CitacPulzu2(_level)
        CitacInterni(2)
    end
    local function CitacPulzu3(_level)
        CitacInterni(3)
    end

-- Uprava vykonu pokud se nic nedeje
    local function ZpracujPauzu()

        -- snizeni vykonu kdyz se nic nedeje
        local i,timedif,power
        local timenow = tmr.now()
        for i=1,3 do 
            -- standardnim zpusobem spocitam diferenci pro urceni vykonu
            local timedif = timenow - Time_Faze[i]
            if timedif > 0 then -- Pri pretoceni casovace jednou za 40 minut vyjde zaporna hodnota a tu zahodim
                power = 3600000000/timedif -- hodnota ve watech pro pulz 1Wh, standardni vypocet jako nahore
                if power < MaximalPower then -- nepripustim ze bych meril neco velkeho, zde asi je jedno protoze nasleduje pouze snizovani ne zvysovani
                    if (Power_Faze[i] > power) then -- vypocteny vykon je nizsi nez predchozi, znamena to se ze se prodluzuji
                    -- pulzy a je rozumne pouzit cas ktery je ted protoze je nejspib blize realite nez predchozi perioda
                    -- takze opravim vykon na aktualni delku bezpulzi
                        Power_Faze[i] = power
                        -- TODO: zapisu si hodnotu tez do RTC memory pro pripad restartu
                    end
                end
                if (Power_Faze[i] == -1) and (power < MinimalPower) then -- pokud stale nebyl predan vykon,
                    -- protoze nepisel pulz a zaroven uz je nameren vykon mensi nez minimum, doba je to desna,
                    -- tak zapisu do vykonu 0 aby se zacalo neco predavat

                    -- TODO: budu porovnavat take s hodnotou v RTC memory a jakmile to bude nizsi tak zacnu tu 
                    -- TODO: hodnotu vydavat za aktualni vykon, pokud bude v RTC memory hodnota nula nebo nizsi
                    -- TODO: nez Minimal power, uplatni se drive podminka o Minimal poweru, ktera zacne vydava
                    -- TODO: nulu za aktualni vykon
                    
                    Power_Faze[i] = 0
                end
            end
        end
        power = nil
        timenow = nil
        timedif = nil
        i = nil

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
    tmr.alarm(1, 1000, 1,  function() ZpracujPauzu() end) 
    --collectgarbage()
