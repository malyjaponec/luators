--[[ measure.lua
    Tento kod nespocita vykon drive nez dostane 2 pulzy. Z jednoho pulzu si to neovodi a ceka dokud neprijde druhy
    To mi prislo blbe, kdyz se zapne system na 0 spotrebe a proto je zde podmika, ktera rika ze pokud je klid 
    dobu delsi nez odpovida spotrebe MinmalPower tak se na cloud zacne posilat nula, hodnota se definuje nize.
    Nijak to neovlivni minimalni mozny zmereny vykon, ten muze byt klidne 0,01W pokud ovsem behem mereni nedojde
    k pretoceni casovace coz je asi 40 minut pak kdo vi co se zacne dit, ne vzdy vyjde zaporne cislo, ktere se 
    samozrejme zahazuje. Zatim jsem nevidel takovou situaci, ale nejspis ji jednou uvidim a pak ji zacnu resit.
--]]
    tmr.stop(1)
    local MinimalPower = 1 -- pro 0,5Wh pulzy to je vlastne mene nez 0.5W, 
    local MaximalPower = 16000 -- pro 0,5Wh pulze je to 8kW, rychlejsi sled pulzu to jiz ignoruje

-- citace, casovace a akumulatory
    local Time_Faze = {-1,-1,-1} -- cas predchoziho pulzu pro jednotlive vstupy (v uS - citac tmr.now)
    local Time_Long = {0,0,0} -- extra cas pro mereni zalezitosti pres 40 minut dlouhych
    local Time_Rotation = 0 -- pro detekci pretoceni
	
-- Debug
	local DebugPower = 0 -- pokud se nadefinuje tak to vypisuje moc vypisu

-- Generalizovana citaci funkce
    local function CitacInterni(_kanal)
        -- jako prvni si zaznamenam cas pulzu aby to neyblo ovlivneno nejakym dalsimi nedeterministickymi vypocty
        local timenow = tmr.now()
        -- spocitam cas od posledniho pulzu - periodu a ulozim si aktualni casovou znacku pro priste
        local timedif = timenow - Time_Faze[_kanal] + Time_Long[_kanal]
        if Time_Faze[_kanal] == -1 then -- po startu nevim kdy byl predchozi pulz, pouze ulozim cas a necham power na -1
            Time_Faze[_kanal] = timenow
            Time_Long[_kanal] = 0
        else
            -- kontroluji zda casva diference dava smysl pro aktualizaci vykonu a kdyz jo aktualizuji
            if timenow - Time_Faze[_kanal] < 0 then -- Nekontroluji timedif, protoze ten i pri pretoceni muze
				-- byt kladny, kdyz je hodnota Time_Long vysoka, a proto pouziju pro rozhodovani rozdil bez 
				-- zapocitani Time_Long
                timedif = timedif + 2147483647 
            end
            Time_Faze[_kanal] = timenow
            Time_Long[_kanal] = 0
            if timedif > 0 then -- Pro jistotu, kdyby mi pres predchozi upravy a podminky proslo zaporne cislo, tak ho zahodim 
				-- a do vypoctu vykonu ho nezapocitam
                local power = 3600000000/timedif -- hodnota ve watech, pokud je pulz 1Wh (jinak se to musi prepocitat na serveru
                if power < MaximalPower then -- nepripustim ze bych meril neco velkeho, to uz zavani zakmity
                    Power_Faze[_kanal] = power
                    rtcmem.write32(3+_kanal, power*1000) -- zapisu si hodnotu tez do RTC memory pro pripad restartu
                end
                power = nil
            end
        end
        timedif = nil
        timenow = nil
        -- akumuluji energii, prictu energetiuckou hodnotu pulzu

        -- zacatek kriticke sekce
            Energy_Faze[_kanal] = Energy_Faze[_kanal] + 1
        -- konec kriticke sekcesekce

    end
      
-- Citaci funkce 1 2 a 3
    local function CitacPulzu1(_level)
        if _level == gpio.LOW then
            CitacInterni(1)
        end
    end
    local function CitacPulzu2(_level)
        if _level == gpio.LOW then
			CitacInterni(2)
		end
    end
    local function CitacPulzu3(_level)
        if _level == gpio.LOW then
			CitacInterni(3)
		end
    end

-- Uprava vykonu pokud se nic nedeje
    local function ZpracujPauzu()

        -- snizeni vykonu kdyz se nic nedeje
        local i,timedif,power,powermem
        local timenow = tmr.now()
        for i=1,3 do 
			if Measure_Faze[i] ~= nil then -- pro elektromery s mene fazema, nemam piny na to abych z nich cetl
				-- standardnim zpusobem spocitam diferenci pro urceni vykonu
				local timedif = timenow - Time_Faze[i] + Time_Long[i]
				--[[ kontrola na zaporny vysledek, tohle ale nebude dobre fungovat
				pokud dojde k tomu ze timenow je nekde blizko 0, potom se stane to 
				ze bude sakra mala pravdepodobnost ze behem 1s kdy se toto kontroluje
				nastane to ze vyjde zaporny vysledek a dojde k tomu ze to bude ukazovat
				nesmysly dokud neprijde pulz ktery bude dal od 0, tomuhle se da zabranit
				pouze tak ze si budu externe detekovat pretoceni casovace a o to se pokousi
				nasledujici kus kodu
				if (timedif < 2000000) and (Time_Previous > timenow) then -- nastal ukaz ...
				jenze nejde dost dobre poznat a 100% sesychronizovat preruseni bez kritickych 
				sekci s peridoickym zpracovanim takze v takovem pripade se bude snizovac vykonu
				coz tento kod je myslet ze je tam velky vykon protoze pulz nastal pred 
				par sekundama pri kazdem pretoceni ale protoze se vzdy zapisuje jen nizsi vykon
				nez byl posledni aktivne zmereny tak se nic nestane, nanejvis dojde k tomu 
				ze nulovy vykon se misto toho ustali na urovni 1 pulz za 40 minut coz je 
				neco v urovni watu a pravdepodobnost ze to nastane je nizka
				]]--    
				if DebugPower ~= nil and Debug == 1 then 
					print("M> ["..i.."] now="..timenow.." rot="..Time_Rotation.." dif="..timedif.." faze"..Time_Faze[i].." lon="..Time_Long[i])
				end
				if (timedif <= 0) or 
					-- Pri pretoceni casovace jednou za 40 minut vyjde zaporna hodnoto casoveho rozdilu
					-- Tady to zaporne vyjde pravdepodobne pouze jednou, kdy je Time_Long jeste nulove
				   ((Time_Rotation > timenow)) then
				   --and (Time_Faze[i] == -1)) then
					-- A nebo poznam ze mam pricist pokud zjistim, ze cas se pretocil a jeste nemam
					-- zadny registrovany pulz na vstupu, protoze tam nemuze nikdy zaporna hodnota
					-- vyjit nebo Time_Faze je zaporna a odcita se od time now, cili vysledek je vzdy kladny
					-- a aby to po startu dobre ukazovalo nulovou spotrebu je tahle saskarna
					if Time_Long[i] < (2147483647*100) then -- tak to uz je fakt moc dlouho bez pulzu, tak nebudu pricitat
						Time_Long[i] = Time_Long[i] + 2147483647 -- zvysim aditivni hodnotu
					end
				end
				if (timedif > 0) then -- tohle je pro jistotu, nevim vubec jestli to cislo co pricitam je spravne
					power = 3600000000/timedif -- hodnota ve watech pro pulz 1Wh, standardni vypocet jako nahore
					if power < MaximalPower then -- nepripustim ze bych meril neco velkeho, zde asi je jedno protoze nasleduje pouze snizovani ne zvysovani
						if (power < Power_Faze[i]) then -- vypocteny vykon je nizsi nez predchozi, znamena to se ze se prodluzuji
						-- pulzy a je rozumne pouzit cas ktery je ted protoze je nejspib blize realite nez predchozi perioda
						-- takze opravim vykon na aktualni delku bezpulzi
							Power_Faze[i] = power
							rtcmem.write32(3+i, power*1000) -- zapisu si hodnotu tez do RTC memory pro pripad restartu
						end
					end
					if (Power_Faze[i] == -1) then -- pokud jeste nemam zadnou hodnotu vykonu, tohle se provede fakt jen na zacatku jednou
						local powermem = rtcmem.read32(3+i)/1000 -- prectu si hodnotu z pameti, pokud doslo k jejimu resetu bude tam 0
						if powermem ~= 0 then -- pokud v pameti neco je, pak to pouziju, nulu budu ignorovat
							if Debug == 1 then print("M> restored power="..powermem) end 
							Power_Faze[i] = powermem -- opravim si aktualni hodnotu na to co je v pameti
							Time_Long[i] = 3600000000/powermem - timenow -- nastavim si virtualne long time aby odpovidal vykonu a ten se hnedka dale snizoval
							-- vysledek je sice necelociselny, ale kdyz se udela math.floor vznikne z toho int 2,1 miliardy a to je malo pro vypocty co potrebujem
							if Time_Long[i] < 0 then Time_Long[i] = 0 end -- pro pripad ze v pameti je neco extremniho a
							-- nacetlo by se to hodne pozde a odectenim timenow by vznikl zaporny cas, je tady tato kontrola
						else
							if Debug == 1 then print("M> saved power invalid") end 
							Power_Faze[i] = -2 -- prepnu se do stavu, kdy z pameti se nic rozumneho nenacedlo a cekam na pokles vykonu na "rozumnou" hodnotu
							-- toto je vhodne aby to neustale necetlo hodnotu z RTC pameti a nezjistovalo ze je nulova
						end
						powermem = nil
					end
					if (Power_Faze[i] == -2) then -- pokud jsem jiz zkusit nacist hodnotu z pameti ale byla nulova
						if (power < MinimalPower) then -- pokud stale nebyl predan vykon,
							-- a dosahli jsme casem rozumne nizke hodnoty, zacnu ji predavat
							Power_Faze[i] = power
						end
					end
				end
				if Debug == 1 then print(string.format("M> power[%d] in/out=%.3f / %.3f",i,power,Power_Faze[i])) end 
			end
        end
        Time_Rotation = timenow -- zaznamenam si novy cas
        power = nil
        timenow = nil
        timedif = nil
        i = nil
    end
      
-- Nastaveni pinu na preruseni
    if Measure_Faze[1] ~= nil then
        gpio.mode(Measure_Faze[1], gpio.INPUT, gpio.FLOAT)
        gpio.mode(Measure_Faze[1], gpio.INT, gpio.PULLUP) 
        gpio.trig(Measure_Faze[1], "down", CitacPulzu1)
    end
    if Measure_Faze[2] ~= nil then
        gpio.mode(Measure_Faze[2], gpio.INPUT, gpio.FLOAT)
        gpio.mode(Measure_Faze[2], gpio.INT, gpio.PULLUP) 
        gpio.trig(Measure_Faze[2], "down", CitacPulzu2)
    end
    if Measure_Faze[3] ~= nil then
        gpio.mode(Measure_Faze[3], gpio.INPUT, gpio.FLOAT)
        gpio.mode(Measure_Faze[3], gpio.INT, gpio.PULLUP) 
        gpio.trig(Measure_Faze[3], "down", CitacPulzu3)
    end
    
-- Nacasu prvni odeslani
    tmr.alarm(1, 1000, 1,  function() ZpracujPauzu() end) 
