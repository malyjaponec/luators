--[[ measure.lua
    zpracovani pulzu je zcela odvozeno z elektromeru a melo by se zachovat synchonni a neni potreba komentovat
	
	vyroba pulzu ale vznika jinak nez u elektromeru, pocita se filtraci ze dvou hall sond tak aby se omezil problem zachvevu vrtule,
	ktera se nutne musi pohybovat lehce a pri sebemensi tlakove zmene v systemu se muze pohnout a pokud je hall sonda na hranici urovni
	nutne zacne generovat pulzy proto se pulzy filtruji jednak na dobu trvani a jednak na pravidelne stridani dvou vstupu, pulzy z jednoho
	vstupu bez toho aby mezi tim byl druhy se ignoruji. Je potreba zajistit aby snimace byly dost daleko a nedochazelo k prekryvani a
	zaroven nesmi byt moc daleko kvuli tomu ze magnet ve vodomeru ma obvykle 2 shodne poly proti sobe, tedy optimalni pozice je 90 stupnu
	s tim ze pokud se kolecko bude otacet o vic jak 90 stupnu nelze zarucit eliminaci problemu, pri pouziti zpetneho ventilu by k tomu 
	dochazet nemelo a pohyb by mel byt pouze lehce dopredny, ale to nemam takze uvidime.
--]]
    tmr.stop(1)
    local MinimalPower = 1
	local MaximalPower = 200000
	--[[ pro vodomer 20ml na otacku resp 10ml na jeden magneticky puls je to je
		 10 ml/hod vs. 2 m3/hod, tedy 33 l/min
	]]
		 
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
            if timedif < 0 then -- kontrola zda hodnota neni zaporna, pokud jo jednorazove ji opravim, nema vliv na dlouhodobe snizovani
                timedif = timedif + 2147483647 
            end
            Time_Faze[_kanal] = timenow
            Time_Long[_kanal] = 0
            if timedif > 0 then -- Pro jistotu, kdyby mi pres predchozi upravy a podminky proslo zaporne cislo, tak ho zahodim 
				-- a do vypoctu vykonu ho nezapocitam
                local power = 3600000000/timedif -- hodnota ve pulzech za hodinu
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

-- Zpracovani dualnich vstupu
	digi_filter = {}
	digi_filter[1] = {0,0,0}
	digi_filter[2] = {0,0,0}
	digi_time = {}
	digi_time[1] = {0,0,0}
	digi_time[2] = {0,0,0}
	digi_last = {}
	digi_last[1] = {0,0,0}
	digi_last[2] = {0,0,0}
	digi_block = {0,0,0}
	
	local function SkenujVstupy()
		for  i=1,3 do
			local level = {}
			if nil ~= Measure_Faze[i] then -- Pokud neni definovan vstup preskakujeme
				-- pokud je vstup definovan, nactu si vstup A a B, uz nekontroluji zda je nadefinovan B, to musi zajistit uzivatel
				level[1],level[2] = gpio.read(Measure_Faze[i]),gpio.read(Measure_FazeB[i])
				for q=1,2 do
					if level[q] == digi_filter[q][i] then -- hodnota je shodna s predchozi
						if digi_time[q][i] < 10 then -- omezeni na zbytecne velka cisla
							digi_time[q][i] = digi_time[q][i] + 1 -- pocitam si dobu setrvani v jedne ustali
						end
						if digi_time[q][i] == 2 then -- prave X shodne hodnoty po sobe muzu se zacit zabyvat tim zda je to platna zmena

							gpio.mode(7,gpio.OUTPUT)
							gpio.write(7,gpio.HIGH) 

							if level[q] ~= digi_last[q][i] then -- 3 hodnoty maji opacnou uroven nez zapamatovana hodnota, to je platna zmena
								digi_last[q][i] = level [q] -- zmenim si ji abych priste detekoval zmenu do opacne urovne
								if level[q] == gpio.HIGH then -- logicka jednotka, pro pocitani puluzu beru jen prechod L->H
									if q == 1 then -- obsluha primarniho vstupu
										if digi_block[i] == 0 then -- prave pokud neni nastavena blokace 
											digi_block[i] = 1 -- jako prvni nastavim blokaci
											CitacInterni(i)
										end -- pokud je nastavena blokace vubec me prechod L->H nezajima nedelam nich
									else -- obsluha sekundarniho pulzu
										digi_block[i] = 0 --[[ zrusim blokaci a proto je vhodne mit nastavene pulzy tak, aby se neprekryvali nebo mohou
														  ale vzdalenost mezi tim kdy mohou vznikat nabezne hrany by mela byt maximalni tak aby se
														  eliminovalo co nejversi otaceni kolecka, ktere neni spojene s odberem vody, to znamena v 
														  mem pripade 90 stupnu a nastavit komparatory tak aby byla sirka 1 pulzu co nejuzsi a pritom 
														  potom ale nema cenu delat tu filtraci 3 pulzu po sobe ... zakmity na prechodech se odstrani tim
														  ze kmnita vzdy pouze jeden vstup, nastesti lze zmenou konstanty filtr uplne eliminovat ]]
									end
								end
							end
		
							gpio.write(7,gpio.LOW) 
							
						end
					else -- hodnota je jina nez posledne
						digi_filter[q][i] = level[q] -- zapisu si novou hodnotu vstupu pro porovnani priste
						digi_time[q][i] = 0 -- nuluji citac stejne hodnoty
					end
				end
			end
			level = nil
		end
		 
        tmr.alarm(3, 5, 0, function() SkenujVstupy() end)
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
					power = 3600000000/timedif -- hodnota v puzech za hodinu, standardni vypocet jako nahore
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
      
-- Nastaveni pinu na vstup z hall sond, pocitam s tim ze vstupy maji tvrdy vystup, cili zadne pull-up-down 
    if Measure_Faze[1] ~= nil then
        gpio.mode(Measure_Faze[1], gpio.INPUT, gpio.FLOAT)
        gpio.mode(Measure_FazeB[1], gpio.INPUT, gpio.FLOAT)
    end
    if Measure_Faze[2] ~= nil then
        gpio.mode(Measure_Faze[2], gpio.INPUT, gpio.PULLUP)
        gpio.mode(Measure_FazeB[2], gpio.INPUT, gpio.PULLUP)
    end
    if Measure_Faze[3] ~= nil then
        gpio.mode(Measure_Faze[3], gpio.INPUT, gpio.PULLUP)
        gpio.mode(Measure_FazeB[3], gpio.INPUT, gpio.PULLUP)
    end

-- Nacasu prvni odeslani
    tmr.alarm(1, 1000, 1, function() ZpracujPauzu() end) 
	tmr.alarm(3, 100, 0, function() SkenujVstupy() end)
	