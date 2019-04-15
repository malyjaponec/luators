-- receive.lua

--------------------------------------------------------------------------------
local function ZpracujOdpoved(code, data)
     -- indikacni led zhasnu
     if LedSend ~= nil then 
        if LedSend > 0 then
			gpio.mode(LedSend, gpio.INPUT)
			gpio.write(LedSend, gpio.LOW)
		else
			gpio.mode(-LedSend, gpio.INPUT)
			gpio.write(-LedSend, gpio.HIGH)
		end
     end

    if (code == nil) then
        code = -100
    end

    if (code > 0) then
        if Debug == 1 then 
			print("p>data prijata/" .. code)
			print(data)
		end
		local values = sjson.decode(data)
		local k,v
		local count = 1 -- timto si pocitam index pro pristup k poli hodnot, ktere vratil server
		for k,v in pairs( GetFeeds ) do -- prochazim pole feedu a gpio tak jak z nej byl udelanej seznam pro URL
			if values[count] ~= nil then
				local value = tonumber(values[count])
				if value ~= nil then
					if v <= 16 then -- pouze GPIO do 16, vyssi cisla maji specialni vlastnosti
                        if v >= 0 then -- pouze pro kladne hodnoty
					    	gpio.mode(v, gpio.OUTPUT)
						    if value > 0 then -- kladna hodnota je logicka 1
   							    gpio.write(v, gpio.HIGH)
	    					else -- nula a zaporne cislo je logicka 0
		    					gpio.write(v, gpio.LOW)
			    			end
                        else -- zaporne hodnoty - otevreny kolektor, stale logicka hodnota odpovida napeti
                            v = -v
                            if value > 0 then -- kladna hodnota je odpojeny vstup
                                gpio.mode(v, gpio.FLOAT)
                            else -- nula je logicka nula
                                gpio.mode(v, gpio.OUTPUT)
                                gpio.write(v, gpio.LOW)
                            end
                        end                     
					else -- specialni vlastnosti
						if v == 17 then -- nastaveni rychlosti reportu do souboru config_speed.lua
							-- jako prvni porovna existujici nastaveni s tim co si to nacetlo
							-- timto se omezi neustale prepisovani souboru, kdyz nedoslo ke zmene
							-- na strane feedu
							if value ~= ReportInterval then -- je tam rozdil
								-- otevru souboru
								if file.open("setup_speed.lua","w") then -- soubor se podarilo otevrit
									file.writeline("ReportInterval = "..ReportInterval)
									-- pro intervaly kratsi nez 60s se nastavi jeste fast reporing
									if ReportInterval < 60 then
										file.writeline("PeriodicReport = 1") -- Pokud tahle promenna existuje prestane to usinat
									end
									file.close()
									-- Nazaver ten soubor vykonam abych zmenil parametry
									dofile("setup_speed.lua")
								end
							end
						end
					end
				end
			end
			count = count + 1 -- nesmim zapomenout zvysovat citac
		end
		values,value = nil,nil
		k,v,count = nil,nil,nil
	
    else
        if Debug == 1 then print("p>chyba/".. code) end
    end
    code = nil
    data = nil
	
	if PeriodicReport ~= nil then -- je pozadovano reportovat pravodelne
		dofile("reload.lc")
	else
		dofile("sleep.lua")
    end
end

--------------------------------------------------------------------------------
local function ZiskejData()

	-- z pole feedu vytvorim seznam
	local feedlist = ""
	local separator = ""
	local k,v
	for k,v in pairs( GetFeeds ) do
		feedlist = feedlist .. separator .. k
		separator = ","
	end
	separator,k,v = nil,nil,nil

    -- prevedu na URL
    local url = "http://emon.jiffaco.cz/feed/fetch.json?" .. 
                "&ids=" .. feedlist .. 
                "&apikey=" .. ReportApiKey
    http.get(url, nil, function(code,data) ZpracujOdpoved(code,data) end )
    url = nil -- url uz taky mazu
	feedlist = nil
    
	-- nacasuji kontrolu pokud nezavola callback a zasekne se to, tak se to bud uspi nebo restartuje   
	if PeriodicReport ~= nil then
		tmr.alarm(0, 15000, 0, function() dofile("restart.lua") end) 
	else
		tmr.alarm(0, 15000, 0, function() dofile("sleep.lua") end) 
	end
end

--------------------------------------------------------------------------------
tmr.alarm(0, 25, 0,  function() ZiskejData() end)  -- Na zacatku klidne muzu cekat dele

