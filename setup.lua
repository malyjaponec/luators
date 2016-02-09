--setup.lua
-- konstanty pro GPIO operace
    local GP = {[0]=3,[1]=10,[2]=4,[3]=9,[4]=1,[5]=2,[10]=12,[12]=6,[13]=7,[14]=5,[15]=8,[16]=0}

-- uklid pinu co by mohli svitit ledkama 
    -- cervena
    gpio.mode(GP[0], gpio.OUTPUT)     
    gpio.write(GP[0], gpio.HIGH)
    -- cervena
    gpio.mode(GP[16], gpio.OUTPUT)     
    gpio.write(GP[16], gpio.HIGH)
    -- cervena
    gpio.mode(GP[14], gpio.OUTPUT)     
    gpio.write(GP[14], gpio.HIGH)
    -- ostatni jsou RGB nebo vstupy 3 fazi 

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
    rgb = require("rgb")
    rgb.setup() -- volam z defaultnimi hodnotami
    rgb.set() -- volam bez parametru = cerna

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

-- Spustim procesy nastavujici sit a merici data

    Network_Ready = 0 -- sit neni inicialozvana
    tmr.alarm(0, 250, 0, function() dofile("network.lc") end)

    Measure_Faze = { GP[4], GP[5], GP[2] } -- definice pinu ktere se ctou
    Energy_Faze = {0,0,0} -- akumulace energie pro jednotlive vstupy (ve Wh)
    Power_Faze = {-1,-1,-1} -- ukladani posledniho vykonu pro jednotlive vstupy (ve W) na zaklade posledni delky pulzu
    tmr.alarm(1, 10, 0,  function() dofile("measure.lc") end)
		-- minimalni cas aby to co nejdrive zacalo merit

    -- odesilace nepotrebuje zadne klobalni promenne, taha data z tech vyse definovanych pro ostatni procesy
    tmr.alarm(2, 500, 0,  function() dofile("send.lc") end)

-- uklid toho co uz nepotrebujem 
    print("run")
