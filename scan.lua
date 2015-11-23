
change = 0
timing = 800
state = 0
cnt = 0
data = ""
-- debug
times = {}
cntdel = 0
up,down = 0,0
data_out = ""


function pin_change(level_)
    local del_ = tmr.now() - change
    change = tmr.now()

    if (timing > del_) and (del_ > timing/5) then
        timing = timing - 1
        down = down + 1
    end
    if (timing*2 < del_) and (del_ < timing*5) then
        timing = timing + 1
        up = up + 1
    end

    if (state == 1) then
        if (timing * 0.8 < del_) and (del_ < timing * 1.2) then -- kratky pulz v ramci tolerance
            cnt = cnt + 1 -- kratke casovani posune citac pul bitu  o 1
            if ((cnt % 2) == 1) then -- lichy citac misto kde nacitam bit
                if (level_ == 1)  then-- vzestupna, bit 1
                    data = data.."1"
                else -- sestupna, bit 0
                    data = data.."0"
                end
            end -- sudy citac, nezajima nas co se tam delo
        else
            if (timing * 1.8 < del_) and (del_ < timing * 2.2) then -- dlouhy pulz v ramci tolerance
                cnt = cnt + 2 -- dlouhy cas posune citac pul bitu o 2
                if ((cnt % 2) == 1) then -- lichy citac misto kde nacitam bit
                    if (level_ == 1) then -- vzestupna, bit 1
                        data = data.."1"
                    else -- sestupna, bit 0
                        data = data.."0"
                    end
                end -- sudy citac, nezajima nas co se tam delo
            else -- nekorektni casovani - reset dat nastaveni do cekani na start
                state = 2 -- chyba prijmu, ukoncuji prijem
            end
        end
     end

     if (state == 0) then -- stav cekani
        if (level_ == 0) then -- zmena dolu
            state = 1 -- prijimam
            cnt = 0 
            data = ""
        end
    end

    if (del_ > 10*timing) then -- dlouha pauza zacatek prenosu
        if (level_ == 0) then -- zmena dolu
            state = 1 -- prijimam
            cnt = 0 
            data = ""
        end
    end

    if (cnt >= 20) then
        data_out = data
        state = 0
        level_ = 1 -- tvarim se ze to byla vzestupna abych priste reagoval na sestoupnou pouze
    end
    
    if (state == 2) then -- chyba prijmu
        state = 0 -- nastavit na prijem
        level_ = 1 -- tvarim se ze to byla vzestupna abych priste reagoval na sestoupnou pouze
    end

    if (cntdel < 40) then
        times[cntdel] = del_
        cntdel = cntdel + 1
    end
            
    if (level_ == 1) then
        gpio.trig(Din, "both")
    else
        gpio.trig(Din, "both")
    end
end

function print_time()
    print(timing)
    print("^"..up.." v"..down)
    local value,q,v="T:"
    for q,v in pairs(times) do
        value = value .. v .. " "
    end
    times = {}
    cntdel = 0
    print(value)
    print(data_out)
    print(".")
    up,down = 0,0
end    

gpio.mode(Din,gpio.INT)
gpio.trig(Din,"both",pin_change)
tmr.alarm(0, 2000, 1, function() print_time() end)
