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

    
    
    RXbuf = ""
    Dist = 0
    Temp = 0


    local function ProcessTemperature()
        -- zpracovat data
        Temp = RXbuf:byte(1) - 45
        -- zrusit handler
        uart.on("data")
        -- prepnout na 115200 a povolit interpret
        uart.setup(0, 115200, 8, uart.PARITY_NONE, uart.STOPBITS_1, 1)
        -- vratit seriovou linku na port 1 
        uart.alt(0)
        -- tisk
        print("vzdalenost ="..(Dist/10).." cm")
        print("teplota ="..(Temp).." C")
    end

    local function ProcessDistance()
        -- zpracovat data
        Dist = RXbuf:byte(1) * 256 + RXbuf:byte(2)
        -- nastavit handler prijmu
        uart.on("data", 1, function(data) RXbuf = data end, 0)
        -- poslat 0x50
        uart.write(0, 0x50)
        -- nacasovat vycteni
        tmr.alarm(1, 5, 0, function() ProcessTemperature() end)        
    end

    local function MesureUltrasonic()
        -- prepnout seriovou linku na 2. port
        uart.alt(1)
        -- nastavit rychlost 9600 a vypnout interpret
        uart.setup(0, 9600, 8, uart.PARITY_NONE, uart.STOPBITS_1, 0)
        -- nastavit handler prijmu
        uart.on("data", 2, function(data) RXbuf = data end, 0)
        -- poslat 0x55
        uart.write(0, 0x55)
        -- nacasovat vycteni
        tmr.alarm(1, 150, 0, function() ProcessDistance() end)
    end

    
    tmr.alarm(0, 1000, 1, function() MesureUltrasonic() end)

    print("run")
