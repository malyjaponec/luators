--[[ measure.lua
    Plán:
    1. hledat minimum a maximum (prumerne min a max)
    2. vymezit zakázaný prostor
    3. detekovat vzestupne hrany pres zakazany prostor
    4. vycteni dat (pulzy,min,max,sirka zakazaneho pasma,kalribtrace ok
--]]
    tmr.stop(1)
    local MinimalPower = 1 -- pro 0,5Wh pulzy to je vlastne mene nez 0.5W, 
    local MaximalPower = 16000 -- pro 0,5Wh pulze je to 8kW, rychlejsi sled pulzu to jiz ignoruje

-- citace, casovace a akumulatory
    local Time_Faze = {-1,-1,-1} -- cas predchoziho pulzu pro jednotlive vstupy (v uS - citac tmr.now)
    local Time_Long = {0,0,0} -- extra cas pro mereni zalezitosti pres 40 minut dlouhych
    local Time_Rotation = 0 -- pro detekci pretoceni
	
	local Average_Counter
	local Average_Data = {}
	local Average
	
	local Digitize_Minimum = 1024
	local Digitize_Maximum = 0
	
	-- Defajny
	local Digitize_MinimalSpan = 200
	local Digitize_Sticky = 0.01


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
            Time_Faze[_kanal] = timenow
            Time_Long[_kanal] = 0
            -- kontroluji zda casva diference dava smysl pro aktualizaci vykonu a kdyz jo aktualizuji
            if timedif < 0 then -- zapornou hodnotu jednorazove opravim
                timedif = timedif + 2147483647 
            end
            if timedif > 0 then -- Pri pretoceni casovace jednou za 40 minut vyjde zaporna hodnota a tu zahodim
                local power = 3600000000/timedif -- hodnota ve watech, pokud je pulz 1Wh (jinak se to musi prepocitat na serveru
                if power < MaximalPower then -- nepripustim ze bych meril neco velkeho, to uz zavani zakmity
                    Power_Faze[_kanal] = power
                    rtcmem.write32(3+_kanal, power) -- zapisu si hodnotu tez do RTC memory pro pripad restartu
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
        local i,timedif,power,powermem
        local timenow = tmr.now()
        for i=1,3 do 
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
            if Debug == 1 and i == 1 then print("m>dif:"..timedif) end
            if (timedif <= 0) or 
                -- Pri pretoceni casovace jednou za 40 minut vyjde zaporna hodnoto casoveho rozdilu
               ((Time_Rotation > timenow) and (Time_Faze[i] == -1)) then
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
                    if (Power_Faze[i] > power) then -- vypocteny vykon je nizsi nez predchozi, znamena to se ze se prodluzuji
                    -- pulzy a je rozumne pouzit cas ktery je ted protoze je nejspib blize realite nez predchozi perioda
                    -- takze opravim vykon na aktualni delku bezpulzi
                        Power_Faze[i] = power
                        rtcmem.write32(3+i, power) -- zapisu si hodnotu tez do RTC memory pro pripad restartu
                    end
                end
                if (Power_Faze[i] == -1) then
                    powermem = rtcmem.read32(3+i) -- prectu si hodnotu z pameti
                    if (power < powermem) then -- je to mene nez hodnota pred restartem
                        Power_Faze[i] = power -- opravim odesilanou hodnotu
                        -- v dalsim pruchodu se aktualizuje i hodnota v pameti
                    end
                    if (power < MinimalPower) then -- pokud stale nebyl predan vykon,
                        -- a dosahli jsme casem rozumne nizke hodnoty, zacnu ji predavat
                        Power_Faze[i] = power
                    end
                end
            end
            if Debug == 1 and i == 1 then print("m>p1:"..power) end 
        end
        Time_Rotation = timenow -- zaznamenam si novy cas
        power = nil
        timenow = nil
        timedif = nil
        i = nil
    end
	
	local function ProcessPoint(_value)
		if (Digitize_Maximum - Digitize_Minimum) < Digitize_MinimalSpan then 
			--[[ Vzdalenost minima a maxima neni pripravena pro provoz, v tomto rezimu pouze 
			vyhledavam maximum a minimum z namerenych bodu a cekam az se od sebe vzdali dostatecne daleo
			toto je nabehovy rezim, do kteho by se mohl system vratit za provozu pouze tak, ze by
			se hodnoty v horni a dolni polovine rozsahu priblizili pod tuto mez, coz by ale znamenalo
			nejakou zavadu ve snimani a tudis by to bylo vlastne koser ]]--
			if _value > Digitize_Maximum then Digitize_Maximum = _value end	
			if _value < Digitize_Minimum then Digitize_Minimum = _value end
		else 
		--[[ Provozni rezim je ustanoven. V tomto rezimu si rozdeluji rozsah mezi hodnotami 
		na dve poloviny, pokud jsem v dolni polovine tak bud minimum snizim na uroven hodnoty
		ktera je pod nim a nebo pokud je nad nim, tak minimum posunu o kousek nahoru. Opacne
		se deje v horni polovine. Takze maximum a minimum se neustale snazi dostat do stredu 
		ale zaroven je hodnotami srazeno dolu a nahoru. ]]--
		local Center = (Digitize_Maximum + Digitize_Minimum) / 2 -- prumerna stredni hodnota
		if _value < Digitize_Minimum then Digitize_Minimum = _value end
		
		if _value > Center then -- hodnota se nachazi v horni polovine
			if _value > Digitize_Maximum then -- hodnota utekla za maximum
				Digitize_Maximum = _value 
			else -- hodnota se nachazi mezi maximem a stredem
				local Distance = Digitize_Maximum - _value -- vzdalenost mezi maximem a hodnotou
				Digitize_Maximum = Digitize_Maximum - Distance * Digitize_Sticky -- přisunu maximum o zlomek vzdalenosti aktualni hodnoty
				Distance = nil
			end
		else -- hodnota se nachazi v dolni polovine (nebo na stredu)
			if _value < Digitize_Minimum then -- hodnota utekla pod minimum
				Digitize_Minimum = _value 
			else -- hodnota se nachaz9 mezi mininimem a stredem
				local Distance = _value - Digitze_Minimum -- vzdalenos mezi hodnotou a minimem
				Digitize_Minimum = Digitize_Minimum + Distance * Digitize_Sticky -- zvednu minimum o nejaky zlomek vzdalenosti od aktualni hodnoty
				Distance = nil
			end
		end
		Center = nil
		
		-- a nyni znova kontrola spanu, a pokud stale ok tak se zpracuje bod do vysledne digitalni hodnoty
		
	end
	
	
	local function CaptureAnalog()
		Average_Data[Average_Counter] = adc.read(0)
		Average_Counter = Average_Counter + 1
		if Average_Counter <= 10 then -- zde se nastavuje pocet vycteni ad prevodniku pro jeden scan
			tmr.alarm(4, math.random(5,15), 0,  function() CaptureAnalog() end)
		else -- nacteno dost dat provedu ocisteni
			-- tady to mam v poli a muzu si s tim delat cokoliv 
			-- ale zatim s tim udelam jen prumerne
			local Sum = 0
			for q = 1,10,1 do
				Sum = Sum + Average_Data[q]
			ProcessPoint(Sum / 10)
			Sum = nil
		end
	end
	
	
	local function StartAnalog()
		Average_Counter = 1
		Average_Data = {}
		tmr.alarm(4, math.random(5,15), 0,  function() CaptureAnalog() end)
	end
	
  
    
-- Nacasu prvni odeslani
    tmr.alarm(1, 1000, 1,  function() ZpracujPauzu() end) -- pousti se opakovane
	tmr.alarm(3, 100, 1,  function() StartAnalog() end) -- pousti se opakovane
    --collectgarbage()
