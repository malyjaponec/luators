-- measure.lua
    tmr.stop(TM["m"])

-- globalni citace pro 2 elektromer
    MeasureCounter = 11
    PCount1 = 0
    PCount2 = 0

-- Citaci funkce
    function CitacPulzu1(level)
        local timenow = tmr.now()
        PCount1 = PCount1 + 1
        local timedif = timenow - PowerTimer1
        PowerTimer1 = timenow
        if timedif > 0 then -- Pri pretoceni casovace jednou za 40 minut vyjde zaporna hodnota a tu zahodim
            Power1 = 1800000000/timedif -- hodnota ve watech (pri pulzu 0,5Wh)
        end
        gpio.trig(Pulzy1, "down") 
        --if level == 1 then gpio.trig(Pulzy1, "down") else gpio.trig(Pulzy1, "up") end
    end
      
-- Odesilaci funkce
    local function AktivujOdeslani()
        --rgb cervena
        gpio.mode(GP[15], gpio.OUTPUT)     
        gpio.write(GP[15], gpio.HIGH)

        -- snizeni vykonu kdyz se nic nedeje
        local timedif = tmr.now() - PowerTimer1
        if timedif > 10000000 then -- jiz 10 sekund neprisel pulz prepocitam vykon
            local PowerX = 1800000000/timedif 
            if PowerX < Power1 then
                Power1 = PowerX
            end
        end

        if MeasureCounter > 0 then
            -- if Debug_M == 1 then uart.write(0,"\r\nm> "..PCount1.."/"..PCount2) end
            MeasureCounter = MeasureCounter - 1
            Rdat[Rpref.."power1"] = Power1
            Rdat[Rpref.."an"] = adc.read(0)
            Completed_Measure = 1
        else
            -- if Debug_M == 1then uart.write(0,"\r\nm> out "..PCount1.."/"..PCount2) end
            --rgb modra
            gpio.mode(GP[13], gpio.OUTPUT)     
            gpio.write(GP[13], gpio.HIGH)
            Rdat[Rpref.."power1"] = Power1
            Rdat[Rpref.."energy1"],PCount1 = PCount1/2,0
            Rdat[Rpref.."an"] = adc.read(0)
            
            Completed_Measure = 1
            MeasureCounter = 11
            --tmr.alarm(TM["m"], 10000, 0,  function() AktivujOdeslani() end) 
        end
        --rgb cervena
        gpio.mode(GP[15], gpio.OUTPUT)     
        gpio.write(GP[15], gpio.LOW)
        collectgarbage()
    end
      
-- Konfigurace, kam jsou elektromery pripojeny
    Pulzy1 = GP[4]
    
-- Nastaveni pinu
    gpio.mode(Pulzy1, gpio.INPUT, gpioPULLUP)
    gpio.mode(Pulzy1, gpio.INT, gpioPULLUP) 
    gpio.trig(Pulzy1, "down", CitacPulzu1)

    Power1 = 0
    PowerTimer1=0

-- Nacasu prvni odeslani
  tmr.alarm(TM["m"], 5000, 1,  function() AktivujOdeslani() end) 
  collectgarbage()
