--[[ measure_vodadual.lua

	Vychazi z plynomeru, nebot mereni aktualniho vykonu (prutoku) probiha digitalne a z analogovych dat
	se zpracovava jen mereni energie (spotreba vody).
	Pokud se neco zasadniho najde v plynomeru (chyba) je nutne to prevest rucne i sem.
--]]
	tmr.stop(1)
	tmr.stop(3)
	--[[ 
		GPIO4 - hall sonda nad magnetyckym koleckem - vodomer ma 20ml na otacku, 2 magneticke pulzy, coz je 10ml / pulz
		GPIO5 - infra zavora v prnvim prevodovem kolecku - 12 zubu magneticke a 48 zubu prvni prevodove s dirkama, celkem 10 otvoru, coz je 8ml / pulz
	]]
	-- pokud je power nizsi nez zeropower, posila se 0
	local ZeroPower = 1 -- pro mene nez 10mL za minutu
	-- pokud je power nizsi nez minimal, tak se i kdyz od zapnuti neprisel pulz zacne posilat tato hodnotami
	local MinimalPower = 10 -- pro mene nez 100ml za minutu
	local MaximalPower = 1500 -- pro vice nez 15l (10x1500) za minutu
	
-- citace, casovace a akumulatory
	local Time_Faze = -1 -- cas predchoziho pulzu pro jednotlive vstupy (v uS - citac tmr.now)
	local Time_Long = 0 -- extra cas pro mereni zalezitosti pres 40 minut dlouhych
	local Time_Rotation = 0 -- pro detekci pretoceni
	local Time_Capture -- pro casovani opakovani mereni, nejde to udelat opakovacim casovacem, protoze pokud se neco zpozdi, tak by mohlo pristi 
	-- mereni vletet do jeste probihajiciho predchoziho a potrebuju si merit cas kdy jsem mereni zahajil abych dodrzoval, pokud se stiha periodu
	
-- Debug
	--local DebugPower = 0 -- pokud se nadefinuje tak to vypisuje moc vypisu

-- Pro prumerovani (plynomer only)
	local Average_Counter = 0
	local Average_Data = {}
	local Average = 0
	
-- promenne pro digitalizaci analogoveho signal (plynomer only)
	-- Digitize_Minimum a Digitize_Maximum jsou globalni protoze si je cde odesilac a posila je ven, takze ty tu nejsou
	local Digitize_LastValue = -1
	local Digitize_TimeFilter = 0
	
-- Defajny nastavujici parametry skenovani analogoveho vstupu
	local DIGITIZE_MINIMAL_SPAN = 200 -- minimalni rozkmit maxima a minima aby se zacali zpracovavat data
	local DIGITIZE_STICKY = 0.000001 -- priblizovani limitu k namerene hodnote, pokud hodnota nezvysi limit
	local DIGITIZE_TIME = 2 -- casova filtrace na digitalni urovni, pocet po sobe jdoucich 1 aby to byla 1
	local POCET_MERENI = 3 -- zde se nastavuje pocet vycteni ad prevodniku pro jeden scan, tedy prumerovani
	local ANALOG_CAPTURE_PERIOD =100 -- v milisekundach perioda mereni analogoveho vstupu (jednoho cyklu vice vstupu)
	local MEASURE_LED = 4 -- GPIO2 modra led na ESP12

-- Generalizovana citaci funkce
	local function CitacPulzu(_level)
		if nil ~= MEASURE_LED then 
			gpio.write(MEASURE_LED, gpio.LOW)	
		end
		if _level == gpio.LOW then
			-- jako prvni si zaznamenam cas pulzu aby to neyblo ovlivneno nejakym dalsimi nedeterministickymi vypocty
			local timenow = tmr.now()
			-- spocitam cas od posledniho pulzu - periodu a ulozim si aktualni casovou znacku pro priste
			local timedif = timenow - Time_Faze + Time_Long
			if Time_Faze == -1 then -- po startu nevim kdy byl predchozi pulz, pouze ulozim cas a necham power na -1
				Time_Faze = timenow
				Time_Long = 0
			else
				-- kontroluji zda casva diference dava smysl pro aktualizaci vykonu a kdyz jo aktualizuji
				if timedif < 0 then -- kontrola zda hodnota neni zaporna, pokud jo jednorazove ji opravim, nema vliv na dlouhodobe snizovani
					timedif = timedif + 2147483647 
				end
				Time_Faze = timenow
				Time_Long = 0
				if timedif > 0 then -- Pro jistotu, kdyby mi pres predchozi upravy a podminky proslo zaporne cislo, tak ho zahodim 
					-- a do vypoctu vykonu ho nezapocitam
					local power = 60000000/timedif -- hodnota ve watech, pokud je pulz 1Wh (jinak se to musi prepocitat na serveru
					if power < MaximalPower then -- nepripustim ze bych meril neco velkeho, to uz zavani zakmity
						-- Primitivni prumerovani
						Power_Faze = Power_Faze * 0.75 + power * 0.25
						rtcmem.write32(4, power*1000) -- zapisu si hodnotu tez do RTC memory pro pripad restartu
					end
					power = nil
				end
			end
			Digitize_WaterFlows = 1 -- kdyz tece voda, nemerime dalas
			timedif = nil
			timenow = nil
		end
		if nil ~= MEASURE_LED then 
			gpio.write(MEASURE_LED, gpio.HIGH)	
		end
	end

-- Uprava vykonu pokud se nic nedeje
    local function ZpracujPauzu()
        -- snizeni vykonu kdyz se nic nedeje
        local i,power,powermem,timedif
        local timenow = tmr.now()

		-- standardnim zpusobem spocitam diferenci pro urceni vykonu
		timedif = timenow - Time_Faze + Time_Long
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
			print("M> now="..timenow.." rot="..Time_Rotation.." dif="..timedif.." faze="..Time_Faze.." lon="..Time_Long)
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
			if Time_Long < (2147483647*100) then -- tak to uz je fakt moc dlouho bez pulzu, tak nebudu pricitat
				Time_Long = Time_Long + 2147483647 -- zvysim aditivni hodnotu
				-- timedif se zmenil, je nutne ho spocitat znova
				timedif = timenow - Time_Faze + Time_Long
			end
		end
		power = -1 -- protoze nasledujici blok nemusi teoreticky projit, debug vystup by zkolaboval, kdyby mel power nedefinovany
		if (timedif > 0) then -- tohle je pro jistotu, nevim vubec jestli to cislo co pricitam je spravne
			power = 60000000/timedif -- hodnota ve watech pro pulz 1Wh, standardni vypocet jako nahore
			if power < MaximalPower then -- nepripustim ze bych meril neco velkeho, zde asi je jedno protoze nasleduje pouze snizovani ne zvysovani
				if (power < Power_Faze) then -- vypocteny vykon je nizsi nez predchozi, znamena to se ze se prodluzuji
				-- pulzy a je rozumne pouzit cas ktery je ted protoze je nejspib blize realite nez predchozi perioda
				-- takze opravim vykon na aktualni delku bezpulzi
					if power < ZeroPower then Power_Faze = 0 else Power_Faze = power end
					rtcmem.write32(4, power*1000) -- zapisu si hodnotu tez do RTC memory pro pripad restartu
				end
			end
			if (Power_Faze == -1) then -- pokud jeste nemam zadnou hodnotu vykonu, tohle se provede fakt jen na zacatku jednou
				local powermem = rtcmem.read32(4)/1000 -- prectu si hodnotu z pameti, pokud doslo k jejimu resetu bude tam 0
				if powermem ~= 0 then -- pokud v pameti neco je, pak to pouziju, nulu budu ignorovat
					if Debug == 1 then print("M> restored power="..powermem) end 
					if powermem < ZeroPower then Power_Faze = 0 else Power_Faze = powermem end-- opravim si aktualni hodnotu na to co je v pameti
					Time_Long = 60000000/powermem - timenow -- nastavim si virtualne long time aby odpovidal vykonu a ten se hnedka dale snizoval
					-- vysledek je sice necelociselny, ale kdyz se udela math.floor vznikne z toho int 2,1 miliardy a to je malo pro vypocty co potrebujem
					if Time_Long < 0 then Time_Long = 0 end -- pro pripad ze v pameti je neco extremniho a
					-- nacetlo by se to hodne pozde a odectenim timenow by vznikl zaporny cas, je tady tato kontrola
				else
					if Debug == 1 then print("M> saved power invalid") end 
					Power_Faze = -2 -- prepnu se do stavu, kdy z pameti se nic rozumneho nenacedlo a cekam na pokles vykonu na "rozumnou" hodnotu
					-- toto je vhodne aby to neustale necetlo hodnotu z RTC pameti a nezjistovalo ze je nulova
				end
				powermem = nil
			end
			if (Power_Faze == -2) then -- pokud jsem jiz zkusit nacist hodnotu z pameti ale byla nulova
				if (power < MinimalPower) then -- pokud stale nebyl predan vykon,
					-- a dosahli jsme casem rozumne nizke hodnoty, zacnu ji predavat
					if power < ZeroPower then Power_Faze = 0 else Power_Faze = power end
				end
			end
		end
		if Debug == 1 then print(string.format("M> power in/out=%.3f / %.3f",power,Power_Faze)) end 
			
		Time_Rotation = timenow -- zaznamenam si novy cas
		power = nil
		timenow = nil
		timedif = nil
    end
	
-- Zpracovani digitalni hotnoty - casova filtrace	
	local function ProcessDigital(_digivalue)
		if Digitize_LastValue == -1 then -- startujeme prvni pruchod
			Digitize_LastValue = _digivalue -- zapiseme si stav a nic nedelame, cekame na prvni zmenu
			Digitize_TimeFilter = DIGITIZE_TIME+1 -- nastavim filtracni jako kdyz uz na te hodnote stoji dlouho
			return
		end
		if _digivalue == Digitize_LastValue then -- pokud se hodnota od posledniho scanu nezmenila
			if Digitize_TimeFilter < DIGITIZE_TIME then -- pokud je to tesne po zmene 
				Digitize_TimeFilter = Digitize_TimeFilter + 1 -- pouze zvysuji casovy citac
				if Digitize_TimeFilter >= DIGITIZE_TIME then -- jestlize zvysenim o 1 doslo k dosazeni limitu
					if _digivalue == 1 then -- a jsme v logicke jednotce
						if Debug == 1 then print("M> up @ "..(tmr.now()/1000000)) end
						-- puvodne se v plynomeru volalo zpracovani pulzu, ale tady se to pouziva jen pro evidenci spotreby
						-- cili pouze inkrementuji cinac pulzu

						-- zacatek kriticke sekce
							Energy_Faze = Energy_Faze + 1
						-- konec kriticke sekce
					else
						if Debug == 1 then print("M> down @ "..(tmr.now()/1000000)) end
					end
				end
			end
		else -- hodnota se zmenila
			Digitize_LastValue = _digivalue -- ulozim si novou hodnotu
			Digitize_TimeFilter = 0 -- vynuluju filtracni citac
		end	
	end
	
-- Zpracovani analogove hodnoty a prevod na digitalni
	local function ProcessPoint(_value)
		if (Digitize_Maximum - Digitize_Minimum) < DIGITIZE_MINIMAL_SPAN then 
			--[[ Vzdalenost minima a maxima neni pripravena pro provoz, v tomto rezimu pouze 
			vyhledavam maximum a minimum z namerenych bodu a cekam az se od sebe vzdali dostatecne daleo
			toto je nabehovy rezim, do kteho by se mohl system vratit za provozu pouze tak, ze by
			se hodnoty v horni a dolni polovine rozsahu priblizili pod tuto mez, coz by ale znamenalo
			nejakou zavadu ve snimani a tudis by to bylo vlastne koser ]]--
			if _value > Digitize_Maximum then 
				Digitize_Maximum = _value
			end	
			if _value < Digitize_Minimum then
				Digitize_Minimum = _value
			end
			Digitize_Status = 3
		else 
		--[[ Provozni rezim je ustanoven. V tomto rezimu si rozdeluji rozsah mezi hodnotami 
		na dve poloviny, pokud jsem v dolni polovine tak bud minimum snizim na uroven hodnoty
		ktera je pod nim a nebo pokud je nad nim, tak minimum posunu o kousek nahoru. Opacne
		se deje v horni polovine. Takze maximum a minimum se neustale snazi dostat do stredu 
		ale zaroven je hodnotami srazeno dolu a nahoru. 
		Taky se tu jako prvni zpracuje hodnota na to zda je to logicka nula nebo jednicka a 
		zavola zpracovani digitalni hodnoty ]]--
		
			local LowZone = Digitize_Minimum + ((Digitize_Maximum - Digitize_Minimum) / 3) -- hranice dolni zony
			local HighZone = Digitize_Maximum - ((Digitize_Maximum - Digitize_Minimum) / 3) -- hranice horni zony
			local Center = (Digitize_Maximum + Digitize_Minimum) / 2 -- prumerna stredni hodnota
		
			if _value > HighZone then -- hodnota se nachazi v horni polovine
				ProcessDigital(1)
				if _value > Digitize_Maximum then -- hodnota utekla za maximum
					Digitize_Maximum = _value 
					rtcmem.write32(10, Digitize_Maximum)
				else -- hodnota se nachazi mezi maximem a stredem
					local Distance = Digitize_Maximum - _value -- vzdalenost mezi maximem a hodnotou
					Digitize_Maximum = Digitize_Maximum - (Distance * DIGITIZE_STICKY) -- přisunu maximum o zlomek vzdalenosti aktualni hodnoty
					rtcmem.write32(10, Digitize_Maximum)
					Distance = nil
				end
				Digitize_Status = 1
			else 
				if _value < LowZone then -- hodnota se nachazi v dolni polovine (nebo na stredu)
					ProcessDigital(0)
					if _value < Digitize_Minimum then -- hodnota utekla pod minimum
						Digitize_Minimum = _value 
						rtcmem.write32(7, Digitize_Minimum)
					else -- hodnota se nachazi mezi mininimem a stredem
						local Distance = _value - Digitize_Minimum -- vzdalenos mezi hodnotou a minimem
						Digitize_Minimum = Digitize_Minimum + (Distance * DIGITIZE_STICKY) -- zvednu minimum o nejaky zlomek vzdalenosti od aktualni hodnoty
						rtcmem.write32(7, Digitize_Minimum)
						Distance = nil
					end
					Digitize_Status = 0
				else -- pozice je v zakazane oblasti ze ktere se to musi casem taky mit moznost dostat a to tak ze se zuzuje obema smery
					local Distance = _value - Digitize_Minimum -- vzdalenos mezi hodnotou a minimem
					Digitize_Minimum = Digitize_Minimum + (Distance * DIGITIZE_STICKY) -- zvednu minimum o nejaky zlomek vzdalenosti od aktualni hodnoty
					Distance = Digitize_Maximum - _value -- vzdalenost mezi maximem a hodnotou
					Digitize_Maximum = Digitize_Maximum - (Distance * DIGITIZE_STICKY) -- přisunu maximum o zlomek vzdalenosti aktualni hodnoty
					rtcmem.write32(7, Digitize_Minimum)
					rtcmem.write32(10, Digitize_Maximum)
					Distance = nil
					Digitize_Status = 2
				end
			end
			
			Center,LowZone,HighZone = nil,nil,nil
		end
	end
	
-- Opakovane nasnimani analogove hodnoty a vytvoreni "prumeru"
	local function CaptureAnalog()
		Average_Data[Average_Counter] = adc.read(0)
		Average_Counter = Average_Counter + 1
		if Average_Counter <= POCET_MERENI then 
			tmr.alarm(4, math.random(5,15), 0,  function() CaptureAnalog() end)
		else -- nacteno dost dat provedu ocisteni
			-- tady to mam v poli a muzu si s tim delat cokoliv alezatim s tim udelam jen prumer
			local Sum = 0
			local q
			for q = 1,POCET_MERENI,1 do
				Sum = Sum + Average_Data[q]
			end
			--if Debug == 1 then print("avr:"..(Sum/POCET_MERENI)) end
			Sum = Sum / POCET_MERENI -- sum uz neni suma ale prumer
			Digitize_Average = Sum -- ulozim si prumer pro dalsi zpracovani a taky pro odeslani na cloud
			-- vypocet odchlky
			local Dev = 0
			for q = 1,POCET_MERENI,1 do
				Dev = Dev + ((Sum - Average_Data[q])^2)
			end
			Dev = Dev / POCET_MERENI -- prumerna odchylka
			Digitize_Deviate = Dev
			Dev, Sum, q = nil
			-- konec vypoctu statistiky, nyni probehne zpracovani podle hodnot zapsanych v globalnich polich
			ProcessPoint(Digitize_Average)
			-- vse je zmereno, je potreba nastavit cekani na dalsi mereni
			local td = tmr.now() - Time_Capture -- spocitam jak dlouho me trvalo mereni
			if td < 0 then -- stat se muze ze se pretoci casovac a pak to vyjde zaporne
				td = td + 2147483647 -- vime do kolika casovac pocita takze se pretoceni da snadno eliminovat
			end
			td = td / 1000 -- lepsi bude to prevest na milisekundy, nez pracovat v mikrosekundach
			Digitize_CaptureTime = td -- odlozim do globalni promenne pro analyticke reporty
			td = ANALOG_CAPTURE_PERIOD - td -- spocitam kolik milisekund zbyva do pozadovane doby jedne periody opakovani mereni
            if td < 15 then
                if td <= 0 then -- kdybych nahodou nestihal
                    print("M> time missed "..td)     
                    td = 1 -- tak nastavin casovac na jednu milisekundu, cili spoustit to co nejdrive jde
                else
                    if Debug == 1 then print("M> time overload "..td) end      
                end
            end         
 			tmr.alarm(4, 5, 0,  function() StartAnalogG() end) -- s urcitim zpozdenim odstartuji dalsi sekvenci mereni
		end
	end
	
-- Opakovane spousteni zpracovani dat
	local function StartAnalog()
		-- mereni casu
		Time_Capture = tmr.now()
		-- spustim mereni
		Average_Counter = 1
		Average_Data = {}
		-- spustim mereni pres casovac i kdyz je to zbytecne
		tmr.alarm(4, 10, 0,  function() CaptureAnalog() end)
	end
	function StartAnalogG(_nic_nic)
		StartAnalog()
	end
  
-- Nastaveni pinu na preruseni pro mereni prutokou nikoli spotreby
    gpio.mode(Measure_Power, gpio.INPUT, gpio.PULLUP)
    gpio.mode(Measure_Power, gpio.INT, gpio.PULLUP) 
    gpio.trig(Measure_Power, "down", CitacPulzu)
    
-- Nacteni hodnot maxima a minima z RTC pameti v pripade resetu bez vypadku proudu
	Digitize_Minimum = rtcmem.read32(7,1) -- nactu si pamet 7 
	Digitize_Maximum = rtcmem.read32(10,1) -- a 10 
	-- je to zvlast protoze zachovavam to ze reset do 7,8,9 da minima a 10,11,12 da maxima aby to bylo shodne s plynomerem
	
-- Indikacni LED
	if nil ~= MEASURE_LED then 
		gpio.mode(MEASURE_LED, gpio.OUTPUT)
		gpio.write(MEASURE_LED, gpio.LOW)	
	end
	
-- Nacasovani zpracovani a mereni
	tmr.alarm(3, 10, 0,  function() StartAnalog(1) end) -- odstartuje mereni spotreby
    tmr.alarm(1, 1000, 1,  function() ZpracujPauzu() end) -- prepocitava prutok 
