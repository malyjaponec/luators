-- measure.lua
    tmr.stop(TM["m"])

-- globalni citace pro 2 elektromer
    PCount1 = 0
    PCount2 = 0

-- Citaci funkce
    function CitacPulzu1(level)
        PCount1 = PCount1 + 1
        --gpio.trig(Pulzy1, "down") 
        --if level == 1 then gpio.trig(Pulzy1, "down") else gpio.trig(Pulzy1, "up") end
    end
      
    function CitacPulzu2(level)
        PCount2 = PCount2 + 1
        --gpio.trig(Pulzy2, "down") 
        --if level == 1 then gpio.trig(Pulzy2, "down") else gpio.trig(Pulzy2, "up") end
    end

-- Odesilaci funkce
    local function AktivujOdeslani()
        print("---")
        print("m>e1="..PCount1)
        print("m>e2="..PCount2)
        Rdat[Rpref.."count1"],PCount1 = PCount1,0
        Rdat[Rpref.."count2"],PCount2 = PCount2,0
      
        -- Analogovy vstup, je na tom fotoodpor
        Rdat[Rpref.."an"] = adc.read(0)
        
        Completed_Measure = 1
        tmr.alarm(TM["m"], 10000, 0,  function() AktivujOdeslani() end) 
    end
      
-- Konfigurace, kam jsou elektromery pripojeny
    Pulzy1 = GP[4]
    Pulzy2 = GP[5]
    
-- Nastaveni pinu
    gpio.mode(Pulzy1, gpio.INT, gpioPULLUP) 
    gpio.trig(Pulzy1, "down", CitacPulzu1)
    if Pulzy2 ~= nil then
        gpio.mode(Pulzy2, gpio.INT, gpioPULLUP) 
        gpio.trig(Pulzy2, "down", CitacPulzu2)
    end

-- Nacasu prvni odeslani
  tmr.alarm(TM["m"], 10000, 0,  function() AktivujOdeslani() end) 
