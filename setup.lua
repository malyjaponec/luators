--setup.lua
-- konstanty pro GPIO operace
    GP = {[0]=3,[1]=10,[2]=4,[3]=9,[4]=1,[5]=2,[10]=12,[12]=6,[13]=7,[14]=5,[15]=8,[16]=0}
-- konstanty pro rozdelni casovaci    
    TM = {["ip"]=0,["m"]=1,["r"]=2,["s"]=3,["s2"]=4} 

-- uklid pinu 
    --cervena
    gpio.mode(GP[0], gpio.OUTPUT)     
    gpio.write(GP[0], gpio.HIGH)
    --cervena necham, zaroven je modra na modulu, nebylo by videt ze pracuje
--    gpio.mode(GP[2], gpio.OUT)     
--    gpio.write(GP[2], gpio.HIGH)
    -- cervena
    gpio.mode(GP[16], gpio.OUTPUT)     
    gpio.write(GP[16], gpio.HIGH)
    -- cervena
    gpio.mode(GP[14], gpio.OUTPUT)     
    gpio.write(GP[14], gpio.HIGH)

-- prevede ID luatoru do 36-kove soustavy
    local function IDIn36(IN)
        local kody,out,znak="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ",""
        while (IN>0) do 
            IN,znak=math.floor(IN/36),(IN % 36)+1
            out = string.sub(kody,znak,znak)..out
        end
        return out
    end
-- nastavi prefix vsech odesilanych dat    
    Rpref = IDIn36(node.chipid()).."_" --nepouziva se, samostatne na nodu
    --Rpref = "h_"

-- nastavi knihovnu pro RGB
    rgb = require("rgb")
    rgb.setup() -- volam z defaultnimi hodnotami
    rgb.set() -- volam bez parametru = cerna

-- vice vypisu
    Debug = 0 
    if (file.open("debug.ini", "r") ~= nil) then Debug = 1 end

-- konstanty pro reportovani
    Rcnt = 0
    Rnod = "4" -- vsechny elektromery jsou 4
    file.open("apikey.ini", "r") -- soubor tam musi byt a ze neni neosetruji
        Rapik = file.readline() -- soubor nesmi obsahovat ukonceni radku, jen apikey!!!
    file.close()
    Rdat = {}

-- Spustim procesy nastavujici sit a merici data

    Network_Ready = 0 -- sit neni inicialozvana
    tmr.alarm(TM["ip"], 100, 0, function() dofile("network.lc") end)

    Measure_Faze = { GP[4], GP[5], GP[2] } -- definice pinu ktere se ctou
    tmr.alarm(TM["m"], 100, 0,  function() dofile("measure.lc") end)

    Send_Busy = 1 -- je to busy, sam si to zmeni az bude network ready
    Send_Request = 0 -- neni zadny pozadavek
    Send_Failed = 0 -- neni chyba
    tmr.alarm(TM["s"], 100, 0,  function() dofile("send.lc") end)

    print("run")
    --collectgarbage()
