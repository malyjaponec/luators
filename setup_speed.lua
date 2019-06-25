-- Nastaveni rychlosti default
	ReportInterval = 10*60    --ReportIntervalFast = 1*60 -- rychlost rychlych reportu, pokud je null tak se to nepouziva
	PeriodicReport = nil -- pokud je null pak se reportuje 1x a usne se, jakakoliv hodnota zpusobi neusnuti a restart po zadane dobe

-- Kontrola propojeni pinu GPIO4 na GND
	gpio.mode(gpionum[4], gpio.INPUT, gpio.PULLUP)

	if gpio.read(gpionum[4]) == 0 then 
			-- Nastavim fast rezim
			ReportInterval = 10    --ReportIntervalFast = 1*60 -- rychlost rychlych reportu, pokud je null tak se to nepouziva
			PeriodicReport = 1 -- pokud je null pak se reportuje 1x a usne se, jakakoliv hodnota zpusobi neusnuti a restart po zadane dobe
	end

	gpio.mode(gpionum[4], gpio.INPUT, gpio.FLOAT)

	if Debug == 1 then print("interval:" .. ReportInterval .. "s") end	
	
