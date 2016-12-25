--[[ measure_plyn.lua

	Vychazi z elektromeru ale bohuzel nejsem to schopen vecpat parametricky do jednoho skriptu
	Takze pri opravach v elektromeru se musi rucne prepisovat opravy i sem 
--]]
	tmr.stop(1)
	tmr.stop(3)
	tmr.stop(4)
	local MinimalPower = 1 -- pro 1 pulz = 10 litru - to je 10 litru / hodinu
	local MaximalPower = 1000 -- pro 1 pulz = 10 litr - je to 10m3 / hodinu, vic nez dostatecne,
	
-- citace, casovace a akumulatory
	local Time_Faze = {-1,-1,-1} -- cas predchoziho pulzu pro jednotlive vstupy (v uS - citac tmr.now)
	local Time_Long = {0,0,0} -- extra cas pro mereni zalezitosti pres 40 minut dlouhych
	local Time_Rotation = 0 -- pro detekci pretoceni
	local Time_Capture -- pro casovani opakovani mereni, nejde to udelat opakovacim casovacem, protoze pokud se neco zpozdi, tak by mohlo pristi 
	-- mereni vletet do jeste probihajiciho predchoziho a potrebuju si merit cas kdy jsem mereni zahajil abych dodrzoval, pokud se stiha periodu
	
-- Debug
	local DebugPower = 0 -- pokud se nadefinuje tak to vypisuje moc vypisu

-- Pro prumerovani (plynomer only)
	local Average_Counter = 0
	local Average_Data = {}
	local Average = 0
	
-- promenne pro digitalizaci analogoveho signal (plynomer only)
	-- Digitize_Minimum a Digitize_Maximum jsou globalni protoze si je cde odesilac a posila je ven, takze ty tu nejsou
	local Digitize_LastValue = {-1,-1,-1}
	local Digitize_TimeFilter = {0,0,0}
	
-- Defajny nastavujici parametry skenovani analogoveho vstupu
	local DIGITIZE_MINIMAL_SPAN = {180,180,180} -- minimalni rozkmit maxima a minima aby se zacali zpracovavat data
	local DIGITIZE_STICKY = {0.0001,0.0001,0.0001} -- priblizovani limitu k namerene hodnote, pokud hodnota nezvysi limit
	local DIGITIZE_TIME = {2,2,2} -- casova filtrace na digitalni urovni, pocet po sobe jdoucich 1 aby to byla 1
	local POCET_MERENI = {3,3,3} -- zde se nastavuje pocet vycteni ad prevodniku pro jeden scan, tedy prumerovani
	local ANALOG_CAPTURE_PERIOD = 100 -- v milisekundach perioda mereni analogoveho vstupu (jednoho cyklu vice vstupu)

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
            if timedif < 0 then -- kontrola zda hodnota neni zaporna, pokud jo jednorazove ji opravim, nema vliv na dlouhodobe snizovani
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
        -- konec kriticke sekce

    end
      
-- Uprava vykonu pokud se nic nedeje
    local function ZpracujPauzu()

        -- snizeni vykonu kdyz se nic nedeje
        local i,power,powermem,timedif
        local timenow = tmr.now()
        for i=1,3 do 
			if Measure_Faze[i] ~= nil then -- pro elektromery s mene fazema, nemam piny na to abych z nich cetl
				-- standardnim zpusobem spocitam diferenci pro urceni vykonu
				timedif = timenow - Time_Faze[i] + Time_Long[i]
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
					print("M> ["..i.."] now="..timenow.." rot="..Time_Rotation.." dif="..timedif.." faze="..Time_Faze[i].." lon="..Time_Long[i])
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
						-- timedif se zmenil, je nutne ho spocitat znova
						timedif = timenow - Time_Faze[i] + Time_Long[i]
					end
				end
				power = -1 -- protoze nasledujici blok nemusi teoreticky projit, debug vystup by zkolaboval, kdyby mel power nedefinovany
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
				if Debug == 1 then print(string.format("M> [%d] power in/out=%.3f / %.3f",i,power,Power_Faze[i])) end 
			end
		end
		Time_Rotation = timenow -- zaznamenam si novy cas
		power = nil
		timenow = nil
		timedif = nil
		i = nil
    end
	
-- Zpracovani digitalni hotnoty - casova filtrace	
	local function ProcessDigital(_digivalue,_kanal)
		if Digitize_LastValue[_kanal] == -1 then -- startujeme prvni pruchod
			Digitize_LastValue[_kanal] = _digivalue -- zapiseme si stav a nic nedelame, cekame na prvni zmenu
			Digitize_TimeFilter[_kanal] = DIGITIZE_TIME[_kanal]+1 -- nastavim filtracni jako kdyz uz na te hodnote stoji dlouho
			return
		end
		if _digivalue == Digitize_LastValue[_kanal] then -- pokud se hodnota od posledniho scanu nezmenila
			if Digitize_TimeFilter[_kanal] < DIGITIZE_TIME[_kanal] then -- pokud je to tesne po zmene 
				Digitize_TimeFilter[_kanal] = Digitize_TimeFilter[_kanal] + 1 -- pouze zvysuji casovy citac
				if Digitize_TimeFilter[_kanal] >= DIGITIZE_TIME[_kanal] then -- jestlize zvysenim o 1 doslo k dosazeni limitu
					if _digivalue == 1 then -- a jsme v logicke jednotce
						if Debug == 1 then print("M> ".._kanal..":up @ "..(tmr.now()/1000000)) end
						CitacInterni(_kanal) -- zavolam zpracovani na faze (pouziva dale kod elektromeru)
					else
						if Debug == 1 then print("M> ".._kanal..":down @ "..(tmr.now()/1000000)) end
					end
				end
			end
		else -- hodnota se zmenila
			Digitize_LastValue[_kanal] = _digivalue -- ulozim si novou hodnotu
			Digitize_TimeFilter[_kanal] = 0 -- vynuluju filtracni citac
		end	
	end
	
-- Zpracovani analogove hodnoty a prevod na digitalni
	local function ProcessPoint(_kanal)
		local _value = Digitize_Average[_kanal] -- vyctu si z globalni promenne
		if (Digitize_Maximum[_kanal] - Digitize_Minimum[_kanal]) < DIGITIZE_MINIMAL_SPAN[_kanal] then 
			--[[ Vzdalenost minima a maxima neni pripravena pro provoz, v tomto rezimu pouze 
			vyhledavam maximum a minimum z namerenych bodu a cekam az se od sebe vzdali dostatecne daleo
			toto je nabehovy rezim, do kteho by se mohl system vratit za provozu pouze tak, ze by
			se hodnoty v horni a dolni polovine rozsahu priblizili pod tuto mez, coz by ale znamenalo
			nejakou zavadu ve snimani a tudis by to bylo vlastne koser ]]--
			if _value > Digitize_Maximum[_kanal] then 
				Digitize_Maximum[_kanal] = _value
			end	
			if _value < Digitize_Minimum[_kanal] then
				Digitize_Minimum[_kanal] = _value
			end
			Digitize_Status[_kanal] = 3
		else 
		--[[ Provozni rezim je ustanoven. V tomto rezimu si rozdeluji rozsah mezi hodnotami 
		na dve poloviny, pokud jsem v dolni polovine tak bud minimum snizim na uroven hodnoty
		ktera je pod nim a nebo pokud je nad nim, tak minimum posunu o kousek nahoru. Opacne
		se deje v horni polovine. Takze maximum a minimum se neustale snazi dostat do stredu 
		ale zaroven je hodnotami srazeno dolu a nahoru. 
		Taky se tu jako prvni zpracuje hodnota na to zda je to logicka nula nebo jednicka a 
		zavola zpracovani digitalni hodnoty ]]--
		
			local LowZone = Digitize_Minimum[_kanal] + ((Digitize_Maximum[_kanal] - Digitize_Minimum[_kanal]) / 3) -- hranice dolni zony
			local HighZone = Digitize_Maximum[_kanal] - ((Digitize_Maximum[_kanal] - Digitize_Minimum[_kanal]) / 3) -- hranice horni zony
			local Center = (Digitize_Maximum[_kanal] + Digitize_Minimum[_kanal]) / 2 -- prumerna stredni hodnota
		
			if _value > HighZone then -- hodnota se nachazi v horni polovine
				--if Debug == 1 then print("M> log:HIGH") end
				ProcessDigital(1,_kanal)
				if _value > Digitize_Maximum[_kanal] then -- hodnota utekla za maximum
					Digitize_Maximum[_kanal] = _value 
					rtcmem.write32(10+_kanal-1, Digitize_Maximum[_kanal])
				else -- hodnota se nachazi mezi maximem a stredem
					local Distance = Digitize_Maximum[_kanal] - _value -- vzdalenost mezi maximem a hodnotou
					Digitize_Maximum[_kanal] = Digitize_Maximum[_kanal] - (Distance * DIGITIZE_STICKY[_kanal]) -- přisunu maximum o zlomek vzdalenosti aktualni hodnoty
					rtcmem.write32(10+_kanal-1, Digitize_Maximum[_kanal])
					Distance = nil
				end
				Digitize_Status[_kanal] = 1
			else 
				if _value < LowZone then -- hodnota se nachazi v dolni polovine (nebo na stredu)
					--if Debug == 1 then print("M> log:LOW") end
					ProcessDigital(0,_kanal)
					if _value < Digitize_Minimum[_kanal] then -- hodnota utekla pod minimum
						Digitize_Minimum[_kanal] = _value 
						rtcmem.write32(7+_kanal-1, Digitize_Minimum[_kanal])
					else -- hodnota se nachaz9 mezi mininimem a stredem
						local Distance = _value - Digitize_Minimum[_kanal] -- vzdalenos mezi hodnotou a minimem
						Digitize_Minimum[_kanal] = Digitize_Minimum[_kanal] + (Distance * DIGITIZE_STICKY[_kanal]) -- zvednu minimum o nejaky zlomek vzdalenosti od aktualni hodnoty
						rtcmem.write32(7+_kanal-1, Digitize_Minimum[_kanal])
						Distance = nil
					end
					Digitize_Status[_kanal] = 0
				else -- pozice je v zakazane oblasti ze ktere se to musi casem taky mit moznost dostat a to tak ze se zuzuje obema smery
					local Distance = _value - Digitize_Minimum[_kanal] -- vzdalenos mezi hodnotou a minimem
					Digitize_Minimum[_kanal] = Digitize_Minimum[_kanal] + (Distance * DIGITIZE_STICKY[_kanal]) -- zvednu minimum o nejaky zlomek vzdalenosti od aktualni hodnoty
					Distance = Digitize_Maximum[_kanal] - _value -- vzdalenost mezi maximem a hodnotou
					Digitize_Maximum[_kanal] = Digitize_Maximum[_kanal] - (Distance * DIGITIZE_STICKY[_kanal]) -- přisunu maximum o zlomek vzdalenosti aktualni hodnoty
					rtcmem.write32(7+_kanal-1, Digitize_Minimum[_kanal])
					rtcmem.write32(10+_kanal-1, Digitize_Maximum[_kanal])
					Distance = nil
					Digitize_Status[_kanal] = 2
				end
			end
			
			Center,LowZone,HighZone = nil,nil,nil
		end
	end
	
-- Opakovane nasnimani analogove hodnoty a vytvoreni "prumeru"
	local function CaptureAnalog(_channel)
		Average_Data[Average_Counter] = adc.read(0)
		Average_Counter = Average_Counter + 1
		if Average_Counter <= POCET_MERENI[_channel] then 
			tmr.alarm(4, math.random(5,15), 0,  function() CaptureAnalog(_channel) end)
		else -- nacteno dost dat provedu ocisteni
			gpio.write(Measure_Faze[_channel],gpio.HIGH)  -- zhasnu led, uz nepotrebuju svitit na snimac, delam to jako prvni 
			-- aby pokud mozno v dalsim kroku sekvence nedochazelo k dosvicovani predchoziho kanalu
			
			-- tady to mam v poli a muzu si s tim delat cokoliv alezatim s tim udelam jen prumer
			local Sum = 0
			local q
			for q = 1,POCET_MERENI[_channel],1 do
				Sum = Sum + Average_Data[q]
			end
			--if Debug == 1 then print("avr:"..(Sum/POCET_MERENI)) end
			Sum = Sum / POCET_MERENI[_channel] -- sum uz neni suma ale prumer
			Digitize_Average[_channel] = Sum -- ulozim si prumer pro dalsi zpracovani a taky pro odeslani na cloud
			-- vypocet odchlky
			local Dev = 0
			for q = 1,POCET_MERENI[_channel],1 do
				Dev = Dev + ((Sum - Average_Data[q])^2)
			end
			Dev = Dev / POCET_MERENI[_channel] -- prumerna odchylka
			Digitize_Deviate[_channel] = Dev
			Dev, Sum, q = nil
			-- konec vypoctu statistiky, nyni probehne zpracovani podle hodnot zapsanych v globalnich polich
			ProcessPoint(_channel)
			if Measure_Faze[_channel+1] ~= nil then -- jeste je definovan dalsi iluminat
				StartAnalogG(_channel+1) -- tady volam funkci definovanou nize, musi byt tedy globalni
			else
				-- vse je zmereno, je potreba nastavit cekani na dalsi mereni
				local td = tmr.now() - Time_Capture -- spocitam jak dlouho me trvalo mereni
				if td < 0 then -- stat se muze ze se pretoci casovac a pak to vyjde zaporne
					td = td + 2147483647 -- vime do kolika casovac pocita takze se pretoceni da snadno eliminovat
				end
				td = td / 1000 -- lepsi bude to prevest na milisekundy, nez pracovat v mikrosekundach
				Digitize_CaptureTime = td -- odlozim do globalni promenne pro analyticke reporty
				td = ANALOG_CAPTURE_PERIOD - td -- spocitam kolik milisekund zbyva do pozadovane doby jedne periody opakovani mereni
				if td <= 0 then -- kdybych nahodou nestihal
					td = 1 -- tak nastavin casovac na jednu milisekundu, cili spoustit to co nejdrive jde
				end
				tmr.alarm(4, 5, 0,  function() StartAnalogG(1) end) -- s urcitim zpozdenim odstartuji dalsi sekvenci mereni
			end
		end
	end
	
-- Opakovane spousteni zpracovani dat
	local function StartAnalog(_kanal)
		-- mereni casu
		if _kanal == 1 then -- delam jen u prvniho kanalu ze sekvence
			Time_Capture = tmr.now()
		end
		-- rozsvitim  IR kalanl
		gpio.mode(Measure_Faze[_kanal],gpio.OUTPUT)
        gpio.write(Measure_Faze[_kanal],gpio.LOW) 
		-- spustim mereni na prvni kanale
		Average_Counter = 1
		Average_Data = {}
		-- spustim mereni pres casovac aby se stihli rozsvitit IR led, tento cas zohlednuje to ze se IR led v detektoru rozsviti
		tmr.alarm(4, 10, 0,  function() CaptureAnalog(_kanal) end)
	end
	function StartAnalogG(_kanal)
		StartAnalog(_kanal)
	end
  
    
-- Nacasu prvni odeslani
	Digitize_Minimum[1], Digitize_Minimum[2], Digitize_Minimum[3], Digitize_Maximum[1], Digitize_Maximum[2], Digitize_Maximum[3] = rtcmem.read32(7,6) -- nactu si pamet 7 a 8

	--tmr.alarm(3, ANALOG_CAPTURE_PERIOD, 1,  function() StartAnalog(1) end) -- pousti se opakovane
	tmr.alarm(3, 10, 0,  function() StartAnalog(1) end) -- odstartuji prvni mereni

    tmr.alarm(1, 1000, 1,  function() ZpracujPauzu() end) -- pousti se opakovane
