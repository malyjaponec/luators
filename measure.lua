-- measure.lua
    tmr.stop(TM["m"])

-- globalni citace pro 2 elektromer
    MeasureCounter = 11
    PCount1 = 0
    PCount2 = 0

-- Citaci funkce
    function CitacPulzu1(level)
        PCount1 = PCount1 + 1
        gpio.trig(Pulzy1, "down") 
        --if level == 1 then gpio.trig(Pulzy1, "down") else gpio.trig(Pulzy1, "up") end
    end
      
    function CitacPulzu2(level)
        PCount2 = PCount2 + 1
        gpio.trig(Pulzy2, "down") 
        --if level == 1 then gpio.trig(Pulzy2, "down") else gpio.trig(Pulzy2, "up") end
    end

-- Odesilaci funkce
    local function AktivujOdeslani()
        --rgb cervena
        gpio.mode(GP[15], gpio.OUTPUT)     
        gpio.write(GP[15], gpio.HIGH)

        if MeasureCounter > 0 then
            -- if Debug_M == 1 then uart.write(0,"\r\nm> "..PCount1.."/"..PCount2) end
            MeasureCounter = MeasureCounter - 1
            --tmr.alarm(TM["m"], 10000, 0,  function() AktivujOdeslani() end) 
        else
            -- if Debug_M == 1then uart.write(0,"\r\nm> out "..PCount1.."/"..PCount2) end
            --rgb modra
            gpio.mode(GP[13], gpio.OUTPUT)     
            gpio.write(GP[13], gpio.HIGH)
            Rdat[Rpref.."count1"],PCount1 = PCount1,0
--            Rdat[Rpref.."count2"],PCount2 = PCount2,0
      
            -- Analogovy vstup, je na tom fotoodpor
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
    Pulzy2 = GP[5]
    
-- Nastaveni pinu
    gpio.mode(Pulzy1, gpio.INPUT, gpioPULLUP)
    gpio.mode(Pulzy1, gpio.INT, gpioPULLUP) 
    gpio.trig(Pulzy1, "down", CitacPulzu1)
    if Pulzy2 ~= nil then
        gpio.mode(Pulzy2, gpio.INPUT, gpioPULLUP)
--        gpio.mode(Pulzy2, gpio.INT, gpioPULLUP) 
--        gpio.trig(Pulzy2, "down", CitacPulzu2)
    end

-- Nacasu prvni odeslani
  tmr.alarm(TM["m"], 5000, 1,  function() AktivujOdeslani() end) 
  collectgarbage()
