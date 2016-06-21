--setup.lua
-- konstanty pro GPIO operace
    local GP = {[0]=3,[1]=10,[2]=4,[3]=9,[4]=1,[5]=2,[10]=12,[12]=6,[13]=7,[14]=5,[15]=8,[16]=0}

-- uklid pinu co by mohli svitit ledkama 
  -- zrusil jsem at svitej!

-- prevede ID luatoru do 36-kove soustavy a ulozi si hodnotu do promenne pro reportovani
    local function IDIn36(IN)
        local kody,out,znak="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ",""
        while (IN>0) do 
            IN,znak=math.floor(IN/36),(IN % 36)+1
            out = string.sub(kody,znak,znak)..out
        end
        return out
    end
    Rpref = IDIn36(node.chipid()).."_"

-- nastavi knihovnu pro RGB
--    rgb = require("rgb")
--    rgb.setup() -- volam s defaultnim zapojeni RGB
--    rgb.set() -- volam bez parametru = cerna

-- vice vypisu, temer se v nove vzniknutych kodech nepouziva, ale v sitove vrstve je pouzito
    Debug = 0 
    if (file.open("debug.ini", "r") ~= nil) then
        Debug = 1
        file.close()
    end

-- konstanty pro reportovani
    Rcnt = 0
    Rnod = "4" -- vsechny elektromery jsou 4
    if (file.open("apikey.ini", "r") ~= nil) then
        Rapik = file.readline() -- soubor nesmi obsahovat ukonceni radku, jen apikey!!!
        file.close()
    else
        Rapik = "xxx"
        print("PANIC: no apikey.ini")
    end
    Rdat = {}

    TimeStart = 0
    Time = -1
    Out = GP[13]
    In = GP[14]

    local function CitacPulzu1(_level)
        if _level == gpio.HIGH then
            TimeStart = tmr.now()
        else
            Time = tmr.now() - TimeStart
        end
    end


    local function MesureTime()
        print("Vzdalenost "..((Time*343.2/10000)-15).." cm")
        --TimeStart = tmr.now()
        gpio.write(Out,gpio.HIGH)
        gpio.write(Out,gpio.LOW)
    end

    gpio.mode(Out,gpio.OUTPUT)
    gpio.write(Out,gpio.LOW)
    
    gpio.mode(In, gpio.INPUT, gpioPULLUP)
    gpio.mode(In, gpio.INT, gpioPULLUP) 
    gpio.trig(In, "both", CitacPulzu1)
    
    tmr.alarm(0, 1000, 1, function() MesureTime() end)

    print("run")
