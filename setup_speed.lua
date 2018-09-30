-- Nastaveni rychlosti default
	ReportInterval = 10*60    --ReportIntervalFast = 1*60 -- rychlost rychlych reportu, pokud je null tak se to nepouziva
	PeriodicReport = nil -- pokud je null pak se reportuje 1x a usne se, jakakoliv hodnota zpusobi neusnuti a restart po zadane dobe

-- Kontrola propojeni pinu GPIO0 a GPIO15
	gpio.mode(gpionum[2], gpio.OUTPUT, gpio.FLOAT)
	gpio.mode(gpionum[0], gpio.INPUT, gpio.PULLUP)

	gpio.write(gpionum[2], gpio.LOW)
4	if gpio.read(gpionum[0]) == 0 then 
		if Debug == 1 then print("check1") end	
		gpio.write(gpionum[2], gpio.HIGH)
		if gpio.read(gpionum[0]) == 1 then
			if Debug == 1 then print("check2") end	
			gpio.write(gpionum[2], gpio.LOW)
			if gpio.read(gpionum[0]) == 0 then 
				if Debug == 1 then print("check3") end		
				-- Nastavim fast rezim
				ReportInterval = 10    --ReportIntervalFast = 1*60 -- rychlost rychlych reportu, pokud je null tak se to nepouziva
				PeriodicReport = 1 -- pokud je null pak se reportuje 1x a usne se, jakakoliv hodnota zpusobi neusnuti a restart po zadane dobe
			end
		end
	end

	gpio.mode(gpionum[2], gpio.INPUT, gpio.FLOAT)
	gpio.mode(gpionum[0], gpio.INPUT, gpio.FLOAT)

	if Debug == 1 then print("interval:" .. ReportInterval .. "s") end	
	
